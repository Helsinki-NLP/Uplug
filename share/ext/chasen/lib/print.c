/*
 * print.c - print mrphs and paths
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
 *  modified by A.Kitauchi <akira-k@is.aist-nara.ac.jp>, Sep. 1996
 *           by O.Imaichi <osamu-im@is.aist-nara.ac.jp>, Sep. 1996
 * $Id$
 */

#include <stdarg.h>
#include <stdio.h>
#include <ctype.h>
#include "chalib.h"
#include "tokenizer.h"
#include "pat.h"

#define CHA_OUTPUT_SIZE (1024*16)

static int path_buffer[CHA_INPUT_SIZE];
static int is_bol = 1;
static int pos_end = 0;

static void (*cha_putc) (), (*cha_puts) (), (*cha_printf) ();
static void (*cha_fputc) (), (*cha_fputs) (), (*cha_fprintf) ();

void
cha_print_reset(void)
{
    pos_end = 0;
}

/*
 * cha_clputc, cha_clputs, cha_clprintf
 *      - output functions for ChaSen client
 */
static void
cha_clputc(int c, FILE * output)
{
    if (is_bol && c == '.')
	putc('.', output);

    putc(c, output);

    is_bol = c == '\n' ? 1 : 0;
}

static void
cha_clputs(char *s, FILE * output)
{
    if (is_bol && s[0] == '.')
	putc('.', output);

    fputs(s, output);

    is_bol = s[strlen(s) - 1] == '\n' ? 1 : 0;
}

static void
cha_clprintf(FILE * output, char *format, ...)
{
    char tmpbuf[CHA_INPUT_SIZE];
    va_list ap;

    va_start(ap, format);
    vsprintf(tmpbuf, format, ap);
    va_end(ap);

    if (is_bol && tmpbuf[0] == '.')
	putc('.', output);

    fputs(tmpbuf, output);

    is_bol = tmpbuf[strlen(tmpbuf) - 1] == '\n' ? 1 : 0;
}

/*
 * cha_sputc, cha_sputs, cha_sprintf
 *      - output fuctions to string
 *
 * NOTE: `output' is a dummy argument for compatibility with cha_clputc, etc.
 *
 */

static char *cha_output;
static int cha_output_idx;
static int cha_output_nblock;

static void
cha_sputc(int c, char *output /* dummy */ )
{
    if (cha_output_idx + 1 >= CHA_OUTPUT_SIZE * cha_output_nblock
	&& cha_output) {
	cha_output =
	    realloc(cha_output, CHA_OUTPUT_SIZE * ++cha_output_nblock);
    }

    if (cha_output) {
	cha_output[cha_output_idx++] = c;
	cha_output[cha_output_idx] = '\0';
    }
}

static void
cha_sputs(char *s, char *output)
{
    int len = strlen(s);

    if (cha_output_idx + len >= CHA_OUTPUT_SIZE * cha_output_nblock
	&& cha_output) {
	cha_output =
	    realloc(cha_output, CHA_OUTPUT_SIZE * ++cha_output_nblock);
    }

    if (cha_output) {
	strcpy(cha_output + cha_output_idx, s);
	cha_output_idx += len;
    }
}

static void
cha_sprintf(char *output, char *format, ...)
{
    char tmpbuf[CHA_INPUT_SIZE];
    va_list ap;

    va_start(ap, format);
    vsprintf(tmpbuf, format, ap);
    va_end(ap);
    cha_sputs(tmpbuf, output);
}

void
cha_set_fput(int server_mode)
{
    /*
     * For system having no prototype declarations for the following
     * functions such as SunOS 4.1.4. 
     */
    extern int fputc(int, FILE *);
    extern int fputs(const char *, FILE *);
    extern int fprintf(FILE *, const char *, ...);

    if (server_mode) {
	cha_fputc = (void (*)) cha_clputc;
	cha_fputs = (void (*)) cha_clputs;
	cha_fprintf = (void (*)) cha_clprintf;
    } else {
	cha_fputc = (void (*)) fputc;
	cha_fputs = (void (*)) fputs;
	cha_fprintf = (void (*)) fprintf;
    }
}

void
cha_set_output(FILE * output)
{
    if (output == NULL) {
	/*
	 * output to string 
	 */
	cha_putc = (void (*)) cha_sputc;
	cha_puts = (void (*)) cha_sputs;
	cha_printf = (void (*)) cha_sprintf;
	/*
	 * initialize output buffer 
	 */
	if (cha_output_nblock > 1) {
	    free(cha_output);
	    cha_output_nblock = 0;
	}
	if (cha_output_nblock == 0)
	    cha_output = malloc(CHA_OUTPUT_SIZE * ++cha_output_nblock);
	cha_output_idx = 0;
	cha_output[0] = '\0';
    } else {
	/*
	 * output to file 
	 */
	cha_output = (char *) output;
	cha_putc = (void (*)) cha_fputc;
	cha_puts = (void (*)) cha_fputs;
	cha_printf = (void (*)) cha_fprintf;
    }
}

