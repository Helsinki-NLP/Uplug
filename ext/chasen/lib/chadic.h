/*
 * chadic.h
 *     1990/12/06/Thu  Yutaka MYOKI(Nagao Lab., KUEE)
 *
 * $Id$
 */

#ifndef __CHADIC_H__
#define __CHADIC_H__

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <limits.h>

#ifdef HAVE_UNISTD_H
#include <sys/types.h>
#endif /* HAVE_UNISTD_H */

#include "pat.h"
#include "sufary.h"

#ifndef FALSE
#define FALSE  ((int)0)
#endif
#ifndef TRUE
#define TRUE   (!FALSE)
#endif

#if defined _WIN32
#define PATH_DELIMITER  '\\'
#define PATHTYPE_MSDOS
#else
#define PATH_DELIMITER  '/'
#endif

#define CHAINT_OFFSET   11
#define CHAINT_SCALE    (256-CHAINT_OFFSET)

#define CHA_FILENAME_LEN 1024

#define MIDASI_LEN	129

#define HINSI_NUM	128

#define TYPE_NUM		256
#define FORM_NUM		128

#define JSTR_BOS             "文頭"
#define ESTR_BOS             "BOS"
#define JSTR_EOS             "文末"
#define ESTR_EOS             "EOS"
#define JSTR_BKUGIRI         "/"
#define ESTR_BOS_EOS         "BOS/EOS"

/* cforms.cha */
#define JSTR_BASE_FORM_STR   "基本形"
#define ESTR_BASE_FORM_STR1  "BASEFORM"
#define ESTR_BASE_FORM_STR2  "STEMFORM"
#define JSTR_BASE_FORM       "基本形"
#define ESTR_BASE_FORM1      "BASEFORM"
#define ESTR_BASE_FORM2      "STEMFORM"

/* *.dic */
#define JSTR_DEF_POS_COST  "デフォルト品詞コスト"
#define ESTR_DEF_POS_COST  "DEF_POS_COST"
#define JSTR_MRPH          "形態素"
#define ESTR_MRPH          "MORPH"
#define JSTR_POS           "品詞"
#define ESTR_POS           "POS"
#define JSTR_WORD          "見出し語"
#define ESTR_WORD          "LEX"
#define JSTR_READING       "読み"
#define ESTR_READING       "READING"
#define JSTR_BASE          "原形"
#define ESTR_BASE          "BASE"
#define JSTR_PRON          "発音"
#define ESTR_PRON          "PRON"
#define JSTR_CTYPE         "活用型"
#define ESTR_CTYPE         "CTYPE"
#define JSTR_CFORM         "活用形"
#define ESTR_CFORM         "CFORM"
#define JSTR_INFO1         "付加情報"
#define JSTR_INFO2         "意味情報"
#define ESTR_INFO          "INFO"
#define JSTR_COMPOUND      "複合語"
#define ESTR_COMPOUND      "COMPOUND"
#define JSTR_SEG           "構成語"
#define ESTR_SEG           "SEG"
#define JSTR_CONN_ATTR     "連接属性"

