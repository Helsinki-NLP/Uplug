/*
 * parse.c - parse a sentence
 *
 * Copyright (C) 1996, 1997, 2000, 2001, 
 *                            Nara Institute of Science and Technology
 *                           
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *      This product includes software developed by Nara Institute of 
 *      Science and Technology.
 * 4. The name Nara Institute of Science and Technology may not be used to
 *    endorse or promote products derived from this software without specific
 *    prior written permission.
 *    
 *
 * THIS SOFTWARE IS PROVIDED BY Nara Institute of Science and Technology 
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
 * PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE Nara Institute
 * of Science and Technology BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Modified by: A.Kitauchi <akira-k@is.aist-nara.ac.jp>, Oct. 1996
 * $Id$
 */

#include "chalib.h"
#include "pat.h"
#include "sufary.h"
#include "tokenizer.h"

#define MRPH_NUM	        1024
#define PATH1_NUM		256

#define HANKAKU            	0x80
#define PRIOD            	0xa1a5
#define CHOON            	0xa1bc
#define KIGOU            	0xa3b0
#define SUJI           	        0xa3c0
#define ALPH            	0xa4a0
#define HIRAGANA                0xa5a0
#define KATAKANA                0xa6a0
#define GR                      0xb0a0
#define KANJI                   0xffff
#define ILLEGAL                 1

#define is_spc(c)    ((c)==' '||(c)=='\t')

mrph2_t *Cha_mrph = NULL;
path_t *Cha_path = NULL;
int Cha_path_num;


/*
 * malloc_chars
 */
#define CHA_MALLOC_SIZE (1024 * 64)
#define malloc_char(n)     malloc_chars(1, n)
#define malloc_short(n)    malloc_chars(2, n)
#define malloc_int(n)      malloc_chars(4, n)
#define free_chars()       malloc_chars(0, 0)
static void *
malloc_chars(int size, int nitems)
{
    static char *buffer_ptr[128];
    static int buffer_ptr_num = 0;
    static int buffer_idx = CHA_MALLOC_SIZE;

    if (nitems == 0) {
	/*
	 * free 
	 */
	if (buffer_ptr_num > 0) {
	    while (buffer_ptr_num > 1)
		free(buffer_ptr[--buffer_ptr_num]);
	    buffer_idx = 0;
	}
	return NULL;
    } else {
	if (size > 1) {
	    /*
	     * size で割りきれる値に補正する 
	     */
	    buffer_idx += size - (buffer_idx & (size - 1));
	    nitems *= size;
	}

	if (buffer_idx + nitems >= CHA_MALLOC_SIZE) {
	    if (buffer_ptr_num == 128)
		cha_exit(1, "Can't allocate memory");
	    buffer_ptr[buffer_ptr_num++] = cha_malloc(CHA_MALLOC_SIZE);
	    buffer_idx = 0;
	}

	buffer_idx += nitems;
	return buffer_ptr[buffer_ptr_num - 1] + buffer_idx - nitems;
    }
}

static void *
malloc_free_block(void *ptr, int *nblockp, int size, int do_free)
{
    if (do_free) {
	/*
	 * free and malloc one block 
	 */
	if (*nblockp > 1) {
	    free(ptr);
	    *nblockp = 0;
	}
	if (*nblockp == 0)
	    ptr = malloc_free_block(ptr, nblockp, size, 0);
    } else {
	/*
	 * realloc one block larger 
	 */
	if (*nblockp == 0)
	    ptr = malloc(size * ++*nblockp);
	else {
	    ptr = realloc(ptr, size * ++*nblockp);
	}
    }

    return ptr;
}

#define malloc_path()  malloc_free_path(0)
#define free_path()    malloc_free_path(1)
static int
malloc_free_path(int do_free)
{
    static int nblock = 0;

    Cha_path = malloc_free_block((void *) Cha_path, &nblock,
				 sizeof(path_t) * CHA_PATH_NUM, do_free);

    return Cha_path == NULL;
}

#define malloc_mrph()  malloc_free_mrph(0)
#define free_mrph()    malloc_free_mrph(1)
static int
malloc_free_mrph(int do_free)
{
    static int nblock = 0;

    Cha_mrph = malloc_free_block((void *) Cha_mrph, &nblock,
				 sizeof(mrph2_t) * MRPH_NUM, do_free);

    return Cha_mrph == NULL;
}

/*
 * register_undef_mrph1 - 未定義語をバッファに追加
 */