/*
 * returns cha_output for chasen_[fs]arse_tostr()
 */
char *
cha_get_output(void)
{
    return cha_output;
}

/*
 * cha_printf_mrph - print morpheme using format string
 *
 * about the format of English please see `manual.tex'
 *  
 * format string:
 *      %m     見出し(活用形)
 *      %M     見出し(基本形)
 *      %y     読みの第一候補(活用形)
 *      %Y     読み第一候補(基本形)
 *      %y0    読み全体(活用形)
 *      %Y0    読み全体(基本形)
 *      %a     発音の第一候補(活用形)
 *      %A     発音の第一候補(基本形)
 *      %a0    発音全体(活用形)
 *      %A0    発音全体(基本形)
 *      %rabc  ルビつきの見出し("a見出しb読みc" と表示)
 *      %i     付加情報
 *      %Ic    付加情報(空文字列か"NIL"なら文字c)
 *      %Pc    各階層の品詞を文字cで区切った文字列(vgramのみ)
 *      %Pnc   1〜n(n:1〜9)階層目までの品詞を文字cで区切った文字列(vgramのみ)
 *      %h     品詞の番号
 *      %H     品詞(vgramの場合は1階層目)
 *      %Hn    n(n:1〜9)階層目の品詞(なければ最も深い階層)(vgramのみ)
 *      %b     品詞細分類の番号(vgramの場合は0)
 *      %BB    品詞細分類(なければ品詞)
 *      %Bc    品詞細分類(なければ文字c)
 *      %t     活用型の番号
 *      %Tc    活用型(なければ文字c)
 *      %f     活用形の番号
 *      %Fc    活用形(なければ文字c)
 *      %c     形態素のコスト
 *      %S     解析文全体
 *      %pb    最適パスであれば "*", そうでなければ " "
 *      %pi    パスの番号
 *      %ps    パスの形態素の開始位置
 *      %pe    パスの形態素の終了位置+1
 *      %pc    パスのコスト
 *      %ppiC  前に接続するパスの番号を文字Cで区切り列挙
 *      %ppcC  前に接続するパスのコストを文字Cで区切り列挙
 *      %rABC,%Ic,%Bc,%Tc,%Fc については A,B,C,c が空白文字の時は何も
 *             表示しない
 *
 *      %?B/STR1/STR2/  品詞細分類があればSTR1、なければSTR2
 *      %?I/STR1/STR2/  付加情報がNILでも""でもなければSTR1、そうでなければSTR2
 *      %?T/STR1/STR2/  活用があればSTR1、なければSTR2
 *      %?F/STR1/STR2/  活用があればSTR1、なければSTR2
 *      %?U/STR1/STR2/  未定義語ならSTR1、そうでなければSTR2
 *      %U/STR/         未定義語なら"未定義語"(vgramの場合は"未知語")、
 *                      そうでなければSTR(%?U/未知語/STR/ と同じ)
 *      `/'には任意の文字が使える。
 *      また、括弧「(){}[]<>」を使った以下のような形式が使える。
 *      %?B(STR1)(STR2) %?B{STR1}/STR2/ %?U[STR]
 *
 *      %%     % そのもの
 *      .      フィールド幅を指定
 *      -      フィールド幅を指定
 *      1-9    フィールド幅を指定
 *      \n     改行文字
 *      \t     タブ
 *      \\     \ そのもの
 *      \'     ' そのもの
 *      \"     " そのもの
 *
 * example:
 *      "%m %y %M %h %b %t %f\n"                     same as -c option
 *      "%m %U(%y) %M %H %h %B* %b %T* %t %F* %f\n"  same as -e option
 */
static int
check_con_cost(path_t * path, int con_tbl)
{
    int con_cost;

    cha_check_automaton(path->state,
			con_tbl, Cha_con_cost_undef, &con_cost);

    return con_cost;
}

static int
comm_prefix_len(char *s1, char *s2)
{
    char *s0 = s1;
    for (; *s1 && *s1 == *s2; s1++, s2++) {
	if ((unsigned char) *s1 & 0x80)
	    if (*++s1 != *++s2)
		break;
    }
    return s1 - s0;
}

static void
set_ruby(char *dest, char *midasi, char *yomi,
	 int par1, int par2, int par3)
{
    char *d = dest;
    char *m = midasi;
    char *y = yomi;
    char *m0 = NULL;
    char *y0 = NULL;
    char *ymax = NULL;
    int stat = 0;
    int plen, maxplen = 0;

    for (;;) {
	for (; *y; y += ((unsigned char) *y & 0x80) ? 2 : 1) {
	    if (stat == 0) {
		stat = 1;
		if ((plen = comm_prefix_len(m, y)) > 0) {
		    memcpy(d, m, plen);
		    d += plen;
		    m += plen;
		    y += plen;
		}
		m0 = m;
		y0 = y;
		if (!*m || !*y)
		    goto end_ruby;
		m += ((unsigned char) *m & 0x80) ? 2 : 1;
		plen = maxplen = 0;
		continue;
	    }
	    if ((plen = comm_prefix_len(m, y)) > 0 && plen > maxplen) {
		maxplen = plen;
		ymax = y;
	    }
	}
	if (maxplen == 0) {
	    if (*m)
		m += ((unsigned char) *m & 0x80) ? 2 : 1;
	    if (!*m)
		ymax = y;
	}
	if (!*m || maxplen > 0) {
	    y = ymax;
	    if (par1 != ' ')
		*d++ = par1;
	    memcpy(d, m0, m - m0);
	    d += m - m0;
	    if (par2 != ' ')
		*d++ = par2;
	    memcpy(d, y0, y - y0);
	    d += y - y0;
	    if (par3 != ' ')
		*d++ = par3;
	    if (!*m)
		break;
	    stat = 0;
	}
    }
  end_ruby:
    *d = '\0';
}