/* chasenrc */
#define JSTR_GRAM_FILE      "文法ファイル"
#define ESTR_GRAM_FILE      "GRAMMAR"
#define JSTR_UNKNOWN_WORD1  "未知語"
#define JSTR_UNKNOWN_WORD2  "未定義語"
#define ESTR_UNKNOWN_WORD   "UNKNOWN"
#define JSTR_UNKNOWN_WORD   JSTR_UNKNOWN_WORD1
#define JSTR_UNKNOWN_POS1   "未知語品詞"
#define JSTR_UNKNOWN_POS2   "未定義語品詞"
#define ESTR_UNKNOWN_POS    "UNKNOWN_POS"
#define JSTR_SPACE_POS      "空白品詞"
#define ESTR_SPACE_POS      "SPACE_POS"
#define JSTR_ANNOTATION     "注釈"
#define ESTR_ANNOTATION     "ANNOTATION"
#define JSTR_POS_COST       "品詞コスト"
#define ESTR_POS_COST       "POS_COST"
#define JSTR_CONN_WEIGHT    "連接コスト重み"
#define ESTR_CONN_WEIGHT    "CONN_WEIGHT"
#define JSTR_MRPH_WEIGHT    "形態素コスト重み"
#define ESTR_MRPH_WEIGHT    "MORPH_WEIGHT"
#define JSTR_COST_WIDTH     "コスト幅"
#define ESTR_COST_WIDTH     "COST_WIDTH"
#define JSTR_DEF_CONN_COST  "未定義連接コスト"
#define ESTR_DEF_CONN_COST  "DEF_CONN_COST"
#define JSTR_COMPOSIT_POS      "連結品詞"
#define ESTR_COMPOSIT_POS      "COMPOSIT_POS"
#define JSTR_OUTPUT_COMPOUND   "複合語出力"
#define ESTR_OUTPUT_COMPOUND   "OUTPUT_COMPOUND"
#define ESTR_PAT_FILE       "PATDIC" /* changed by Tatuo 960920 */
#define ESTR_SUF_FILE       "SUFDIC"
#define JSTR_OUTPUT_FORMAT  "出力フォーマット"
#define ESTR_OUTPUT_FORMAT  "OUTPUT_FORMAT"
#define JSTR_LANG           "言語"
#define ESTR_LANG           "LANG"
#define JSTR_DELIMITER      "区切り文字"
#define ESTR_DELIMITER      "DELIMITER"
#define JSTR_BOS_STR        "BOS文字列"
#define ESTR_BOS_STR        "BOS_STRING"
#define JSTR_EOS_STR        "EOS文字列"
#define ESTR_EOS_STR        "EOS_STRING"

#define VCHA_CONNECT_FILE "connect.cha"
#define VCHA_CONNTMP_FILE "_connect.cha"
#define VCHA_GRAMMAR_FILE "grammar.cha"
#define VCHA_CFORM_FILE   "cforms.cha"
#define VCHA_CTYPE_FILE   "ctypes.cha"
#define VCHA_TABLE_FILE   "table.cha"
#define VCHA_MATRIX_FILE  "matrix.cha"
#define CHA_CONNECT_FILE  "chasen.connect.c"
#define CHA_CONNTMP_FILE  "chasen.connect"
#define CHA_GRAMMAR_FILE  "chasen.grammar"
#define CHA_CFORM_FILE    "chasen.cforms"
#define CHA_CTYPE_FILE    "chasen.ctypes"
#define CHA_TABLE_FILE    "chasen.table"
#define CHA_MATRIX_FILE   "chasen.matrix"
#define CONNECT_FILE	  VCHA_CONNECT_FILE
#define CONNTMP_FILE	  VCHA_CONNTMP_FILE
#define GRAMMAR_FILE	  VCHA_GRAMMAR_FILE
#define CFORM_FILE	  VCHA_CFORM_FILE
#define CTYPE_FILE	  VCHA_CTYPE_FILE
#define TABLE_FILE	  VCHA_TABLE_FILE
#define MATRIX_FILE	  VCHA_MATRIX_FILE

#define CONS		0
#define ATOM		1
#define NIL		((chasen_cell_t *)(NULL))

#define s_tag(cell)	(((chasen_cell_t *)(cell))->tag)
#define consp(x)	(!nullp(x) && (s_tag(x) == CONS))
#define atomp(x)	(!nullp(x) && (s_tag(x) == ATOM))
#define nullp(cell)	((cell) == NIL)
#define car_val(cell)	(((chasen_cell_t *)(cell))->value.cha_cons.cha_car)
#define cdr_val(cell)	(((chasen_cell_t *)(cell))->value.cha_cons.cha_cdr)
#define s_atom_val(cell) (((chasen_cell_t *)(cell))->value.atom)

/* added by T.Utsuro for weight of rensetu matrix */
#define DEFAULT_C_WEIGHT  10

/* added by S.Kurohashi for mrph weight default values */
#define MRPH_DEFAULT_WEIGHT	1

#define strmatch2(s,s1,s2)      (!strcmp(s,s1)||!strcmp(s,s2))
#define strmatch3(s,s1,s2,s3)   (!strcmp(s,s1)||!strcmp(s,s2)||!strcmp(s,s3))

/*
 * structures
 */

/* rensetu matrix */
typedef struct _connect_rule_t {
    unsigned short next;
    unsigned short cost;
} connect_rule_t;

