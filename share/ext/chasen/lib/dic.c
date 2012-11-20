/*
 * dic.c -- library for parsing dictionary
 *
 * Copyright (C) 2000, 2001,  Nara Institute of Science and Technology
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
 *
 * $Id$
 */
#include "chalib.h"

SUFARY *Suf_dicfile[PAT_DIC_NUM];	/* dictionary (SUFDIC) */
pat_t *Pat_dicfile[PAT_DIC_NUM];	/* dictionary (PATDIC) */
int Suf_ndicfile = 0;
int Pat_ndicfile = 0;

void
cha_get_mrph_data(mrph2_t * mrph, char *pbuf, char *target)
{
    unsigned char *p = pbuf;

    mrph->midasi = target;	/* surface form */
    mrph->is_undef = 0;		/* unseen word or not */

    /*
     * 見出し語の長さ the length of surface form
     */
    while (*p++);
    mrph->base_length = mrph->length = (char *) p - pbuf - 1;
    /*
     * 読み Japanese reading 
     */
    mrph->yomi = p;
    while (*p++);
    /*
     * 発音 Japanese pronunciation 
     */
    mrph->pron = p;
    while (*p++);
    /*
     * 原形 infinitive form 
     */
    mrph->base = p;
    while (*p++);
    /*
     * 意味 semantic information 
     */
    mrph->info = p;
    while (*p++);

    /*
     * 品詞大分類 POS number 
     */
    mrph->hinsi =
	(p[0] - CHAINT_OFFSET) * CHAINT_SCALE + p[1] - CHAINT_OFFSET;
    p += 2;
    /*
     * 活用型 Conjugation type 
     */
    mrph->ktype = *p++ - CHAINT_OFFSET;
    /*
     * 活用形 Conjugation form 
     */
    mrph->kform = *p++ - CHAINT_OFFSET;
    /*
     * 重み cost for morpheme 
     */
    mrph->weight =
	(p[0] - CHAINT_OFFSET) * CHAINT_SCALE + p[1] - CHAINT_OFFSET;
    p += 2;
    /*
     * 接続テーブル番号 the number for connection matrix 
     */
    mrph->con_tbl =
	(p[0] - CHAINT_OFFSET) * CHAINT_SCALE + p[1] - CHAINT_OFFSET;
    p += 2;
    /*
     * 複合語  compound words information 
     */
    mrph->compound = p;
}