static void
print_nhinsi(int hinsi, int c, int n)
{
    short *path;
    int i;

    if (c == '\'')
	cha_putc(c, cha_output);

    path = Cha_hinsi[hinsi].path;
    for (i = 0;; i++) {
	cha_puts(Cha_hinsi[*path].name, cha_output);
	if (!*path || !*++path || i == n)
	    break;
	if (c == '\'')
	    cha_puts("'-'", cha_output);
	else
	    cha_putc(c, cha_output);
    }

    if (c == '\'')
	cha_putc(c, cha_output);
}

/*
 * int_to_str - convert an integer to ASCII
 *	by Masanao Izumo <masana-i@is.aist-nara.ac.jp>
 */
static char *
int_to_str(int value)
{
    static char buff[32];
    char *p;
    int sign;

    p = buff + 31;
    if (value >= 0)
	sign = 0;
    else {
	if (-value == value) {	/* value == INT_MIN */
	    sprintf(buff, "%d", value);
	    return buff;
	}
	value = -value;
	sign = 1;
    }

    do {
	*--p = value % 10 + '0';
	value /= 10;
    } while (value > 0);
    if (sign)
	*--p = '-';

    return p;
}

/*
 * fputsn
 *	by Masanao Izumo <masana-i@is.aist-nara.ac.jp>
 */
static void
fputsn(char *str, char *out, int n)
{
    char buff[256];
    int len;

    while (n > 0) {
	len = (n <= 255 ? n : 255);
	memcpy(buff, str, len);
	buff[len] = '\0';
	cha_puts(buff, out);
	str += len;
	n -= len;
    }
}

/* ad-hoc macros XXX */
#define strtoi(s, i) \
while (isdigit(*(s))) { (i) = (i) * 10 + *(s) - '0'; (s)++; } 

#define field_putsn(w, o, l) \
    ((l) == -1) ? cha_puts((w), (o)) : fputsn((w), (o), (l))
/*
 * printf_field
 *	by Masanao Izumo <masana-i@is.aist-nara.ac.jp>
 */
static void
printf_field(char *width_str, char *word)
{
    char *field = width_str;
    int field_len, word_len, wl;

    if (width_str == NULL) {
	cha_puts(word, cha_output);
	return;
    }

    if (*field == '-')
	field++;

    word_len = -1;
    field_len = 0;
    strtoi(field, field_len);

    if (*field == '.') {
	int len = 0;
	word_len = strlen(word);
	field++;
	strtoi(field, len);
	if (len < word_len)
	    word_len = len;
    }

    wl = (word_len == -1) ? strlen(word) : word_len;
    if (*width_str == '-') {
	field_putsn(word, cha_output, word_len);
	field_len -= wl;
	while (field_len-- > 0)
	    cha_putc(' ', cha_output);
    } else {
	field_len -= wl;
	while (field_len-- > 0)
	    cha_putc(' ', cha_output);
	field_putsn(word, cha_output, word_len);
    }
}
#undef strtoi(s, i)
#undef field_putsn((w), (o), (l))

static int
get_deli_right(int c)
{
    switch (c) {
    case '(':
	return ')';
    case '{':
	return '}';
    case '[':
	return ']';
    case '<':
	return '>';
    default:
	return c;
    }
}

static void
print_anno(int path_num, char *format)
{
    path_t *path = &Cha_path[path_num];
    mrph2_t mrph;
    int start, end;

    if (!Cha_anno_info[0].hinsi && !Cha_anno_info[1].hinsi
	&& !Cha_anno_info[1].format)
	return;

    if (path->start <= pos_end) {
	pos_end = path->end;
	return;
    }

    start = path->start;
    end = path->end;

    while (start > pos_end) {
	int anno_no = cha_tok_anno_type(Cha_tokenizer, pos_end);
	char *format_string = format;
	if (anno_no >= 0 &&
	    (Cha_anno_info[anno_no].hinsi
	     || Cha_anno_info[anno_no].format)) {
	    mrph.midasi = Cha_tokenizer->string + pos_end;
	    mrph.base_length =
		mrph.length = cha_tok_char_type_len(Cha_tokenizer, pos_end);
	    mrph.yomi = "";
	    mrph.base = "";
	    mrph.pron = "";
	    if (Cha_anno_info[anno_no].format) {
		format_string = Cha_anno_info[anno_no].format;
		mrph.is_undef = 1;
		mrph.hinsi = Cha_undef_info[0].hinsi;
	    } else {
		mrph.is_undef = 0;
		mrph.hinsi = Cha_anno_info[anno_no].hinsi;
	    }
	    mrph.con_tbl = 0;
	    mrph.ktype = 0;
	    mrph.kform = 0;
	    mrph.weight = 0;
	    mrph.info = "";
	    path->start = pos_end;
	    path->end = pos_end + mrph.length;
	    cha_printf_mrph(path_num, &mrph, format_string);
	}
	pos_end += cha_tok_char_type_len(Cha_tokenizer, pos_end);
    }
    path->end = pos_end = end;
    path->start = start;
}

