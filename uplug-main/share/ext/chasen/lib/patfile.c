/*
 * patfile.c - library for patricia tree
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
#include "config.h"
#include <stdio.h>

#include "chadic.h"
#include "pat.h"

pat_node *pat_malloc_node(void);
static void pat_init_tree_top(pat_node *);
static void pat_com_l(char *, pat_node *);
static void pat_com_s(char *, pat_node *);

/*
 * pat_open
 */
pat_t *
pat_open(char *textfile, char *patfile)
{
    pat_t *pat;
    void *map;

    pat = cha_malloc(sizeof(pat_t));
    pat->_size = cha_mmap_file(textfile, &map);
    pat->_map = map;
    pat->root = pat_malloc_node();
    pat_init_tree_top(pat->root);

    if (patfile != NULL)
	pat_load(pat, patfile);

    return pat;
}

void
pat_load(pat_t * pat, char *patfile)
{
    pat_com_l(patfile, pat->root);
}

void
pat_save(pat_t * pat, char *patfile)
{
    pat_com_s(patfile, pat->root);
}

void
pat_text_reopen(pat_t * pat, char *textfile)
{
    void *map;

    cha_munmap_file(pat->_map, pat->_size);
    pat = cha_malloc(sizeof(pat_t));
    pat->_size = cha_mmap_file(textfile, &map);
    pat->_map = map;
}

/*
 * subroutines for pat_load_anode()
 */
pat_index_list *
pat_malloc_index_list(void)
{
    static int idx = 1024;
    static pat_index_list *ptr;

    if (idx == 1024) {
	ptr = cha_malloc(sizeof(pat_index_list) * idx);
	idx = 0;
    }

    return ptr + idx++;
}

pat_node *
pat_malloc_node(void)
{
    static int idx = 1024;
    static pat_node *ptr;

    if (idx == 1024) {
	ptr = cha_malloc(sizeof(pat_node) * idx);
	idx = 0;
    }

    return ptr + idx++;
}

static void
dummy(FILE * fp)
{
    fputc(0xff, fp);
    fputc(0xff, fp);
    fputc(0xff, fp);
    fputc(0xff, fp);
}

/*
 * pat_load_anode ---  パトリシア木をロード
 *                     load patricia tree
 *  by 米沢恵司(keiji-y@is.aist-nara.ac.jp)
 *
 * parameters:
 *   p_ptr --- このノードが外部接点であった時にインデックスを格納する場所
 *             内部接点であったときは、このポインタは右の子に渡される。
 *             when the node is the outside node, p_ptr is the index.
 *             when the node is the inside node, 
 *                              this pointer pass to right tree.
 *   fp --- input file
 *          
 *
 * Algorithm
 *   チェックビットを読み込んだら、それは内部接点だから新しくノードを作る
 *     左部分木、右部分木の順に再帰する
 *     左再帰の時は新しく作ったこの接点のポインタを、
 *     右再帰の時は p_ptr をインデックスの格納場所として渡す。
 *   インデックスを読み込んだら、それは外部接点だから、p_ptr->index に格納
 *
 *   When read `checkbit', it will be inside node.
 *     So make a new node. 
 *     And do recursion to left subtree and right subtree in this order.
 *     When left subtree recursion, return pointer to this new node.
 *     When right subtree recursion, return p_ptr which contains `index'.
 *   When read `index', it will be outside node.
 *     Put `index' to p_ptr->index.
 *
 * memo
 *   インデックスの格納場所が元と違うが、特に問題ない。
 *   Where contains `index' is different between original algorithm 
 *   and this program.  But no problem.
 */
static pat_node *
pat_load_anode(pat_node * p_ptr, FILE * fp)
{
    unsigned char c;
    pat_node *new_ptr;      /* pointer to new node (= this node) */
                       
    long tmp_idx;
    pat_index_list *new_l_ptr, *t_ptr = NULL;

    if ((c = fgetc(fp)) & 0x80) { /* process leaves, read index */
	while (c & 0x80) {
	    tmp_idx = (c & 0x3f) << 24;
	    tmp_idx |= fgetc(fp) << 16;
	    tmp_idx |= fgetc(fp) << 8;
	    tmp_idx |= fgetc(fp);

	    if ((p_ptr->il).index < 0)
		new_l_ptr = &(p_ptr->il);
	    else {
		new_l_ptr = pat_malloc_index_list();
		t_ptr->next = new_l_ptr;
	    }
	    new_l_ptr->index = tmp_idx;
	    new_l_ptr->next = NULL;
	    t_ptr = new_l_ptr;

	    if (c & 0x40)
		break;
	    c = fgetc(fp);
	}

	return p_ptr;
    } else {   /* process of inside node (recursive) */
	new_ptr = pat_malloc_node();
	new_ptr->checkbit = ((c << 8) | fgetc(fp)) - 1;	 /* checkbit */
	(new_ptr->il).index = -1;
	new_ptr->left = pat_load_anode(new_ptr, fp);
	new_ptr->right = pat_load_anode(p_ptr, fp);
	return new_ptr;
    }
}

