/*
 * pat.c - library for patricia tree
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
 * $Id$
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pat.h"

/*
 * strcpy_tonl()
 */
static void
strcpy_tonl(char *dst, char *src)
{
    while ((*dst++ = *src++) != '\n');
}

static int
strcmp_tonl(char *s1, char *s2)
{
    for (; *s1 != '\n' && *s1 == *s2; s1++, s2++);
    return (int) (*s1 - *s2);
}

/*
 * pat_bits --- 文字列中の指定された位置のビットを返す
 *              position given for string
 *              return the bit of the position
 * 
 * parameters:
 *   string --- 文字列
 *              string
 *   cbit --- 指定された位置。文字列全体を一つのビット列と考え、
 *            先頭(左)bitから 0,1,2,3... で指定する。
 *            position.  
 *            string is regarded as a sequence of bits.
 *            the first(left) bit is 0.
 *   len --- 文字列の長さ．strlenをいちいちやってたんじゃ大変だから 
 *           the length of string.  --- strlen is cumbersome...
 *
 * return:
 *   0 / not 0
 */
static int
pat_bits(char *string, int cbit, int len)
{
    int moji_idx = cbit / 8;	/* 指定された位置が何文字目か */
                                /* the position to what number by character */
/*      static int bitval[8] = */
/*  	{ 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01 }; */
/*      printf("[%d,%d,%d]", cbit, moji_idx, len); */
/*      if (moji_idx > len) { */
/*  	printf("!!!!!!!!!!!!!!!"); */
/*  	exit(1); */
/*      } */

    /*
     * 指定された位置 >= 文字列の長さのチェック 
     * check (the position >= the length of string)
     */
    if (moji_idx >= len)
	return 0;
    /*
     * トップノードのときは1を返す(topからは必ず右) 
     *  when top node, return 1;
     */
    if (cbit < 0)
	return 1;
    return string[moji_idx] & (1 << (7 - cbit % 8));
}

static int
pat_memcmp(unsigned char *s1, unsigned char *s2, int n)
{
    if (n == 2)
	return (s1[0] != s2[0] || s1[1] != s2[1]);
    else
	return memcmp(s1, s2, n);
}

/*
 * key の checkbitビット目で左右に振り分け 
 * right or left by `checkbit'-th key
 */
#define get_next_node(node, key, checkbit, key_length) \
((pat_bits((key), (checkbit), (key_length))) ? (node)->right : (node)->left)

/*
 * pat_search --- search patricia tree
 * 
 * parameter
 *   key --- 検索キー
 *   result --- 結果を入れる．
 * 
 * return:
 *   pointer to a node which the search end
 */
pat_node *
pat_search(pat_t * pat, char *key, char **result)
{
    pat_node *top_ptr = pat->root;
    pat_node *tmp_ptr = NULL;
    pat_node *ptr = pat->root->right;
    pat_index_list *list;
    int checkbit;
    int key_length = strlen(key);   /* the length of key string */
    int match_len = 0;    /* the length of matched prefix string */
                            
    int result_last = 0;

    do {
	checkbit = ptr->checkbit;
	/* when the SIKIIBIT (= the character segment) */
	if (checkbit % SIKII_BIT == 0 && checkbit) {	/* 途中単語を探す */ /* search word */
	    tmp_ptr = ptr->left;
#ifdef DEBUG
	    printf("\n[%d,%02x%02x]", checkbit, key[0], key[1]);
#endif
	    /*
	     * 先頭の「見出し語」部分だけでマッチングを行なう 
	     * matching by `surface form'
	     */
	    if (!pat_memcmp(key + match_len,
			    pat_get_text(pat, (tmp_ptr->il).index)
			    + match_len, checkbit / 8 - match_len)) { /* found! */

		match_len = checkbit / 8;  /* the character length of matched prefix */
		list = &(tmp_ptr->il);	   /* pick up the all elements */
		
		while (list != NULL) {
		    result[result_last++] = pat_get_text(pat, list->index);
		    list = list->next;
		}
	    } else {      /* not found */
		result[result_last] = NULL;
		return ptr;
	    }
	}

	/*
	 * key の checkbitビット目で左右に振り分け 
         * right or left by `checkbit'-th bit of key
	 */
	ptr = get_next_node(ptr, key, checkbit, key_length);
    } while (checkbit < ptr->checkbit);

    if (ptr != tmp_ptr || ptr == top_ptr) { /* check the end node or not */
	char *line = pat_get_text(pat, (ptr->il).index);
	/*
	 * bufferの先頭の「見出し語」部分だけでマッチングを行なう 
         * matching by `surface form'
	 */
	/*
	 * いきどまり単語のPrefixチェック 
         * check the prefix of dead end word
	 */
	if (!pat_memcmp(key + match_len,
			line + match_len, strlen(line) - match_len)) {
	    if (match_len != key_length) { 	    /*  new word or not  */
		list = &(ptr->il);	/* pick up the all elements in list */

		while (list != NULL) {
		    result[result_last++] = pat_get_text(pat, list->index);
		    list = list->next;
		}
	    }
	}
    }
    result[result_last++] = NULL;

    return ptr;
}