static void
extract_yomi1(char *dst, char *src)
{
    int in_brace = 0, is1st = 0;
    char *s, *d;

    if (strchr(src, '{') == NULL) {
	if (dst != src)
	    strcpy(dst, src);
	return;
    }

    for (s = src, d = dst; *s; s++) {
	if (!in_brace) {
	    if (*s == '{')
		in_brace = is1st = 1;
	    else
		*d++ = *s;
	} else if (*s == '}')
	    in_brace = 0;
	else if (is1st) {
	    if (*s == '/')
		is1st = 0;
	    else
		*d++ = *s;
	}
    }

    *d = '\0';
}

void
cha_printf_mrph(int path_num, mrph2_t * mrph, char *format)
{
    int letter, value, n, state;
    int deli_left = 0, deli_right = 0;
    char *s, *word, *eword;
    char word_str[CHA_INPUT_SIZE], word_str2[CHA_INPUT_SIZE];
    char *width_str;
    path_t *path = &Cha_path[path_num];

    eword = NULL;		/* string in EUC */
    word = NULL;		/* string in EUC(UNIX) or SJIS(Win) */
    letter = 0;			/* character */
    value = INT_MAX;		/* integer value */
    state = 0;

    for (s = format; *s; s++) {
	if (state == 1 && *s == deli_right) {
	    if (deli_right != deli_left && !*s++)
		return;
	    deli_right = get_deli_right(*s);
	    if ((s = strchr(++s, deli_right)) == NULL)
		return;
	    state = 0;
	    continue;
	}
	if (state == 2 && *s == deli_right) {
	    state = 0;
	    continue;
	}

	if (*s != '%') {
	    cha_putc(*s, cha_output);
	    continue;
	}

	s++;
	width_str = NULL;
	if (*s == '-' || *s == '.' || (*s >= '0' && *s <= '9')) {
	    width_str = s;
	    while (*s == '-' || *s == '.' || (*s >= '0' && *s <= '9'))
		s++;
	}

	switch (*s) {
	case '?':
	    if (!*++s)
		return;
	    state = 2;
	    switch (*s) {
	    case 'U':
		if (mrph->is_undef)
		    state = 1;
		break;
	    case 'B':
		if (Cha_hinsi[mrph->hinsi].depth > 1)
		    state = 1;
		break;
	    case 'I':
		if (mrph->info[0] && strcmp(mrph->info, "NIL"))
		    state = 1;
		break;
	    case 'T':
	    case 'F':
		if (mrph->kform)
		    state = 1;
		break;
	    }
	    if (!*++s)
		return;
	    deli_right = get_deli_right(deli_left = *s);
	    if (state == 2) {
		if ((s = strchr(++s, deli_right)) == NULL)
		    return;
		if (deli_left != deli_right)
		    if (!*++s)
			return;
		deli_right = get_deli_right(*s);
	    }
	    continue;
	case 'U':
	    if (mrph->is_undef) {
		state = 1;
		deli_right = *s;
		deli_left = '\0';
		s--;
		word = (Cha_lang == CHASEN_LANG_EN) ?
		    ESTR_UNKNOWN_WORD : JSTR_UNKNOWN_WORD;
	    } else {
		state = 2;
		deli_right = get_deli_right(deli_left = *++s);
	    }
	    break;
	case 'm':		/* Surface string (surface form) */
  	    if (mrph->length == 0)    /* bunsetsu */
		word = mrph->midasi;
	    else {                    /* not bunsetsu */
		memcpy(eword = word_str, mrph->midasi, mrph->length);
		word_str[mrph->length] = '\0';
	    }
	    break;
	case 'M':		/* Surface string (base form) */
   	    if (mrph->length == 0)  /* bunsetsu */
		word = mrph->midasi;
	    else if (mrph->base[0]) /* not bunsetsu */
		eword = mrph->base;
	    else {
		memcpy(eword = word_str, mrph->midasi, mrph->base_length);
		if (!mrph->ktype)
		    word_str[mrph->base_length] = '\0';
		else
		    strcpy(word_str + mrph->base_length,
			   Cha_form[mrph->ktype][Cha_type[mrph->ktype].
						 basic].gobi);
	    }
	    break;
	case 'y':		/* Japanese Reading (surface form) */
	case 'Y':		/* Japanese Reading (base form) */
	case 'r':
   	    if (mrph->length == 0) /* bunsetsu */
		word = mrph->midasi;
	    else {                 /* not bunsetsu */
		if (mrph->yomi[0]) {
		    if (s[0] != 'r' && s[1] != '0')
			extract_yomi1(word_str, mrph->yomi);
		    else
			strcpy(word_str, mrph->yomi);
		} else {
		    memcpy(word_str, mrph->midasi, mrph->base_length);
		    word_str[mrph->base_length] = '\0';
		}
		if (mrph->ktype > 0) {
		    if (*s != 'Y')
			strcat(word_str,
			       Cha_form[mrph->ktype][mrph->kform].ygobi);
		    else
			strcat(word_str,
			       Cha_form[mrph->ktype][Cha_type[mrph->ktype].
						     basic].ygobi);
		}
		eword = word_str;
	    }
	    if (*s != 'r') {
		if (s[1] == '0' || s[1] == '1')
		    s++;
		break;
	    }
	    if (!s[1] || !s[2] || !s[3])
		cha_putc(*s, cha_output);
	    else {
		extract_yomi1(word_str2, eword);
		eword = word_str2;
		if (memcmp(mrph->midasi, eword, mrph->length)) {
		    char yomi[CHA_INPUT_SIZE], midasi[CHA_INPUT_SIZE];
		    strcpy(yomi, eword);
		    memcpy(midasi, mrph->midasi, mrph->length);
		    midasi[mrph->length] = '\0';
		    set_ruby(word_str, midasi, yomi, s[1], s[2], s[3]);
		    eword = word_str;
		}
		s += 3;
	    }
	    break;
	case 'a':		/* Japanese pronunciation (surface form) */
	case 'A':		/* Japanese pronunciation (base form) */
  	    if (mrph->length == 0)   /* bunsetsu */
		word = mrph->midasi;
	    else {                   /* not bunsetsu */
		if (mrph->pron[0]) {
		    if (s[1] != '0')
			extract_yomi1(word_str, mrph->pron);
		    else
			strcpy(word_str, mrph->pron);
		} else if (mrph->yomi[0]) {
		    if (s[1] != '0')
			extract_yomi1(word_str, mrph->yomi);
		    else
			strcpy(word_str, mrph->yomi);
		} else {
		    memcpy(word_str, mrph->midasi, mrph->base_length);
		    word_str[mrph->base_length] = 0;
		}
		if (mrph->ktype > 0) {
		    if (*s != 'A')
			strcat(word_str,
			       Cha_form[mrph->ktype][mrph->kform].pgobi);
		    else
			strcat(word_str,
			       Cha_form[mrph->ktype][Cha_type[mrph->ktype].
						     basic].pgobi);
		}
		eword = word_str;
	    }
	    if (s[1] == '0' || s[1] == '1')
		s++;
	    break;
	case 'i':		/* information */
	    if (s[1] != '0')
		extract_yomi1(word_str, mrph->info);
	    else
		strcpy(word_str, mrph->info);
	    eword = word_str;
	    break;
	case 'I':		/* information */
	    if (*++s == '\0')
		cha_putc(*--s, cha_output);
	    else if (mrph->info[0] && strcmp(mrph->info, "NIL"))
		eword = mrph->info;
	    else if (*s != ' ')
		letter = *s;
	    break;
	case 'P':
	    n = 99;		/* print all level of the POS -- すべての階層を表示 */
	    if (s[1] >= '1' && s[1] <= '9')
		n = *++s - '1';
	    if (s[1] == '\0')
		cha_putc(*s, cha_output);
	    else
		print_nhinsi(mrph->hinsi, *++s, n);
	    break;
	case 'h':		/* POS number */
	    value = mrph->hinsi;
	    break;
	case 'H':		/* POS string */
	    if (s[1] < '1' || s[1] > '9')
		n = 0;
	    else {
		n = *++s - '1';
		if (Cha_hinsi[mrph->hinsi].depth - 1 < n)
		    n = Cha_hinsi[mrph->hinsi].depth - 1;
	    }
	    word = Cha_hinsi[Cha_hinsi[mrph->hinsi].path[n]].name;
	    break;
	case 'b':		/* POS subdivision number */
	    value = 0;
	    break;
	case 'B':		/* POS subdivision string */
	    if (s[1] == '\0')
		cha_putc(*s, cha_output);
	    else if (*++s == 'M' && mrph->is_undef)
		word = (Cha_lang == CHASEN_LANG_EN) ?
		    ESTR_UNKNOWN_WORD : JSTR_UNKNOWN_WORD;
	    /*
	     * 階層化品詞なら一番下の階層の品詞名を表示 
	     * when the POS has subdivision level,
	     * print the lowest level of the POS name
	     */
	    else if (*s == 'M' || *s == 'B'
		     || Cha_hinsi[mrph->hinsi].depth > 1)
		word = Cha_hinsi[mrph->hinsi].name;
	    else if (*s != ' ')
		letter = *s;
	    break;
	case 't':		/* Conjugation type number */
	    value = mrph->ktype;
	    break;
	case 'T':		/* Conjugation type string */
	    if (*++s == '\0')
		cha_putc(*--s, cha_output);
	    else if (mrph->ktype)
		word = Cha_type[mrph->ktype].name;
	    else if (*s != ' ')
		letter = *s;
	    break;
	case 'f':		/* Conjugation form number */
	    value = mrph->kform;
	    break;
	case 'F':		/* Conjugation form string */
	    if (*++s == '\0')
		cha_putc(*--s, cha_output);
	    if (mrph->kform)
		word = Cha_form[mrph->ktype][mrph->kform].name;
	    else if (*s != ' ')
		letter = *s;
	    break;
	case 'c':		/* the cost of morpheme */
	    if (mrph->is_undef) {
		value = Cha_undef_info[mrph->is_undef - 1].cost
		    + Cha_undef_info[mrph->is_undef -
				     1].cost_step * mrph->length / 2;
	    } else {
		value = Cha_hinsi[mrph->hinsi].cost;
	    }
	    value *= mrph->weight * Cha_mrph_cost_weight;
	    break;
	case 'S':		/* entire sentence */
	    word = Cha_tokenizer->string;
	    break;
	case 'p':		/* the information about path */
	    if (s[1] == '\0') {
		cha_putc(*s, cha_output);
		break;
	    }
	    switch (*++s) {
	    case 'i':
		value = path_num;
		break;
	    case 's':
		value = path->start;
		break;
	    case 'e':
		value = path->end;
		break;
	    case 'c':
		value = path->cost;
		break;
	    case 'b':
		letter = path->do_print == 2 ? '*' : ' ';
		break;
	    case 'p':
		if ((s[1] != 'i' && s[1] != 'c') || s[2] == '\0')
		    cha_putc(*s, cha_output);
		else if (*++s == 'i') {
		    int c = *++s, j;
		    for (j = 0; path->path[j] != -1; j++) {
			if (j)
			    cha_putc(c, cha_output);
			cha_printf(cha_output, "%d", path->path[j]);
		    }
		} else {
		    int con_tbl = mrph->con_tbl;
		    int c = *++s, j;
		    for (j = 0; path->path[j] != -1; j++) {
			if (j)
			    cha_putc(c, cha_output);
			cha_printf(cha_output, "%d", Cha_con_cost_weight *
				   check_con_cost(&Cha_path[path->path[j]],
						  con_tbl));
		    }
		}
		break;
	    }
	    break;
	case '\0':
	    return;
	default:		/* includes '%' */
	    cha_putc(*s, cha_output);
	    continue;
	}

	if (word != NULL) {
	    printf_field(width_str, word);
	    word = NULL;
	} else if (eword != NULL) {
#ifdef SJIS
	    char tmp_str[CHA_INPUT_SIZE];
	    strcpy(tmp_str, eword);
	    euc2sjis(tmp_str);
	    eword = tmp_str;
#endif
	    printf_field(width_str, eword);
	    eword = NULL;
	} else if (letter) {
	    word_str[0] = letter;
	    word_str[1] = '\0';
	    printf_field(width_str, word_str);
	    letter = 0;
	} else if (value != INT_MAX) {
	    printf_field(width_str, int_to_str(value));
	    value = INT_MAX;
	}
    }
}

