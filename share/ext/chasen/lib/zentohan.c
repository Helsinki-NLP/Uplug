/*
 * zentohan.c -- convert character code
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
 * 1991/01/08/Tue Yutaka MYOKI(Nagao Lab., KUEE)
 *
 * $Id$
 */

#ifdef SJIS

#include <stdio.h>
#include <string.h>

#define iskanji(x) ((unsigned char)(x) & 0x80)

/*
 *  euc->sjis, sjis->euc hankakukana->zenkaku code translation 
 */
unsigned char *
euc2sjis(unsigned char *str)
{
    unsigned char *s;
    for (s = str; *s; s++) {
	if (*s >= 0x80) {
	    if (*s & 1) {
		*(s + 1) -= 0x61;
		if (*(s + 1) >= 0x7f)
		    (*(s + 1))++;
	    } else
		*(s + 1) -= 2;

	    *s = ((*s + 1) >> 1) + 0x30;
	    if (*s >= 0xa0)
		*s += 0x40;
	    s++;
	}
    }
    return str;
}

/*
 * hankana2zenkana1
 *
 * return code: もとのポインタを必要に応じて進めたポインタ
 */
static unsigned char *
hankana2zenkana1(unsigned char *moto, unsigned char *ato)
{
    static unsigned char hankaku[] =
	{ 0x81, 0x42, 0x81, 0x75, 0x81, 0x76, 0x81, 0x41,
	  0x81, 0x45, 0x83, 0x92, 0x83, 0x40, 0x83, 0x42,
	  0x83, 0x44, 0x83, 0x46, 0x83, 0x48, 0x83, 0x83,
	  0x83, 0x85, 0x83, 0x87, 0x83, 0x62, 0x81, 0x5b,
	  0x83, 0x41, 0x83, 0x43, 0x83, 0x45, 0x83, 0x47,
	  0x83, 0x49, 0x83, 0x4a, 0x83, 0x4c, 0x83, 0x4e,
	  0x83, 0x50, 0x83, 0x52, 0x83, 0x54, 0x83, 0x56,
	  0x83, 0x58, 0x83, 0x5a, 0x83, 0x5c, 0x83, 0x5e,
	  0x83, 0x60, 0x83, 0x63, 0x83, 0x65, 0x83, 0x67,
	  0x83, 0x69, 0x83, 0x6a, 0x83, 0x6b, 0x83, 0x6c,
	  0x83, 0x6d, 0x83, 0x6e, 0x83, 0x71, 0x83, 0x74,
	  0x83, 0x77, 0x83, 0x7a, 0x83, 0x7d, 0x83, 0x7e,
	  0x83, 0x80, 0x83, 0x81, 0x83, 0x82, 0x83, 0x84,
	  0x83, 0x86, 0x83, 0x88, 0x83, 0x89, 0x83, 0x8a,
	  0x83, 0x8b, 0x83, 0x8c, 0x83, 0x8d, 0x83, 0x8f,
	  0x83, 0x93, 0x81, 0x4a, 0x81, 0x4b
    };
    
    unsigned char *p, *s;
    int dakuten;

    p = ato;
    s = moto;
    if (*(s + 1) == 0xde &&
	(*s >= 0xb6 && *s <= 0xc4 || *s >= 0xca && *s <= 0xce))
	dakuten = 1;
    else if (*(s + 1) == 0xdf && *s >= 0xca && *s <= 0xce)
	dakuten = 2;
    else
	dakuten = 0;
    *p++ = hankaku[(*s - 0xa1) * 2];
    *p++ = hankaku[(*s - 0xa1) * 2 + 1] + dakuten;
    if (dakuten) {
	s++;
    }
    return s;
}

unsigned char *
hankana2zenkana(unsigned char *str)
{
    unsigned char tmp[8192]; /* CHA_INPUT_SIZE */
    unsigned char *p, *s;

    p = tmp;
    for (s = str; *s; s++) {
	if ((0x80 <= *s && *s < 0xa0) || (0xe0 <= *s && *s <= 0xfc)) {
	    *p++ = *s++;
	    *p++ = *s;
	} else if (0xa1 <= *s && *s <= 0xdf) {
	    s = hankana2zenkana1(s, p);
	    p += 2;
	} else {
	    *p++ = *s;
	}
    }
    *p = '\0';
    strcpy(str, tmp);
    return str;
}

static void
sjis2euc1(unsigned char *hi, unsigned char *lo)
{
    if (*hi >= 0xe0)
	(*hi) -= 0x40;
    *hi = ((*hi - 0x30) << 1);

    if (*lo >= 0x9f)
	(*lo) += 2;
    else {
	(*hi)--;
	if (*lo >= 0x80)
	    (*lo) += 0x60;
	else
	    (*lo) += 0x61;
    }
}

unsigned char *
sjis2euc(unsigned char *str)
{
    unsigned char tmp[8192]; /* CHA_INPUT_SIZE */
    unsigned char *p, *s;

    if (!str[0])
	return str;

    p = tmp;
    for (s = str; *s; s++) {
	if ((0x80 <= *s && *s < 0xa0) || (0xe0 <= *s && *s <= 0xfc)) {
	    *p++ = *s++;
	    *p++ = *s;
	    sjis2euc1(p - 2, p - 1);
	} else if (0xa1 <= *s && *s <= 0xdf) {
	    s = hankana2zenkana1(s, p);
	    p += 2;
	    sjis2euc1(p - 2, p - 1);
	} else {
	    *p++ = *s;
	}
    }
    *p = '\0';
    strcpy(str, tmp);
    return str;
}
#endif				/* SJIS */