/*
 * pat_com_l --- load tree
 *               
 *  by 米沢恵司(keiji-y@is.aist-nara.ac.jp)
 */
static void
pat_com_l(char *fname_pat, pat_node * ptr)
{
    FILE *fp;

    if ((fp = fopen(fname_pat, "rb")) == NULL) {
	fprintf(stderr, "can't open %s\n", fname_pat);
	exit(1);
    }
    ptr->right = pat_load_anode(ptr, fp);
    fclose(fp);
}

/*
 * save_pat --- パトリシア木データをセーブ 
 *              save patricia tree data
 *  by 米沢恵司(keiji-y@is.aist-nara.ac.jp)
 *
 * parameters:
 *   top_ptr --- 検索開始ノードの位置(ポインタ)
 *               pointer to a node -- search starting point
 *   fp --- 出力先(stdoutやファイル)
 *               output (stdout or FILE)
 * 
 * return:
 *   none.
 *   output patricia tree to `fp'
 *
 * 出力フォーマット --- 8ビットに区切ってバイナリ出力
 * output format --- segment to 8bit per unit 
 *   左優先探索で内部接点はチェックビット、外部接点はインデックスを出力
 *   チェックビット --- 基本的にそのまま (第 0 ビットが 0)
 *     ただし -1 のとき困るので 1 を足す
 *   インデックス --- 第 0 ビットを 1 にする
 *   left most search:
 *        if inside node, output `checkbit'
 *        if outside node, output `index'
 *     `checkbit': basically we use original bit
 *                 0 bit will be `0'
 *                 But when -1 bit, plus 1.
 *     `index': 0 bit will be `1'
 */
static void
save_pat(pat_node * top_ptr, FILE * fp)
{
    pat_index_list *ptr;

    /*
     * 内部接点の処理、チェックビットを出力
     *   process inside node, output checkbit
     */
    fputc(((top_ptr->checkbit + 1) >> 8) & 0x7f, fp);
    fputc((top_ptr->checkbit + 1) & 0xff, fp);

    /*
     * 左右の Subtree の処理。葉っぱならインデックスを出力、
     * 葉っぱでなければ再帰。
     *   process subtree,
     *     if node is a leaf, output index
     *     otherwise, do recursion
     */
    if (top_ptr->checkbit < top_ptr->left->checkbit)
	save_pat(top_ptr->left, fp);
    else {
	ptr = &(top_ptr->left->il);
	if (ptr->index < 0)
	    dummy(fp);
	else {
	    while (ptr != NULL) {
		if (ptr->next == NULL)
		    fputc(((ptr->index >> 24) & 0x3f) | 0xc0, fp);
		else
		    fputc(((ptr->index >> 24) & 0x3f) | 0x80, fp);
		fputc((ptr->index >> 16) & 0xff, fp);
		fputc((ptr->index >> 8) & 0xff, fp);
		fputc((ptr->index) & 0xff, fp);
		ptr = ptr->next;
	    }
	}
    }
    if (top_ptr->checkbit < top_ptr->right->checkbit)
	save_pat(top_ptr->right, fp);
    else {
	ptr = &(top_ptr->right->il);
	if (ptr->index < 0)
	    dummy(fp);
	else {
	    while (ptr != NULL) {
		if (ptr->next == NULL)
		    fputc(((ptr->index >> 24) & 0x3f) | 0xc0, fp);
		else
		    fputc(((ptr->index >> 24) & 0x3f) | 0x80, fp);
		fputc((ptr->index >> 16) & 0xff, fp);
		fputc((ptr->index >> 8) & 0xff, fp);
		fputc((ptr->index) & 0xff, fp);
		ptr = ptr->next;
	    }
	}
    }
}

/*
 * pat_com_s --- save a patricia tree to file
 *               
 *  by 米沢恵司(keiji-y@is.aist-nara.ac.jp)
 */
static void
pat_com_s(char *fname_pat, pat_node * ptr)
{
    FILE *fp;

    printf("Saving pat-tree \"%s\" ...\n", fname_pat);
    fp = fopen(fname_pat, "w+b");
    if (fp == NULL) {
	fprintf(stderr, "can't open %s\n", fname_pat);
	exit(1);
    };
    save_pat(ptr->right, fp);	/* output to file */
    fclose(fp);
}

/*
 * pat_init_tree_top --- initialize a root of patricia tree
 *                       
 * parameter:
 *   ptr --- pointer to a root of patricia tree 
 */
static void
pat_init_tree_top(pat_node * ptr)
{
    (ptr->il).index = -1;	/* list of index is -1 */
    ptr->checkbit = -1;         /* checkbit is -1 */
    ptr->right = ptr;           /* right node point itself */
    ptr->left = ptr;            /* left node point itself */
}