/*
 * pat_search_exact --- パトリシア木を検索(search patricia tree exact match)
 * 
 * parameter
 *   key --- 検索キー
 *   x_ptr --- 検索開始位置(ポインタ)
 *             pointer to position where the search begin
 *   result --- 結果を入れる．
 * 
 * return:
 *   pointer to a node where the search end
 */
pat_node *
pat_search_exact(pat_t * pat, char *key, char **result)
{
    pat_node *x_ptr = pat->root;
    pat_node *ptr;
    pat_index_list *list;
    int key_length = strlen(key);	/* the length of key  */
    char *line;
    int result_last = 0;

    do {
	ptr = x_ptr;
	x_ptr = get_next_node(x_ptr, key, x_ptr->checkbit, key_length);
    } while (ptr->checkbit < x_ptr->checkbit);

    /*
     * ファイルから取って来る 
     * get text from file
     */
    line = pat_get_text(pat, (x_ptr->il).index);

    /*
     * bufferの先頭の「見出し語」部分だけでマッチングを行なう 
     * pattern match by `surface form' which is at the first column in `.int'
     */
    if (strcmp(key, line) == 0) {	/* いきどまり単語のチェック */
                                        /* check the dead end word */
	list = &(x_ptr->il);	/* 全リスト要素の取り出し */
                                /* pick up all elements */
	while (list != NULL) {
	    line = pat_get_text(pat, list->index);
	    result[result_last++] = line;
	    list = list->next;
	}
    }
    result[result_last] = NULL;

    return x_ptr;
}

/*
 * pat_search4insert --- 挿入用に検索
 *                       search for insersion
 * 
 * parameter
 *   key --- 検索キー
 *   node --- 検索開始位置(ポインタ)
 *            pointer to a position where the search begin
 * 
 * return
 *   検索終了位置(ポインタ)
 *   pointer to a position where the search end
 */
static pat_node *
pat_search4insert(char *key, pat_node * node)
{
    pat_node *tmp_node;
    int key_length = strlen(key);	/* the length of key  */
                                        
    do {
	tmp_node = node;
	node = get_next_node(node, key, node->checkbit, key_length);
    } while (tmp_node->checkbit < node->checkbit);

    return node;
}

/*
 * pat_insert --- パトリシア木にデータを挿入
 *                insert data for patricia tree
 * 
 * Parameter
 *   f --- file
 *   line --- データ(挿入キーと内容が区切り文字で区切られている構造)
 *            key and contents (segmented by delimiter)
 *   index --- データのファイル上のインデックス
 *            `index' for data file
 *   x_ptr --- 挿入のための検索の開始位置
 *            begining point which the search start
 * 
 * return 
 *   none
 */
