/*
 * tokenizer.c - tokenize a string
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

#include <string.h>
#include <ctype.h>

#include "chalib.h"
#include "tokenizer.h"

#define is_space(c) (((c) == ' ') || ((c) == '\t'))

enum ja_char_type {
    JA_NOSTATE,
    JA_SPACE,
    PROLONGED,      /* KATAKANA-HIRAGANA PROLONGED SOUND MARK */
    KATAKANA,       /* KATAKANA LETTER (SMALL) [A-KE] */
    SMALL_KATAKANA, /* KATAKANA LETTER SMALL AIUEO, TU, YAYUYO, WA */
    FULL_LATIN,     /* FULLWIDTH LATIN (CAPITAL|SMALL) LETTER [A-Z] */
    HALF_LATIN,     /* LATIN (CAPITAL|SMALL) LETTER [A-Z] */
    JA_OTHER,
};

enum en_char_type {
    EN_NOSTATE,
    EN_SPACE,
    EN_LATIN,
    EN_OTHER,
};

static int euc_mblen(unsigned char*, int);
static int iso8859_mblen(unsigned char*, int);
static int utf8_mblen(unsigned char*, int);

static int ja_char_type_parse(chasen_tok_t*,int,int*,int);
static int en_char_type_parse(chasen_tok_t*,int,int*,int);

static enum ja_char_type
ja_euc_char_type(chasen_tok_t*, unsigned char *, int);
static enum ja_char_type
ja_utf8_char_type(chasen_tok_t*, unsigned char *, int);

static enum en_char_type
en_char_type(chasen_tok_t*, unsigned char *, int);

typedef int (*ja_char_type_get)(chasen_tok_t*,unsigned char*,int);
typedef int (*en_char_type_get)(chasen_tok_t*,unsigned char*,int);

static int is_anno(chasen_tok_t*, unsigned char*, int);
static int is_anno2(anno_info*, unsigned char*, int);

/*
 * This function constructs a tokenizer object.
 * If an error occurs, it terminates a process.
 */
chasen_tok_t *
cha_tok_new(int lang, int encode)
{
    chasen_tok_t *tok;

    tok = cha_malloc(sizeof(chasen_tok_t));

    tok->lang = lang;
    tok->encode = encode;
    tok->_is_malloced = 0;
    tok->_char_type = tok->__static_char_type;
    tok->_anno_type = tok->__static_anno_type;
    tok->anno = NULL;

    if (lang == CHASEN_LANG_JA) {
	if (encode == CHASEN_ENCODE_EUCJP) {
	    tok->_mblen = euc_mblen;
	    tok->_char_type_parse = ja_char_type_parse;
	    tok->_get_char_type = (ja_char_type_get)ja_euc_char_type;
	} else if (encode == CHASEN_ENCODE_UTF8) {
	    tok->_mblen = utf8_mblen;
	    tok->_char_type_parse = ja_char_type_parse;
	    tok->_get_char_type = (ja_char_type_get)ja_utf8_char_type;
	}
    } else if (lang == CHASEN_LANG_EN) {
	if (encode == CHASEN_ENCODE_ISO8859) {
	    tok->_mblen = iso8859_mblen;
	    tok->_char_type_parse = en_char_type_parse;
	    tok->_get_char_type = (en_char_type_get)en_char_type;
	} else if (encode == CHASEN_ENCODE_UTF8) {
	    tok->_mblen = utf8_mblen;
	    tok->_char_type_parse = en_char_type_parse;
	    tok->_get_char_type = (en_char_type_get)en_char_type;
	}
    } else {
	tok->_mblen = iso8859_mblen;
	tok->_char_type_parse = en_char_type_parse;
	tok->_get_char_type = (en_char_type_get)en_char_type;
    }

    return tok;
}

/*
 * This function destroys the tokenizer object.
 */
void
cha_tok_delete(chasen_tok_t *tok)
{
    if (tok->_is_malloced) {
	cha_free(tok->_char_type);
	cha_free(tok->_anno_type);
    }
    cha_free(tok);
}

/*
 * This function parses string str with len bytes.
 */