/* <cha_car> 部と <cha_cdr> 部へのポインタで表現されたセル */
typedef struct _bin_t {
    void *cha_car;			/* address of <cha_car> */
    void *cha_cdr;			/* address of <cha_cdr> */
} bin_t;

/* <BIN> または 文字列 を表現する完全な構造 */
typedef struct _cell {
    int tag;			/* tag of <cell> 0:cha_cons 1:atom */
    union {
	bin_t	cha_cons;
	char	*atom;
    } value;
} chasen_cell_t;

/* this structure is used only in mkchadic */
/* morpheme */
typedef struct _mrph {
    char midasi[MIDASI_LEN];  /* surface form */
    char yomi[MIDASI_LEN];    /* Japanese reading */
    char *info;               /* semantic information */
    char *base;               /* base form */
    char pron[MIDASI_LEN];    /* Japanese pronunciation */
    unsigned short hinsi;     /* POS number */
    unsigned char ktype;      /* Conjugation type number */
    unsigned char kform;      /* Conjugation form number */

    short con_tbl;            /* connection table number */
    short length;             /* the length of surface form */
    unsigned short weight;    /* cost for morpheme  */

    char is_undef;            /* the unseen word or not */
} mrph_t;

/* POS information -- see also the comments (the end of this file) */
typedef struct _hinsi_t {
    short *path;         /* the path to top node */
    short *daughter;     /* the daughter node */
    char  *name;         /* the name of POS (at the level) */
    char  *bkugiri;      /* for bunsetsu segmentation */
    short composit;      /* for the COMPOSIT_POS */ 
    char  depth;         /* the depth from top node */
    char  kt;            /* have conjugation or not */
    unsigned char cost;
} hinsi_t;

/* 活用型 conjugation type */
typedef struct _ktype {
    char   *name;    /* CTYPE name */
    short  basic;    /* base form */
} ktype_t;

/* 活用形 conjugation form */
typedef struct _kform {
    char  *name;     /* CFORM name */
    char  *gobi;     /* suffix of surface form */
    int   gobi_len;  /* the length of suffix */
    char  *ygobi;    /* suffix of Japanese reading */
    char  *pgobi;    /* suffix of Japanese pronunciation */
} kform_t;

/* 連接表 connection matrix */
typedef struct _rensetu_pair {
    short  index;
    short  i_pos;  /* the POS index in the current state (= preceding morpheme) */  
    short  j_pos;  /* the POS index in the input (= current morpheme) */

    unsigned short hinsi;   /* POS */
    unsigned char type;     /* CTYPE */
    unsigned char form;     /* CFORM */
    char   *goi;   /* Lexicalized POS */
} rensetu_pair_t;

/*
 * global variables
 */

#define HINSI_MAX     4096
extern hinsi_t Cha_hinsi[HINSI_MAX];  /* see also the comments (the end of this file) */
extern ktype_t Cha_type[TYPE_NUM];
extern kform_t Cha_form[TYPE_NUM][FORM_NUM];
extern int Cha_lineno, Cha_lineno_error;

/* getopt.c */
extern int Cha_optind;
extern char *Cha_optarg;

extern int Cha_server_mode;
extern int Cha_errno;
extern FILE *Cha_stderr;

/* dictionaries(dic.c) */
extern SUFARY *Suf_dicfile[];
extern pat_t *Pat_dicfile[];
extern int Suf_ndicfile;
extern int Pat_ndicfile;

/*
 * functions
 */

/* iotool.c */
char *cha_convert_escape(char*, int);
void cha_set_progpath(char*);
void cha_set_rcpath(char*);
char *cha_get_rcpath(void);
char *cha_get_grammar_dir(void);
void cha_set_filepath(char*);
FILE *cha_fopen(char*, char*, int);
FILE *cha_fopen2(char*, char*, char*, int);
FILE *cha_fopen_grammar(char*, char*, int, int, char**);
FILE *cha_fopen_grammar2(char*, char*, char*, int, int, char**);
void *cha_malloc(size_t);
void *cha_realloc(void*, size_t);
#define cha_free(ptr) (free(ptr))
char *cha_strdup(char*);

void cha_exit(int, char*, ...);
void cha_exit_file(int, char*, ...);
void cha_perror(char*);
void cha_exit_perror(char*);
FILE *cha_fopen_rcfile(void);
void cha_read_grammar_dir(void);

