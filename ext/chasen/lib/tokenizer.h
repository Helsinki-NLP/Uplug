/*
 * $Id$
 */

#ifndef __TOKENIZER_H__
#define __TOKENIZER_H__

#include "chalib.h"

/* for language */
enum cha_lang {
    CHASEN_LANG_JA,
    CHASEN_LANG_EN
};

/* for encoding scheme */
enum cha_encode {
    CHASEN_ENCODE_EUCJP,
    CHASEN_ENCODE_ISO8859,
    CHASEN_ENCODE_UTF8
};

typedef struct _chasen_tok_t chasen_tok_t;
struct _chasen_tok_t {
    enum cha_lang lang;
    enum cha_encode encode;
    unsigned char *string;
    int string_len;
    anno_info *anno;
    /* private member */
    int *_char_type;
    int *_anno_type;
    int _is_malloced;
    int __static_char_type[CHA_INPUT_SIZE];
    int __static_anno_type[CHA_INPUT_SIZE];
    int (*_mblen)(unsigned char*, int);
    int (*_get_char_type)(chasen_tok_t*,unsigned char*, int);
    int (*_char_type_parse)(chasen_tok_t*,int,int*,int);
};

extern enum cha_lang Cha_lang;
extern enum cha_encode Cha_encode;
extern chasen_tok_t *Cha_tokenizer;

chasen_tok_t *cha_tok_new(int, int);
void cha_tok_delete(chasen_tok_t*);

int cha_tok_parse(chasen_tok_t*, unsigned char*, int);
int cha_tok_mblen_on_cursor(chasen_tok_t*, int);

int cha_tok_mblen(chasen_tok_t*,unsigned char*,int);
int cha_tok_char_type_len(chasen_tok_t*, int);

void cha_tok_set_annotation(chasen_tok_t*, anno_info*);
int cha_tok_anno_type(chasen_tok_t*, int);

int cha_tok_is_jisx0208_latin(chasen_tok_t*, int, int);

#endif /*__TOKENIZER_H__ */