static void
print_bos_eos(char *str)
{
    char *s;

    for (s = str; *s; s++) {
	if (*s == '%' && *++s == 'S')
	    cha_puts(Cha_tokenizer->string, cha_output);
	else
	    cha_putc(*s, cha_output);
    }
}

static void
print_bos(int opt_form)
{
    if (opt_form != 'W' && opt_form != 'd' && *Cha_bos_string)
	print_bos_eos(Cha_bos_string);
}

static void
print_eos(int opt_form)
{
    if (opt_form == 'W')
	cha_putc('\n', cha_output);
    else if (opt_form != 'd' && *Cha_eos_string)
	print_bos_eos(Cha_eos_string);
}

/*
 * print_path_mrph
 */
static void
print_mrph(int path_num, mrph2_t * mrph, char *format)
{
    print_anno(path_num, format);

    if (Cha_output_iscompound || 
	mrph->compound == NULL ||
	*mrph->compound == '\n') {
        cha_printf_mrph(path_num, mrph, format); 
    } else {
	/*
	 * compound word 
	 */
	int kform = mrph->kform;
	while (*mrph->compound != '\n') {
	    cha_get_mrph_data(mrph, mrph->compound, mrph->midasi);
	    /*
	     * 最後の形態素の活用形＝複合語の活用形 
	     */
	    if (*mrph->compound == '\n' && !mrph->kform)
		mrph->kform = kform;
	    if (mrph->ktype) {
		mrph->length +=
		    strlen(Cha_form[mrph->ktype][mrph->kform].gobi);
		mrph->con_tbl += mrph->kform - 1;
	    }
	    cha_printf_mrph(path_num, mrph, format);
	    mrph->midasi += mrph->length;
	}
    }
}