static int
register_undef_mrph1(char *target, int mrph_idx, int undef_len, int no)
{
    mrph2_t *mrph = &Cha_mrph[mrph_idx];

    mrph->midasi = target;
    mrph->yomi = "";
    mrph->base_length = mrph->length = undef_len;
    mrph->base = "";
    mrph->pron = "";
    mrph->compound = "\n";

    mrph->hinsi = Cha_undef_info[no].hinsi;
    mrph->con_tbl = Cha_undef_info[no].con_tbl;
    mrph->ktype = 0;
    mrph->kform = 0;
    mrph->is_undef = no + 1;	/* 未定義語 */
    mrph->weight = MRPH_DEFAULT_WEIGHT;
    mrph->info = "";		/* 付加情報は空文字列とする． */

    if (++mrph_idx % MRPH_NUM == 0 && malloc_mrph())
	return FALSE;

    return TRUE;
}

/*
 * register_mrph - 活用を調べながら形態素をバッファに追加
 *
 * Retern value:
 * If successful, this rutine returns the number of morphs
 * added to the buffer. If an error occurs, return -1.
 */
static int
register_mrph(int mrph_idx)
{
    int new_mrph_idx = mrph_idx;
    mrph2_t *new_mrph = &Cha_mrph[mrph_idx];

    if (!new_mrph->ktype) {
	/*
	 * 活用しない 
	 */
	if (++new_mrph_idx % MRPH_NUM == 0 && malloc_mrph())
	    return -1;
    } else {
	/*
	 * 活用する 
	 */
	if (new_mrph->kform) {
	    /*
	     * 語幹なし 
	     */
	    new_mrph->base_length = 0;
	    new_mrph->yomi = "";
	    new_mrph->pron = "";
	    if (++new_mrph_idx % MRPH_NUM == 0 && malloc_mrph())
		return -1;
	} else {
	    /*
	     * 語幹あり 
	     */
	    int f;
	    int ktype = new_mrph->ktype;
	    int baselen = new_mrph->length;
	    int con_tbl = new_mrph->con_tbl;
	    char *follows = new_mrph->midasi + baselen;
	    int new_mrph_idx0 = new_mrph_idx;
	    for (f = 1; Cha_form[ktype][f].name; f++) {
		if (!Cha_form[ktype][f].gobi[0] ||
		    (follows[0] == Cha_form[ktype][f].gobi[0] &&
		     !memcmp(follows, Cha_form[ktype][f].gobi,
			     Cha_form[ktype][f].gobi_len))) {
		    if (new_mrph_idx != new_mrph_idx0)
			*new_mrph = Cha_mrph[new_mrph_idx0];
		    new_mrph->kform = f;
		    new_mrph->length =
			baselen + Cha_form[ktype][f].gobi_len;
		    new_mrph->con_tbl = con_tbl + f - 1;
		    if (++new_mrph_idx % MRPH_NUM == 0 && malloc_mrph())
			return -1;
		    new_mrph = &Cha_mrph[new_mrph_idx];
		}
	    }
	}
    }

    return new_mrph_idx - mrph_idx;
}

/*
 * convert_mrphs - 形態素をバッファに追加
 * 
 * Retern value:
 * If successful, this rutine returns the number of morphs
 * added to the buffer. If an error occurs, return -1.
 */
static int
convert_mrphs(char *target, char **dic_buffer, int mrph_idx)
{
    int nmrph;
    int new_mrph_idx = mrph_idx;
    char **pbuf;

    for (pbuf = dic_buffer; *pbuf; pbuf++) {
	cha_get_mrph_data(&Cha_mrph[new_mrph_idx], *pbuf, target);
	nmrph = register_mrph(new_mrph_idx);
	if (nmrph < 0)
	    return -1;
	new_mrph_idx += nmrph;
    }

    return new_mrph_idx - mrph_idx;
}

/*
 * collect_mrphs_for_pos()
 */
static int
collect_mrphs_for_pos(int pos, int *p_idx)
{
    static int p_start;
    int i, j;

    j = 0;
    if (pos == 0) {
	/*
	 * new sentence 
	 */
	p_idx[j++] = 0;
	p_start = 1;
    } else {
	for (i = p_start; i < Cha_path_num; i++) {
	    if (Cha_path[i].end <= pos) {
		if (i == p_start)
		    p_start++;
		if (Cha_path[i].end == pos)
		    p_idx[j++] = i;
	    }
	}
    }
    p_idx[j] = -1;

    return j;
}


/*
 * check_connect()
 */