int
cha_tok_parse(chasen_tok_t *tok, unsigned char *str, int len)
{
    int cursor, head;
    int state, state0;
    anno_info *anno = NULL;

    tok->string = str;
    tok->string_len = len;

    if (len > sizeof(tok->__static_char_type) / sizeof(int)) {
	tok->_char_type = cha_malloc(sizeof(int) * len);
	tok->_anno_type = cha_malloc(sizeof(int) * len);
	tok->_is_malloced = 1;
    }

    memset(tok->_char_type, 0, sizeof(int) * len);
    memset(tok->_anno_type, 0, sizeof(int) * len);

    state0 = state = 0; /* NOSTATE */
    for (cursor = head = 0; cursor < len;
	 cursor += tok->_mblen(str + cursor, len - cursor)) {
	if (state0 < 0) { /* in annotation */
	    if (is_anno2(anno, str, cursor)) {
		state0 = 0; /* end of annotation */
	    } else {
		continue; /* skip annotation */
	    }
	} 

	state = is_anno(tok, str + cursor, len - cursor);
	if (state < 0) {
	    anno = &(tok->anno[-state]);
	    tok->_anno_type[cursor] = -state;
	} else {
	    state = tok->_get_char_type(tok, str + cursor, len - cursor);
	    state = tok->_char_type_parse(tok, state, &state0, cursor);
	}

	if (state != state0) {
	    tok->_char_type[head] = cursor - head;
	    head = cursor;
	}
	state0 = state;
    }
    tok->_char_type[head] = cursor - head;

    return 1;
}

/*
 * This function returns the length in bytes of the multibyte character
 * on cursor in the parsed string.
 *
 * If the character is `\0', it returns 1.
 */
int
cha_tok_mblen_on_cursor(chasen_tok_t *tok, int cursor)
{
    return tok->_mblen(tok->string + cursor,
		       tok->string_len - cursor);
}

/*
 * This function returns the length in bytes of the multibyte character
 * str with len bytes.
 *
 * If the character is `\0', it returns 1.
 */
int
cha_tok_mblen(chasen_tok_t *tok, unsigned char *str, int len)
{
    return tok->_mblen(str, len);
}

/*
 * This function returns the length in bytes of the substring
 * including same kind of characters.
 *
 * In the middle of substring, it returns 0.
 */
int
cha_tok_char_type_len(chasen_tok_t *tok, int cursor)
{
    return tok->_char_type[cursor];
}

/*
 * This function sets information of annotation anno in tokenizer tok.
 */
void
cha_tok_set_annotation(chasen_tok_t *tok, anno_info *anno)
{
    tok->anno = anno;
}

/*
 * This function returns the type of annotation, if there is 
 * the begining of annotation on cursor.  The type is more than 0.
 *
 * And it returns less than 0 value, if the character on cursor is
 * white space.
 *
 * Otherwise it returns 0.
 */
int
cha_tok_anno_type(chasen_tok_t *tok, int cursor)
{
    return tok->_anno_type[cursor];
}

/*
 * This function is ad-hoc. You should not use it.
 *
 * But it is used in lib/parse.c(cha_parse_sentence).
 */
int
cha_tok_is_jisx0208_latin(chasen_tok_t *tok, int cursor, int len)
{
    if ((tok->lang == CHASEN_LANG_JA) &&
	(tok->_get_char_type(tok, tok->string + cursor, len) == FULL_LATIN))
	return 1;
    else
	return 0;

}

/*
 * private functions
 */
static int
euc_mblen(unsigned char *str, int len)
{
    if (len >= 3 && 
	str[0] == 0x8f && (str[1] & 0x80) && (str[2] & 0x80)) {
	return 3;
    } else if (len >= 2 && (str[0] & 0x80) && (str[1] & 0x80)) {
	return 2;
    }

    return 1;
}

static int
iso8859_mblen(unsigned char *str, int len)
{
    return 1;
}

static int
utf8_mblen(unsigned char *str, int len)
{
    if (len >= 4 && (str[0] & 0xf0) == 0xf0 &&
	(str[1] & 0x80) && (str[2] & 0x80) && (str[3] & 0x80)) {
	return 4;
    } else if (len >= 3 && (str[0] & 0xe0) == 0xe0 &&
	       (str[1] & 0x80) && (str[2] & 0x80)) {
	return 3;
    } else if (len >= 2 && (str[0] & 0xc0) == 0xc0 && (str[1] & 0x80)) {
	return 2;
    }

    return 1;
}

static int
ja_char_type_parse(chasen_tok_t *tok, int state, int *state0, int cursor)
{
    if (state == JA_SPACE) {
	tok->_anno_type[cursor] = -1;
    } else if ((state == HALF_LATIN) ||
	       (state == FULL_LATIN)) {
	; /* do nothing */
    } else if (((*state0 == KATAKANA) &&
		((state == PROLONGED) ||
		 (state == SMALL_KATAKANA))) ||
	       (state == KATAKANA)) {
	state = KATAKANA;
    } else {
	state = JA_OTHER;
	*state0 = JA_NOSTATE;
    }

    return state;
}