static void
print_path_mrph(int path_num, char *format)
{
    print_mrph(path_num, &Cha_mrph[Cha_path[path_num].mrph_p], format);
}

static void
concat_composit_mrph(mrph2_t *composit_mrph, mrph2_t *cur_mrph)
{
    /* 
     * initialization
     */
    if (!composit_mrph->hinsi) {    
	composit_mrph->hinsi = Cha_hinsi[cur_mrph->hinsi].composit;
	composit_mrph->midasi = cur_mrph->midasi;
	composit_mrph->length = composit_mrph->weight = 0;
	composit_mrph->yomi[0] = '\0';
	composit_mrph->pron[0] = '\0';
	composit_mrph->base[0] = '\0';
    } 
    /* 
     * Japanese Reading 
     */
    if (cur_mrph->yomi[0])          
	strcat(composit_mrph->yomi, cur_mrph->yomi);
    else {
	int len = strlen(composit_mrph->yomi);
	memcpy(composit_mrph->yomi + len, cur_mrph->midasi, cur_mrph->base_length);
	composit_mrph->yomi[len + cur_mrph->base_length] = '\0';
    }
    if (cur_mrph->ktype > 0)
	strcat(composit_mrph->yomi,
	       Cha_form[cur_mrph->ktype][cur_mrph->kform].ygobi);
    /* 
     * Pronunciation
     */
    if (cur_mrph->pron[0])
	strcat(composit_mrph->pron, cur_mrph->pron);
    else if (cur_mrph->yomi[0])
	strcat(composit_mrph->pron, cur_mrph->yomi);
    else {
	int len = strlen(composit_mrph->pron);
	memcpy(composit_mrph->pron + len, cur_mrph->midasi, cur_mrph->base_length);
	composit_mrph->pron[len + cur_mrph->base_length] = '\0';
    }
    if (cur_mrph->ktype > 0)
	strcat(composit_mrph->pron,
	       Cha_form[cur_mrph->ktype][cur_mrph->kform].pgobi);

    strcat(composit_mrph->base, cur_mrph->base);
    composit_mrph->length += cur_mrph->length;
    composit_mrph->weight += cur_mrph->weight;
}