static int
check_connect(int pos, int m_num, int *p_idx)
{
    /*
     * 次状態の値でパスを分類する 
     */
    typedef struct _path_cost_t {
	int min_cost;
	short min_cost_no;
	short state;
	short num;
	int cost[PATH1_NUM];
	int pno[PATH1_NUM];
    } path_cost_t;

    /*
     * static short best_start, best_end, best_state; static int
     * best_cost; 
     */
    static path_cost_t pcost[PATH1_NUM];
    int pcost_num;
    mrph2_t *new_mrph;
    int i, pno, pcostno;
    int haba_cost, con_cost, cost, mrph_cost;
    int con_tbl, next_state;

#ifdef DEBUG
    printf("[m:%d] ", m_num);
#endif
    new_mrph = &Cha_mrph[m_num];
    con_tbl = new_mrph->con_tbl;

    pcost[0].state = -1;
    pcost_num = 0;

    for (i = 0; (pno = p_idx[i]) >= 0; i++) {
	/*
	 * オートマトンを調べて次状態と接続コストを出す 
	 */
	next_state = cha_check_automaton
	    (Cha_path[pno].state, con_tbl, Cha_con_cost_undef, &con_cost);

	if (con_cost == -1)
	    continue;

#ifdef DEBUG
	printf
	    ("[%3d, %3d, pos:%d, len:%d, state:%5d,%5d, cost:%d, undef:%d]\n",
	     Cha_path[pno].mrph_p, m_num, pos, new_mrph->length,
	     Cha_path[pno].state, next_state, cost, new_mrph->is_undef);
#endif
	/*
	 * cost を計算 
	 */
	cost = Cha_path[pno].cost + con_cost * Cha_con_cost_weight;

	/*
	 * どの pcost に属するか調べる 
	 */
	for (pcostno = 0; pcostno < pcost_num; pcostno++)
	    if (next_state == pcost[pcostno].state)
		break;
	if (pcostno < pcost_num) {
	    /*
	     * tricky: when Cha_cost_width is -1, ">-1" means ">=0" 
	     */
	    if (cost - pcost[pcostno].min_cost > Cha_cost_width)
		continue;
	} else {
	    /*
	     * 新しい pcost を作る 
	     */
	    pcost_num++;
	    pcost[pcostno].num = 0;
	    pcost[pcostno].state = next_state;
	    pcost[pcostno].min_cost = INT_MAX;
	}

	/*
	 * pcost に登録 
	 */
	if (Cha_cost_width < 0) {
	    pcost[pcostno].min_cost = cost;
	    pcost[pcostno].pno[0] = pno;
	} else {
	    pcost[pcostno].cost[pcost[pcostno].num] = cost;
	    pcost[pcostno].pno[pcost[pcostno].num] = pno;
	    if (cost < pcost[pcostno].min_cost) {
		pcost[pcostno].min_cost = cost;
		pcost[pcostno].min_cost_no = pcost[pcostno].num;
	    }
	    pcost[pcostno].num++;
	}
    }

    if (pcost_num == 0)
	return TRUE;

    /*
     * 形態素コスト 
     */
    if (new_mrph->is_undef) {
	mrph_cost = Cha_undef_info[new_mrph->is_undef - 1].cost
	    + Cha_undef_info[new_mrph->is_undef -
			     1].cost_step * new_mrph->length / 2;
    } else {
	mrph_cost = Cha_hinsi[new_mrph->hinsi].cost;
    }
    mrph_cost *= new_mrph->weight * Cha_mrph_cost_weight;

    for (pcostno = 0; pcostno < pcost_num; pcostno++) {
	/*
	 * コスト幅におさまっているパスを抜き出す 
	 */
	if (Cha_cost_width < 0) {
	    Cha_path[Cha_path_num].path = malloc_int(2);
	    Cha_path[Cha_path_num].path[0] = pcost[pcostno].pno[0];
	    Cha_path[Cha_path_num].path[1] = -1;
	} else {
	    int npath = 0;
	    int path[PATH1_NUM];
	    haba_cost = pcost[pcostno].min_cost + Cha_cost_width;
	    path[npath++] = pcost[pcostno].pno[pcost[pcostno].min_cost_no];
	    for (i = 0; i < pcost[pcostno].num; i++)
		if (pcost[pcostno].cost[i] <= haba_cost
		    && i != pcost[pcostno].min_cost_no)
		    path[npath++] = pcost[pcostno].pno[i];
	    path[npath++] = -1;
	    memcpy(Cha_path[Cha_path_num].path = malloc_int(npath),
		   path, sizeof(int) * npath);
	}

	/*
	 * Cha_path に登録 
	 */
	Cha_path[Cha_path_num].cost = pcost[pcostno].min_cost + mrph_cost;
	Cha_path[Cha_path_num].mrph_p = m_num;
	Cha_path[Cha_path_num].state = pcost[pcostno].state;
	Cha_path[Cha_path_num].start = pos;
	Cha_path[Cha_path_num].end = pos + new_mrph->length;
#ifdef DEBUG
	printf("%3d %3d %5d [p:%d,prev:%d,m:%d,c:%d,pc:%d]\n",
	       Cha_path[Cha_path_num].start, Cha_path[Cha_path_num].end,
	       Cha_path[Cha_path_num].state,
	       Cha_path_num, Cha_path[Cha_path_num].path[0], m_num,
	       pcost[0].cost[i], Cha_path[Cha_path_num].cost);
#endif
	if (++Cha_path_num % CHA_PATH_NUM == 0 && malloc_path())
	    return FALSE;
    }

    return TRUE;
}

