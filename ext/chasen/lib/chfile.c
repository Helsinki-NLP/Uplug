/*
 *  chfile.c - �ե�����γ��Ľ���                 
 *             open/close suffix array files   
 *  SUFARY --- Suffix Array �����Τ���Υ饤�֥��
 *
 * Copyright (C) 2000, 2001,
 *                             Nara Institute of Science and Technology
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
 *                                                        
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "chadic.h"
#include "sufary.h"

static void sa_opentextfile(SUFARY *, char *);
static void sa_openarrayfile(SUFARY *, char *);
static void sa_closetextfile(SUFARY *);
static void sa_closearrayfile(SUFARY *);


/*
 * SUFARY *sa_openfiles(char *s, char *t);
 *
 * purpose
 *   ���ꤵ�줿�ƥ����ȥե�����(s)��array�ե�����(t)�򳫤���
 *   array�ե�����̾��NULL�˻��ꤹ��С��ƥ����ȥե�����̾��
 *   '.ary' ���ղä�����Τ�array�ե�����̾�ˤʤ롣
 *
 * parameters
 *   t : array�ե�����̾
 *   s : �ƥ����ȥե�����̾
 *
 * return value
 *   �������줿SUFARY���ѿ�
 */
SUFARY *
sa_openfiles(char *s, char *t)
{
    SUFARY *newary;
    char aryname[8192];

    newary = cha_malloc(sizeof(SUFARY));

    sa_opentextfile(newary, s);
    if (t == NULL) { /* text filename is not specified */
	sprintf(aryname, "%s.ary", s);
	t = aryname;
    }
    sa_openarrayfile(newary, t);

    return newary;
}


/*
 * open text file
 */
static void
sa_opentextfile(SUFARY * ary, char *filename)
{
    off_t size;
    void *map;

    /*
     * ���˥����ץ󤵤�Ƥ����Τ�����Х����� 
     */
    if (ary->txtmap != NULL) {
	sa_closetextfile(ary);
    }

    size = cha_mmap_file(filename, &map);

    ary->txtsz = size;
    ary->txtmap = map;
}

/*
 * open array file
 */
static void
sa_openarrayfile(SUFARY * ary, char *filename)
{
    off_t size;
    void *map;

    /*
     * ���˥����ץ󤵤�Ƥ����Τ�����Х����� 
     */
    if (ary->arymap != NULL) {
	sa_closearrayfile(ary);
    }

    size = cha_mmap_file(filename, &map);
    ary->arysz = size;
    ary->arraysize = size / sizeof(long);
    ary->arymap = map;
    /*
     * left, right �ϸ����ϰϤ���¦��ؤ�
     */
    ary->left = 0;
    ary->right = ary->arraysize - 1;
}

/*
 * void sa_closefiles(SUFARY *ary);
 *
 * purpose
 *   ���ꤵ�줿�ե�������Ĥ���
 * 
 * parameters
 *   ary : �Ĥ������ե�����˴ؤ���SUFARY���ѿ�
 *
 * return value
 *   �ʤ�
 *
 * description
 *   �ƥ����ȥե������array�ե������Ʊ�����Ĥ���
 */
void
sa_closefiles(SUFARY * ary)
{
    sa_closetextfile(ary);
    sa_closearrayfile(ary);
    cha_free(ary);
}

/*
 * close text file
 */
static void
sa_closetextfile(SUFARY * ary)
{
    if (ary->txtmap != NULL) {
	cha_munmap_file(ary->txtmap, ary->txtsz);
	ary->txtmap = NULL;
	ary->txtsz = 0;
    }
}

/*
 * close array file
 */
static void
sa_closearrayfile(SUFARY * ary)
{
    if (ary->arymap != NULL) {
	cha_munmap_file(ary->arymap, ary->arysz);
	ary->arymap = NULL;
	ary->arysz = 0;
    }
    ary->arraysize = 0;
    ary->left = 0;
    ary->right = 0;
}