static void
concat_composit_mrph_end(mrph2_t *composit_mrph, mrph2_t *cur_mrph) {
    /* 
     * Japanese Reading 
     */
    if (cur_mrph->yomi[0])
        strcat(composit_mrph->yomi, cur_mrph->yomi);
    else {
        int len = strlen(composit_mrph->yomi);
        memcpy(composit_mrph->yomi + len, cur_mrph->midasi,
    	   cur_mrph->base_length);
        composit_mrph->yomi[len + cur_mrph->base_length] = '\0';
    }
    /* 
     * Japanese Pronunciation
     */
    if (cur_mrph->pron[0])
        strcat(composit_mrph->pron, cur_mrph->pron);
    else if (cur_mrph->yomi[0])
        strcat(composit_mrph->pron, cur_mrph->yomi);
    else {
        int len = strlen(composit_mrph->pron);
        memcpy(composit_mrph->pron + len, cur_mrph->midasi,
    	   cur_mrph->base_length);
        composit_mrph->pron[len + cur_mrph->base_length] = '\0';
    }

    strcat(composit_mrph->base, cur_mrph->base);
    composit_mrph->base_length = composit_mrph->length + cur_mrph->base_length;
    composit_mrph->length += cur_mrph->length;
    composit_mrph->weight += cur_mrph->weight;
    composit_mrph->info = cur_mrph->info;
    composit_mrph->ktype = cur_mrph->ktype;
    composit_mrph->kform = cur_mrph->kform;
    composit_mrph->is_undef = cur_mrph->is_undef;
}

#define print_anno_eos() \
    { print_anno(Cha_path_num - 1, format); print_eos(opt_form); }
/*
 * print_best_path()
 */
static void
print_best_path(int opt_form, char *format)
{
    int i, last, pbuf_last, isfirst = 1;
    int path_num_composit = 0;
    char yomi[CHA_INPUT_SIZE];
    char pron[CHA_INPUT_SIZE];
    char base[CHA_INPUT_SIZE];
    mrph2_t composit_mrph, *cur_mrph, *pre_mrph;

    print_bos(opt_form);

    last = Cha_path[Cha_path_num - 1].path[0];

    if (last == 0) {
	print_anno_eos();
	return;
    }
    for (pbuf_last = 0; last; last = Cha_path[last].path[0], pbuf_last++) {
	path_buffer[pbuf_last] = last;
    }

    /*
     * print composit POSs as one word
     */
    /* initialization */
    composit_mrph.hinsi = 0;
    composit_mrph.yomi = yomi;
    composit_mrph.pron = pron;
    composit_mrph.base = base;
    cur_mrph = &Cha_mrph[Cha_path[path_buffer[pbuf_last - 1]].mrph_p];

    /* 
     * chunking the composit POSs from EOS to BOS
     */
    for (i = pbuf_last - 1; i >= 0; i--) {   

	pre_mrph = (i == 0) ?
	    NULL : &Cha_mrph[Cha_path[path_buffer[i - 1]].mrph_p];

	if (i > 0 && !cur_mrph->is_undef && !pre_mrph->is_undef
	    && (Cha_path[path_buffer[i]].end == Cha_path[path_buffer[i - 1]].start)
	    && Cha_hinsi[cur_mrph->hinsi].composit
	    && (Cha_hinsi[cur_mrph->hinsi].composit == Cha_hinsi[pre_mrph->hinsi].composit)) {

	    if (!composit_mrph.hinsi) 
	        path_num_composit = path_buffer[i];

	    concat_composit_mrph(&composit_mrph, cur_mrph);

	} else {
	    if (opt_form == 'd') {
		if (isfirst)
		    isfirst = 0;
		else
		    cha_putc(',', cha_output);
	    }
	    if (!composit_mrph.hinsi)
		print_mrph(path_buffer[i], cur_mrph, format);
	    else {
                concat_composit_mrph_end(&composit_mrph, cur_mrph);
                Cha_path[path_num_composit].end =
                   Cha_path[path_num_composit].start + composit_mrph.length;
		print_mrph(path_num_composit, &composit_mrph, format);
		composit_mrph.hinsi = 0;
	    }
	}
	cur_mrph = pre_mrph;
    }

    print_anno_eos();
}