static int
en_char_type_parse(chasen_tok_t *tok, int state, int *state0, int cursor)
{
    if (state == EN_SPACE) {
	tok->_anno_type[cursor] = -1;
    } else if (state == EN_OTHER) {
	*state0 = EN_NOSTATE;
    }

    return state;
}

static enum ja_char_type
ja_euc_char_type(chasen_tok_t *tok, unsigned char *str, int len)
{
    int mblen = tok->_mblen(str, len);

    if (mblen == 1) {
	if (isalpha(str[0])) {
	    return HALF_LATIN;
	} else if (is_space(str[0])) {
	    return JA_SPACE;
	}
    } else if (mblen == 2) {
	if ((str[0] == 0xa1) && (str[1] == 0xbc)) {
	    return PROLONGED;
	} else if (str[0] == 0xa5) {
	    if ((str[1] == 0xa1) || (str[1] == 0xa3) ||
		(str[1] == 0xa5) || (str[1] == 0xa7) ||
		(str[1] == 0xa9) || (str[1] == 0xc3) ||
		(str[1] == 0xe3) || (str[1] == 0xe5) ||
		(str[1] == 0xe7) || (str[1] == 0xee)) {
		return SMALL_KATAKANA;
	    } else {
		return KATAKANA;
	    }
	} else if ((str[0] == 0xa3) && (str[1] >= 0xc1)) {
	    return FULL_LATIN;
	}
    }

    return JA_OTHER;
}

static enum ja_char_type
ja_utf8_char_type(chasen_tok_t *tok, unsigned char *str, int len)
{
    int mblen = tok->_mblen(str, len);

    if (mblen == 1) {
	if (isalpha(str[0])) {
	    return HALF_LATIN;
	} else if (is_space(str[0])) {
	    return JA_SPACE;
	}
    } else if (mblen == 3) {
	if ((str[0] == 0xe3) && (str[1] == 0x83) && (str[2] == 0xbc)) {
	    return PROLONGED;
	} else if (str[0] == 0xe3) {
	    if (((str[1] == 0x82) &&
		 ((str[2] == 0xa1) || (str[2] == 0xa3) ||
		  (str[2] == 0xa5) || (str[2] == 0xa7) ||
		  (str[2] == 0xa9))) ||
		((str[1] == 0x83) &&
		  ((str[2] == 0x83) || (str[2] == 0xa3) ||
		   (str[2] == 0xa5) || (str[2] == 0xa7) ||
		   (str[2] == 0xae)))) {
		return SMALL_KATAKANA;
	    } else if (((str[1] == 0x82) &&
			(str[2] >= 0xa1) && (str[2] <= 0xbf)) ||
		       ((str[1] == 0x83) &&
			(str[2] >= 0x80) && (str[2] <= 0xBA))) {
		return KATAKANA;
	    }
	} else if ((str[0] == 0xef) &&
		   (((str[1] == 0xbc) &&
		     (str[2] >= 0xa1) && (str[2] <= 0xba)) ||
		    ((str[1] == 0xbd) &&
		     (str[2] >= 0x81) && (str[2] <= 0x9a)))) {
	    return FULL_LATIN;
	}
    }

    return JA_OTHER;
}

static enum en_char_type
en_char_type(chasen_tok_t *tok, unsigned char *str, int len)
{
    unsigned char c = str[0];

    if (is_space(c)) {
	return EN_SPACE;
    } else if (isalpha(c)) { /* for English only */
	return EN_LATIN;
    }
	
    return EN_OTHER;
}


static int
is_anno(chasen_tok_t *tok, unsigned char *string, int len)
{
    int i;
    anno_info *anno = tok->anno;

    if (anno == NULL) {
	return 0;
    }
    for (i = 1; (anno[i].str1 != NULL); i++) {
	if (len < anno[i].len1) {
	    continue;
	}
	if (!memcmp(string, anno[i].str1, anno[i].len1)) {
	    return -i;
	}
    }
    return 0;
}

static int
is_anno2(anno_info *anno, unsigned char *bos, int cursor)
{
    int len2 = anno->len2;

    if (cursor < len2) {
	return 0;
    }

    return (memcmp(bos + cursor - len2, anno->str2, len2) == 0);
}