/* lisp.c */
void cha_set_getc_alone(void);
void cha_set_getc_server(void);
void cha_set_skip_char(int);
int cha_s_feof(FILE*);
void cha_s_free(chasen_cell_t*);
chasen_cell_t *cha_tmp_atom(char*);
chasen_cell_t *cha_cons(void*, void*);
chasen_cell_t *cha_car(chasen_cell_t*);
chasen_cell_t *cha_cdr(chasen_cell_t*);
char *cha_s_atom(chasen_cell_t*);
int cha_equal(void*, void*);
int cha_s_length(chasen_cell_t*);
chasen_cell_t *cha_s_read(FILE*);
chasen_cell_t *cha_assoc(chasen_cell_t*, chasen_cell_t*);
char *cha_s_tostr(chasen_cell_t*);
chasen_cell_t *cha_s_print(FILE*, chasen_cell_t*);

/* grammar.c */
void cha_read_class(FILE*);
int cha_match_nhinsi(chasen_cell_t*, int);
void cha_read_grammar(FILE*, int, int);

/* katuyou.c */
void cha_read_katuyou(FILE*, int);

/* connect.c */
void cha_read_table(FILE*, int);
int cha_check_table(mrph_t*); /* 970301 tatuo: void -> int for 頑健化 */
int cha_check_table_for_undef(int);
void cha_read_matrix(FILE*);
int cha_check_automaton(int, int, int, int*);
/* for EDR dic */
void cha_check_edrtable(mrph_t *, chasen_cell_t*);
void cha_check_edrtable_str(mrph_t*, char*); /* Unused.  */

/* getid.c */
int cha_get_nhinsi_str_id(char**);
int cha_get_nhinsi_id(chasen_cell_t*);
int cha_get_type_id(char*);
int cha_get_form_id(char*, int);

/* zentohan.c */
unsigned char *euc2sjis(char*);
unsigned char *sjis2euc(unsigned char*);
unsigned char *hankana2zenkana(unsigned char*);

/* getopt.c */
int cha_getopt(char**, char*, FILE*);
int cha_getopt_chasen(char**, FILE*);

/* mmap.c */
off_t cha_mmap_file(char*, void**);
off_t cha_mmap_file_w(char*, void**);
void cha_munmap_file(void*, off_t);

#endif /* __CHADIC_H__ */


/*
  the data format of the structure hinsi_t
  the POS informations are treated in global valuable Cha_hinsi[n]

=============                          ===================
"grammar.cha"                          "real POS tag list"
=============                          ===================
(A1                   ; Cha_hinsi[1]
    (B1)              ; Cha_hinsi[2]   A1-B1                 ; Cha_hinsi[2]
    (B2               ; Cha_hinsi[3]
	(C1)          ; Cha_hinsi[4]   A1-B2-C1              ; Cha_hinsi[4]
	(C2           ; Cha_hinsi[5]
	    (D1)      ; Cha_hinsi[6]   A1-B2-C2-D1           ; Cha_hinsi[6]
	    (D2)      ; Cha_hinsi[7]   A1-B2-C2-D2           ; Cha_hinsi[7]
	    (D3))     ; Cha_hinsi[8]   A1-B2-C2-D3           ; Cha_hinsi[8]
	(C3)          ; Cha_hinsi[9]   A1-B2-C3              ; Cha_hinsi[9]
	(C4           ; Cha_hinsi[10]
	    (D4)      ; Cha_hinsi[11]  A1-B2-C4-D4           ; Cha_hinsi[11]
	    (D5))))   ; Cha_hinsi[12]  A1-B2-C4-D5           ; Cha_hinsi[12]

=========================================
*hinsi_t Cha_hinsi[HINSI] for the example
=========================================
n (idx)                =  1  2  3  4  5  6  7  8  9  10 11 12
Cha_hinsi[n].name      =  A1 B1 B2 C1 C2 D1 D2 D3 C3 C4 D4 D5
Cha_hinsi[n].depth     =  1  2  2  3  3  4  4  4  3  3  4  4
*Cha_hinsi[n].daughter =  2  0  4  0  6  0  0  0  0  11 0  0
*Cha_hinsi[n].path     =  1  1  1  1  1  1  1  1  1  1  1  1

*/