/*
 * print_all_mrph - 正しい解析結果に含まれる全ての形態素を表示
 *      -m, -d, -v オプションで使用
 */
static void
collect_all_mrph(int path_num)
{
    int i, j;

    for (i = 0; (j = Cha_path[path_num].path[i]) && j != -1; i++) {
	if (!Cha_path[j].do_print) {
	    Cha_path[j].do_print =
		(i == 0 &&
		 (path_num == Cha_path_num - 1
		  || Cha_path[path_num].do_print == 2))
		? 2 : 1;
	    collect_all_mrph(j);
	}
    }
}

static void
print_all_mrph(int opt_form, char *format)
{
    int i;
    int isfirst = 1;		/* 文頭かどうかのフラグ for -d option */

    for (i = 0; i < Cha_path_num; i++)
	Cha_path[i].do_print = 0;
    collect_all_mrph(Cha_path_num - 1);

    /*
     * -v のときは文頭・文末の情報も表示 
     */
    if (opt_form == 'v') {
	Cha_path[0].do_print = 2;
	Cha_path[Cha_path_num - 1].do_print = 2;
    }

    print_bos(opt_form);
    for (i = 0; i < Cha_path_num; i++) {
	if (Cha_path[i].do_print) {
	    if (opt_form == 'd') {
		if (isfirst)
		    isfirst = 0;
		else
		    cha_putc(',', cha_output);
	    }
	    print_path_mrph(i, format);
	}
    }
    print_anno(Cha_path_num - 1, format);
    print_eos(opt_form);
}

/*
 * print_all_path()
 */
static void
print_all_path_sub(int path_num, int paths, int opt_form, char *format)
{
    int i, j;

    for (i = 0; Cha_path[path_num].path[i] != -1; i++) {
	if (Cha_path[path_num].path[0] == 0) {
	    pos_end = 0;
	    for (j = paths - 1; j >= 0; j--)
		print_path_mrph(path_buffer[j], format);
	    print_anno(Cha_path_num - 1, format);
	    cha_puts("EOP\n", cha_output);
	} else {
	    path_buffer[paths] = Cha_path[path_num].path[i];
	    print_all_path_sub(Cha_path[path_num].path[i], paths + 1,
			       opt_form, format);
	}
    }
}

static void
print_all_path(int opt_form, char *format)
{
    print_bos(opt_form);
    print_all_path_sub(Cha_path_num - 1, 0, opt_form, format);
    print_eos(opt_form);
}

void
cha_print_path(int opt_show, int opt_form, char *format)
{
    if (opt_form == 'd')
	cha_putc('[', cha_output);

    switch (opt_show) {
    case 'm':
	print_all_mrph(opt_form, format);
	break;
    case 'p':
	print_all_path(opt_form, format);
	break;
    default:
	print_best_path(opt_form, format);	/* 'b' */
    }

    if (opt_form == 'd')
	cha_puts("].\n", cha_output);
}

void
cha_print_bos_eos(int opt_form)
{
    pos_end = 0;
    print_bos(opt_form);
    print_eos(opt_form);
}

void
cha_print_hinsi_table(void)
{
    int i;

    for (i = 0; Cha_hinsi[i].name; i++) {
	cha_printf(cha_output, "%d ", i);
	print_nhinsi(i, '-', 99);
	cha_putc('\n', cha_output);
    }
}

void
cha_print_ctype_table(void)
{
    int i;
    for (i = 1; Cha_type[i].name; i++)
	cha_printf(cha_output, "%d %s\n", i, Cha_type[i].name);
}

void
cha_print_cform_table(void)
{
    int i, j;
    for (i = 1; Cha_type[i].name; i++)
	for (j = 1; Cha_form[i][j].name; j++)
	    printf("%d %d %s\n", i, j, Cha_form[i][j].name);
}
