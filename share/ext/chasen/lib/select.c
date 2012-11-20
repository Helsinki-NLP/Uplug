/*
 * select.c - search with suffix array file
 *
 * Copyright (C) 2000, 2001, 
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
#include "sufary.h"
#include "tokenizer.h"
#include "htobe.h"

#define MINMIN(X,Y) ((X) < (Y) ? (X) : (Y))

/*
 * sistring の比較 
 */
static int cmp_sistr(char *, char *, int *, int);
static eresult sa_search(SUFARY *, char *, int, int);

#define sa_aryidx2txtptr(ary, idx) \
((ary)->txtmap + betoh(((long *)((ary)->arymap + (idx) * sizeof(long)))[0]))

/*
 * eresult sa_search(SUFARY *ary, char *s, int keylen, int base_offset);
 *
 * purpose
 *   検索を実行
 *
 * parameters
 *   ary : 検索対象ファイル
 *   s   : 検索キーワード
 *   keylen : キーワードの長さ
 *
 * return value
 *   プログラム継続モード
 *
 * description
 *   array から文字列を探索。
 *   2分探査を3回使って範囲検索をする
 *
 *                 abxxiabcdefgxyzpoop
 * ary->left       hipdabbbbbbbbbbxaba     ary->right
 *    |            bbbcfffffffffffhllm        |
 *    ------------------##########-------------
 *                     ||        ||
 *                l_out l_in  r_in r_out
 *
 * キーワード "fb" で検索した例。
 * 検索結果(範囲)は left_inside 〜 right_inside ( # で示した部分 )
 *
 * [重要] left, right は必ず検索範囲の内側を指す。 980319
 *
 *   ・書き変わるもの
 *       ary->ee : エラーコード(どんなエラーが発生したか)
 *       ary->right, ary->left : 自動的に次の検索範囲を狭める
 *
 */
static eresult
sa_search(SUFARY * ary, char *s, int keylen, int base_offset)
{
    long left_outside, right_outside, left_inside, right_inside, cur, tmp;
    int hr;
    int prefix_length_L = base_offset;
    int prefix_length_R = base_offset;
    int offset = 0, diffpos /* 異なり位置 */ ;

    if (ary == NULL || ary->arymap == NULL) {
	fprintf(stderr, "specify target files first.\n");
	return FAIL;
    }

    /*
     * 検索範囲初期設定 
     */
    right_outside = ary->right + 1;
    left_outside = ary->left - 1;
    right_inside = ary->right;
    left_inside = ary->left;

    /*
     * step 1. Match する点を見つける。
     */
    cur = (right_outside - left_outside) / 2 + left_outside;
    while (1) {
	offset = MINMIN(prefix_length_L, prefix_length_R);
	hr = cmp_sistr(sa_aryidx2txtptr(ary, cur) + offset,
		       s + offset, &diffpos, keylen - offset);
	if (hr < 0) {		/* LESS */
	    left_outside = cur;
	    prefix_length_L = offset + diffpos;
	} else if (hr > 0) {	/* ABOVE */
	    right_outside = cur;
	    prefix_length_R = offset + diffpos;
	} else {		/* MATCH ... if (hr == 0) */
	    left_inside = right_inside = cur;
	    break;
	}
	tmp = (right_outside - left_outside) / 2 + left_outside;
	/*
	 * left_outside は -1 の可能性あり。 ∴ tmp も -1 になることがある 
	 * 980319 
	 */
	if (cur == tmp || tmp < ary->left)
	    return FAIL;	/* 見つからなかった... */
	cur = tmp;
    }

    /*
     * step 2. right_inside を確定する 
     */
    offset = prefix_length_R;
    cur = (right_outside - right_inside) / 2 + right_inside;
    while (1) {
	hr = cmp_sistr(sa_aryidx2txtptr(ary, cur) + offset,
		       s + offset, &diffpos, keylen - offset);
	if (hr > 0) {		/* ABOVE */
	    right_outside = cur;
	    offset += diffpos;
	} else if (hr == 0) {	/* MATCH */
	    right_inside = cur;
	} else {		/* LESS ... if (hr < 0) */
	    ary->ee = STRUCTURE;
	    return _ERROR;
	}
	tmp = (right_outside - right_inside) / 2 + right_inside;
	if (cur == tmp)
	    break;
	cur = tmp;
    }

    /*
     * step 3. left_inside を確定する 
     */
    offset = prefix_length_L;
    cur = left_inside - (left_inside - left_outside) / 2;	/* 980319 */
    if (cur < 0)
	cur = 0;
    while (1) {
	hr = cmp_sistr(sa_aryidx2txtptr(ary, cur) + offset,
		       s + offset, &diffpos, keylen - offset);
	if (hr < 0) {		/* LESS */
	    left_outside = cur;
	    offset += diffpos;
	} else if (hr == 0) {	/* MATCH */
	    left_inside = cur;
	} else {		/* ABOVE ... if (hr > 0) */
	    ary->ee = STRUCTURE;
	    return _ERROR;
	}
	tmp = left_inside - (left_inside - left_outside) / 2;	/* 980319 */
	if (tmp < 0)
	    tmp = 0;
	if (cur == tmp)
	    break;
	cur = tmp;
    }

    /*
     * ary->left, ary->right の再設定 
     */
    ary->left = left_inside;
    ary->right = right_inside;

    return CONT;
}