static void
set_mrph_end(mrph2_t * mrph)
{
    mrph->midasi = mrph->yomi = mrph->info = "";
    mrph->base = mrph->pron = "";
    mrph->compound = "\n";
    mrph->base_length = mrph->length = 0;

    mrph->hinsi = 0;
    mrph->ktype = 0;
    mrph->kform = 0;
    mrph->con_tbl = 0;
    mrph->is_undef = 0;
    mrph->weight = MRPH_DEFAULT_WEIGHT;
}

static int
set_mrph_bkugiri(void)
{
    static int bkugiri_num;
    int h;
    mrph2_t *mrph;

    if (Cha_mrph[1].midasi)
	return bkugiri_num;

    for (h = 0; Cha_hinsi[h].name; h++) {
	if (!Cha_hinsi[h].bkugiri)
	    continue;
	mrph = &Cha_mrph[++bkugiri_num];
	/*
	 * memset: unnecessary? 
	 */
	memset(mrph, 0, sizeof(mrph2_t));

	mrph->hinsi = h;
	mrph->con_tbl = cha_check_table_for_undef(h);
	mrph->midasi = mrph->yomi = mrph->base = mrph->pron =
	    Cha_hinsi[h].bkugiri;
	mrph->info = "";
    }
    return bkugiri_num;
}

static int
lookup_dic(char *target, int target_len, int cursor, int new_mrph_idx)
{
    int dic_no;
    char *dic_buffer[256];

    /*
     * 辞書引き(全角文字のみ検索する) EUC only 
     */
    if (Cha_encode == CHASEN_ENCODE_EUCJP &&
	cha_tok_mblen_on_cursor(Cha_tokenizer, cursor) == 2) {
	for (dic_no = 0; dic_no < Pat_ndicfile; dic_no++) {
	    int nmrph;
	    /*
	     * パトリシア木から形態素を検索 
	     */
	    pat_search(Pat_dicfile[dic_no], target + cursor, dic_buffer);
	    /*
	     * 活用させつつ形態素を Cha_mrph に追加 
	     */
	    nmrph = convert_mrphs(target + cursor, dic_buffer,
				  new_mrph_idx);
	    if (nmrph < 0)
		return -1;
	    new_mrph_idx += nmrph;
	}
    }

    for (dic_no = 0; dic_no < Suf_ndicfile; dic_no++) {
	int nmrph;
	/*
	 * SUFARY ファイルから形態素を検索 
	 */
	sa_common_prefix_search(Suf_dicfile[dic_no],
				target + cursor, target_len - cursor,
				dic_buffer);
	/*
	 * 活用させつつ形態素を Cha_mrph に追加 
	 */
	nmrph = convert_mrphs(target + cursor, dic_buffer, new_mrph_idx);
	if (nmrph < 0)
	    return -1;
	new_mrph_idx += nmrph;
    }

    return new_mrph_idx;
}


/*
 * 未定義語処理 
 */
static int
set_undefword(char *target, int cursor, int new_mrph_idx, int mrph_idx,
	      int *path_idx)
{
    int undef_len;
    int i;

    undef_len = cha_tok_char_type_len(Cha_tokenizer, cursor);
    /*
     * 直前のパスとの接続をチェック 
     */
    for (i = mrph_idx; i < new_mrph_idx; i++) {
	/*
	 * 未定義語と同じ長さの単語が辞書にあれば未定義語を追加しない 
	 */
	if (Cha_con_cost_undef > 0 && Cha_mrph[i].length == undef_len)
	    undef_len = 0;
	if (check_connect(cursor, i, path_idx) == FALSE)
	    return -1;
    }

    /*
     * 未定義語の追加 
     */
    if (undef_len > 0) {
	int no;
	for (no = 0; no < Cha_undef_info_num; no++, new_mrph_idx++) {
	    if (register_undef_mrph1(target + cursor, new_mrph_idx,
				     undef_len, no) == FALSE)
		return -1;
	    if (check_connect(cursor, new_mrph_idx, path_idx) == FALSE)
		return -1;
#if 0
	    printf("path[0]: %d:%d\n", Cha_path_num - 1,
		   Cha_path[Cha_path_num - 1].path[0]);
#endif
	}
    }

    return new_mrph_idx;
}

