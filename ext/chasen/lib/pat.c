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
 * pat_bits --- ʸ������λ��ꤵ�줿���֤ΥӥåȤ��֤�
 *              position given for string
 *              return the bit of the position
 * 
 * parameters:
 *   string --- ʸ����
 *              string
 *   cbit --- ���ꤵ�줿���֡�ʸ�������Τ��ĤΥӥå���ȹͤ���
 *            ��Ƭ(��)bit���� 0,1,2,3... �ǻ��ꤹ�롣
 *            position.  
 *            string is regarded as a sequence of bits.
 *            the first(left) bit is 0.
 *   len --- ʸ�����Ĺ����strlen�򤤤�������äƤ��󤸤����Ѥ����� 
 *           the length of string.  --- strlen is cumbersome...
 *
 * return:
 *   0 / not 0
 */
static int
pat_bits(char *string, int cbit, int len)
{
    int moji_idx = cbit / 8;	/* ���ꤵ�줿���֤���ʸ���ܤ� */
                                /* the position to what number by character */
/*      static int bitval[8] = */
/*  	{ 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01 }; */
/*      printf("[%d,%d,%d]", cbit, moji_idx, len); */
/*      if (moji_idx > len) { */
/*  	printf("!!!!!!!!!!!!!!!"); */
/*  	exit(1); */
/*      } */

    /*
     * ���ꤵ�줿���� >= ʸ�����Ĺ���Υ����å� 
     * check (the position >= the length of string)
     */
    if (moji_idx >= len)
	return 0;
    /*
     * �ȥåץΡ��ɤΤȤ���1���֤�(top�����ɬ����) 
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
 * key �� checkbit�ӥå��ܤǺ����˿���ʬ�� 
 * right or left by `checkbit'-th key
 */
#define get_next_node(node, key, checkbit, key_length) \
((pat_bits((key), (checkbit), (key_length))) ? (node)->right : (node)->left)

/*
 * pat_search --- search patricia tree
 * 
 * parameter
 *   key --- ��������
 *   result --- ��̤�����롥
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
	if (checkbit % SIKII_BIT == 0 && checkbit) {	/* ����ñ���õ�� */ /* search word */
	    tmp_ptr = ptr->left;
#ifdef DEBUG
	    printf("\n[%d,%02x%02x]", checkbit, key[0], key[1]);
#endif
	    /*
	     * ��Ƭ�Ρָ��Ф������ʬ�����ǥޥå��󥰤�Ԥʤ� 
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
	 * key �� checkbit�ӥå��ܤǺ����˿���ʬ�� 
         * right or left by `checkbit'-th bit of key
	 */
	ptr = get_next_node(ptr, key, checkbit, key_length);
    } while (checkbit < ptr->checkbit);

    if (ptr != tmp_ptr || ptr == top_ptr) { /* check the end node or not */
	char *line = pat_get_text(pat, (ptr->il).index);
	/*
	 * buffer����Ƭ�Ρָ��Ф������ʬ�����ǥޥå��󥰤�Ԥʤ� 
         * matching by `surface form'
	 */
	/*
	 * �����ɤޤ�ñ���Prefix�����å� 
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
 * pat_search_exact --- �ѥȥꥷ���ڤ򸡺�(search patricia tree exact match)
 * 
 * parameter
 *   key --- ��������
 *   x_ptr --- �������ϰ���(�ݥ���)
 *             pointer to position where the search begin
 *   result --- ��̤�����롥
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
     * �ե����뤫���ä���� 
     * get text from file
     */
    line = pat_get_text(pat, (x_ptr->il).index);

    /*
     * buffer����Ƭ�Ρָ��Ф������ʬ�����ǥޥå��󥰤�Ԥʤ� 
     * pattern match by `surface form' which is at the first column in `.int'
     */
    if (strcmp(key, line) == 0) {	/* �����ɤޤ�ñ��Υ����å� */
                                        /* check the dead end word */
	list = &(x_ptr->il);	/* ���ꥹ�����Ǥμ��Ф� */
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
 * pat_search4insert --- �����Ѥ˸���
 *                       search for insersion
 * 
 * parameter
 *   key --- ��������
 *   node --- �������ϰ���(�ݥ���)
 *            pointer to a position where the search begin
 * 
 * return
 *   ������λ����(�ݥ���)
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
 * pat_insert --- �ѥȥꥷ���ڤ˥ǡ���������
 *                insert data for patricia tree
 * 
 * Parameter
 *   f --- file
 *   line --- �ǡ���(�������������Ƥ����ڤ�ʸ���Ƕ��ڤ��Ƥ��빽¤)
 *            key and contents (segmented by delimiter)
 *   index --- �ǡ����Υե������Υ���ǥå���
 *            `index' for data file
 *   x_ptr --- �����Τ���θ����γ��ϰ���
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
		     * ����Ʊ���Τ�����Τ����������˥꥿���� 
		     * return, because there is entirely same string
		     */
		    return;
		}
		mae_wo_sasu_ptr = list;
		list = list->next;
	    }			/* ���λ����� list �ϥꥹ�Ȥ�������ؤ� */
                                /* `list' point the end of list */

	    /*
	     * ���ˤ��륭�������Ƥ򤵤���������� 
	     * insert the `content' for the existing `key'
	     */
	    new_l_ptr = pat_malloc_index_list();	/* list of index */
	    new_l_ptr->index = index;
	    new_l_ptr->next = NULL;
	    mae_wo_sasu_ptr->next = new_l_ptr;

	    return;
	}
    } else { /* �ǡ�����̵���Ρ��ɤ���������: �ǽ�˥ǡ����򤤤줿�Ȥ� */
             /* when the node has no data or
                when the node is inserted initial data */
	buffer[0] = buffer[1] = '\0';	/* 16bit */
    }

    /*
     * ���������Ⱦ��ͤ��륭���Ȥδ֤� �ǽ�˰ۤʤ� bit
     * �ΰ���(diff_bit)����� 
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
     * �������֤�����(x_ptr)����롣 
     * take `x_ptr' which is put the `key'
     */
    do {
	p_ptr = x_ptr;
	/*
	 * key �� checkbit�ӥå��ܤǺ����˿���ʬ�� 
         * right or left by `checkbit'-th bit of key
	 */
	x_ptr = get_next_node(x_ptr, key, x_ptr->checkbit, key_length);
    } while ((x_ptr->checkbit < diff_bit)
	     && (p_ptr->checkbit < x_ptr->checkbit));

    /*
     * ��������Ρ��ɤ������������������ӥå��������ꤹ�롣 
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
     * �ӥåȤ�1�ʤ鱦��󥯤������Τ�����֤�ؤ���0�ʤ麸��󥯡� 
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
     * �ӥåȤ�1�ʤ顢�Ƥα��ˤĤʤ���0�ʤ麸�� 
     * when bit is `1', connect to right of `mother node'.
     * when bit is `0', connect to left of `mother node'.
     */
    if (pat_bits(key, p_ptr->checkbit, key_length))
	p_ptr->right = new_ptr;
    else
	p_ptr->left = new_ptr;

    return;
}