void
pat_insert(pat_t * pat, char *line, long index)
{
    pat_node *x_ptr = pat->root;
    pat_node *t_ptr, *p_ptr, *new_ptr;
    int diff_bit;
    pat_index_list *new_l_ptr, *list, *mae_wo_sasu_ptr = NULL;
    int buffer_length;
    int key_length;
    char key[500];
    char buffer[50000];	 /* buffer for general use */

    x_ptr = pat->root;

    strcpy(key, line);
    key_length = strlen(key);	/* the length of key  */
                                
    /* search the key */
    t_ptr = (pat_node *) pat_search4insert(key, x_ptr);

    if ((t_ptr->il).index >= 0) {
	strcpy_tonl(buffer, pat_get_text(pat, (t_ptr->il).index));

	if (strncmp(key, buffer, strlen(key)) == 0) {	/* match the key */
	    list = &(t_ptr->il);

	    while (list != NULL) {
		strcpy_tonl(buffer, pat_get_text(pat, list->index));
		if (strcmp_tonl(buffer, line) == 0) {
		    /*
		     * 全く同じのがあるので挿入せずにリターン 
		     * return, because there is entirely same string
		     */
		    return;
		}
		mae_wo_sasu_ptr = list;
		list = list->next;
	    }			/* この時点で list はリストの末尾を指す */
                                /* `list' point the end of list */

	    /*
	     * 既にあるキーに内容をさらに挿入する 
	     * insert the `content' for the existing `key'
	     */
	    new_l_ptr = pat_malloc_index_list();	/* list of index */
	    new_l_ptr->index = index;
	    new_l_ptr->next = NULL;
	    mae_wo_sasu_ptr->next = new_l_ptr;

	    return;
	}
    } else { /* データの無いノードに落ちた場合: 最初にデータをいれたとき */
             /* when the node has no data or
                when the node is inserted initial data */
	buffer[0] = buffer[1] = '\0';	/* 16bit */
    }

    /*
     * 挿入キーと衝突するキーとの間で 最初に異なる bit
     * の位置(diff_bit)を求める 
     * take `diff_bit' which is different 
     * between insersion key and collision key
     */
    buffer_length = strlen(buffer);
    for (diff_bit = 0;
	 !pat_bits(key, diff_bit, key_length)
	     == !pat_bits(buffer, diff_bit, buffer_length);
	 diff_bit++)
	;                           /* empty sentence */

    /*
     * キーを置く位置(x_ptr)を求める。 
     * take `x_ptr' which is put the `key'
     */
    do {
	p_ptr = x_ptr;
	/*
	 * key の checkbitビット目で左右に振り分け 
         * right or left by `checkbit'-th bit of key
	 */
	x_ptr = get_next_node(x_ptr, key, x_ptr->checkbit, key_length);
    } while ((x_ptr->checkbit < diff_bit)
	     && (p_ptr->checkbit < x_ptr->checkbit));

    /*
     * 挿入するノードを生成しキー・検査ビット等を設定する。 
     * make the new node to insert,
     * define `checkbit' etc..
     */
    new_ptr = pat_malloc_node();	 /* make new node */
    new_ptr->checkbit = diff_bit;	 /* define checkbit */
    (new_ptr->il).index = index;         /* define index in list */
    (new_ptr->il).next = NULL;           /* define next index in list */

    /*
     * define `mother node' and `daughter node'
     */
    /*
     * ビットが1なら右リンクがキーのある位置を指す。0なら左リンク。 
     * when bit is `1', right link point the position of key.
     * when bit is `0', left link point the position of key.
     */
    if (pat_bits(key, new_ptr->checkbit, key_length)) {
	new_ptr->right = new_ptr;
	new_ptr->left = x_ptr;
    } else {
	new_ptr->left = new_ptr;
	new_ptr->right = x_ptr;
    }
    /*
     * ビットが1なら、親の右につなぐ。0なら左。 
     * when bit is `1', connect to right of `mother node'.
     * when bit is `0', connect to left of `mother node'.
     */
    if (pat_bits(key, p_ptr->checkbit, key_length))
	p_ptr->right = new_ptr;
    else
	p_ptr->left = new_ptr;

    return;
}