static int
add_bkugiri(int cursor, int *path_idx, int path_idx_num, int bkugiri_num)
{
    int bk;

    for (bk = 0; bk < bkugiri_num; bk++) {
	int path_num;
	path_num = Cha_path_num;
	/*
	 * 文節区切りを追加 
	 */
	if (check_connect(cursor, bk + 1, path_idx) == FALSE)
	    return -1;
#if 0
	printf("PATH: %d: %d -> %d\n", cursor, path_num, Cha_path_num);
#endif
	/*
	 * 追加された path を path_idx に追加 
	 */
	if (Cha_path_num > path_num)
	    for (; path_num < Cha_path_num; path_num++)
		path_idx[path_idx_num++] = path_num;
	path_idx[path_idx_num] = -1;
    }

    return path_idx_num;
}

#define cursor_sep(c, l) \
     ((!cha_tok_is_jisx0208_latin(Cha_tokenizer,(c), (l))) ? \
        cha_tok_mblen_on_cursor(Cha_tokenizer, (c)) : \
        cha_tok_char_type_len(Cha_tokenizer, (c)))

/*
 * cha_parse_sentence() - 一文を形態素解析する
 *
 * return value:
 *     0 - ok
 *     1 - no result / too many morphs
 */
int
cha_parse_sentence(char *target, int target_len, int opt_nobk)
{
    int cursor, prev_cursor;
    int path_idx[PATH1_NUM], path_idx_num;
    int mrph_idx, new_mrph_idx;
    int bkugiri_num = 0;
    static int path0 = -1;

    cha_tok_parse(Cha_tokenizer, target, target_len + 1);

    free_chars();
    free_path();
    free_mrph();

    /*
     * 文頭処理
     */
    Cha_path[0].start = Cha_path[0].end = 0;
    Cha_path[0].path = &path0;
    Cha_path[0].cost = 0;
    Cha_path[0].mrph_p = 0;
    Cha_path[0].state = 0;

    Cha_path_num = 1;
    set_mrph_end(&Cha_mrph[0]);
    if (!opt_nobk)
	bkugiri_num = set_mrph_bkugiri();
    new_mrph_idx = mrph_idx = bkugiri_num + 1;

    /*
     * 本処理
     */
    for (cursor = prev_cursor = 0; cursor < target_len;
	cursor += cursor_sep(cursor, target_len - cursor),
	prev_cursor = cursor) {
        /* skip annotations and white space */
	while (cha_tok_anno_type(Cha_tokenizer, cursor) != 0 )
	  cursor += cha_tok_char_type_len(Cha_tokenizer, cursor);
	if (cursor >= target_len)
	  break;
	
	path_idx_num = collect_mrphs_for_pos(prev_cursor, path_idx);

	if (path_idx_num == 0)
	    continue;

	/* add BUNSETSU (the POS with length 0) information */
	path_idx_num = add_bkugiri(cursor,
				   path_idx, path_idx_num, bkugiri_num);
	if (path_idx_num < 0)
	    goto error_end;

	/* pick up possible words from dictionary */
	new_mrph_idx = lookup_dic(target, target_len, cursor, new_mrph_idx);
	if (new_mrph_idx < 0)
	    goto error_end;

	/* set undefined word */
	/* check the path between the preceding and current position  */
	new_mrph_idx = set_undefword(target, cursor,
				     new_mrph_idx, mrph_idx, path_idx);
	if (new_mrph_idx < 0)
	    goto error_end;

	mrph_idx = new_mrph_idx;
    }

    /*
     * 文末処理
     */
    set_mrph_end(&Cha_mrph[mrph_idx++]);
    if (mrph_idx % MRPH_NUM == 0 && malloc_mrph())
        goto error_end;
    
    path_idx_num = collect_mrphs_for_pos(prev_cursor, path_idx);

    if (check_connect(cursor, mrph_idx - 1, path_idx) == FALSE)
        goto error_end;

 
    return 0;

    /*
     * エラー処理
     */
  error_end:
    printf("Error: Too many morphs: %s\n", target);

    return 1;
}