/*
 *   int cmp_sistr(char *txt, char *str, int *diffpos, int len);
 *
 * purpose
 *   sistring の比較
 *
 * parameters
 *   txt : 比較される文字列(検索対象テキスト)
 *   str : 比較する文字列(検索キーワード)
 *   diffpos : 何文字目まで同じだったか？ 始めて異なった位置(文字目)
 *             書き換えて、返し値として使用。
 *   len : 比較する文字数
 *
 * return value (int)
 *   0 : MATCH 一致
 *   - : LESS  sistring(pos) < str  ('abc...' < 'ccc')
 *   + : ABOVE sistring(pos) > str  ('abc...' > 'aaa')
 *
 * description
 *   980422 に大改造
 *
 */
static int
cmp_sistr(char *txt, char *str, int *diffpos, int len)
{
    int i;
    for (i = 0; i < len; i++, txt++, str++)
	if (*txt != *str) {
	    *diffpos = i;
	    return ((unsigned char) *txt - (unsigned char) *str);
	}
    *diffpos = len;
    return 0;
}

/*
 * sa_reset(SUFARY *ary);
 *
 * purpose
 *   SUFARY型変数aryのrightとleftを元に戻す
 *
 * parameters
 *   ary : 対象array
 */
#define sa_reset(ary) \
    { (ary)->left = 0; \
      (ary)->right = (ary)->arraysize - 1; }

#define mbclen(mb) \
((((unsigned char)(mb) & 0x80)) ? 2 : 1)

/*
 *   char **sa_common_prefix_search(SUFARY *ary,
 *                                  char *pattern,
 *                                  int pattern_len,
 *                                  char **result);
 *
 * purpose
 *   Suffix Array を TRIE とみなして、形態素解析サーチを行なう
 *
 * parameters
 *   ary : 対象array
 *   pattern : 検索キーワード
 *   pattern_len : pattern のバイト長
 *   result  : 検索結果を格納するバッファ
 *
 * return value
 *   テキストインデックス(long)の配列へのポインタ
 *
 * description
 *  [Common Prefix Search とは...] 検索キーワード＊に＊Prefixマッチする
 *   文字列を取り出す。「検索キーワードが」ではないよ。
 *   例: 辞書            a, abc, any, anybody, anymore, ...
 *       検索キーワード  anybody
 *       結果            a, any, anybody
 */
char **
sa_common_prefix_search(SUFARY * ary, char *pattern, int pattern_len,
			char **result)
{
    int cursor;
    int result_last = 0;
    long tmp;

    sa_reset(ary);

    cursor = 0;
    while (1) {
	int next = cursor + cha_tok_mblen(Cha_tokenizer, pattern + cursor,
					  pattern_len - cursor);
	if (sa_search(ary, pattern, next, cursor) != CONT)
	    break;
	for (tmp = ary->left; tmp <= ary->right; tmp++) {
	    char *entry = sa_aryidx2txtptr(ary, tmp);
	    if (entry[next] != '\0')
		break;
	    result[result_last++] = entry;
	}
	cursor = next;
    }
    result[result_last] = NULL;

    return result;
}
