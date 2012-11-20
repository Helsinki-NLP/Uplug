/*
 * $Id$
 */

#ifndef __CHALIB_H__
#define __CHALIB_H__

#include "chadic.h"
#include "chasen.h"

#if defined _WIN32 && ! defined __CYGWIN__
#define	strcasecmp	stricmp
#define	strncasecmp	strnicmp
#endif /* _WIN32 */

#define CHA_PATH_NUM            1024
#define CHA_INPUT_SIZE      8192
#define UNDEF_HINSI_MAX     256
#define PAT_DIC_NUM 5 /* 同時に使える辞書の数の上限 (ChaSen) */

/*
 * structures
 */

typedef struct _mrph2_t {
    char *midasi;     /* Surface form */
    char *yomi;       /* Japanese reading */
    char *info;       /* semantic information */         
    char *base;       /* base form */
    char *pron;       /* Japanese pronunciation */
    char *compound;   /* compound words information */
    short base_length; /* the length of stem */

    unsigned short hinsi; /* POS number */
    unsigned char ktype;  /* Conjugation type number */
    unsigned char kform;  /* Conjugation form number */
    char  is_undef;       /* the unseen word or not */

    unsigned short weight; /* cost of morpheme */
    short  length;         /* the length of surface form */
    short  con_tbl;        /* connection table number */
} mrph2_t;

typedef struct _path_t {
    int   mrph_p;
    short state;
    short start;
    short end;
    short do_print;
    int   cost;
    int   *path;
} path_t;

/* information for annotation */
typedef struct _anno_info {
    int  hinsi;
    char *str1, *str2;
    int  len1, len2;
    char *format;
} anno_info;

/* information for unseen word */
typedef struct _undef_info {
    int  cost, cost_step;
    int  con_tbl;
    int  hinsi;
} undef_info;

/*
 * global variables
 */
extern mrph2_t *Cha_mrph;
extern path_t *Cha_path;
extern int Cha_path_num;
extern int Cha_con_cost_weight, Cha_con_cost_undef;
extern int Cha_mrph_cost_weight, Cha_cost_width;
extern int Space_pos_hinsi;
extern anno_info Cha_anno_info[UNDEF_HINSI_MAX];
extern undef_info Cha_undef_info[UNDEF_HINSI_MAX];
extern int Cha_undef_info_num;
extern char *Cha_bos_string;
extern char *Cha_eos_string;
extern int Cha_output_iscompound;

/*
 * functions
 */

/* init.c */
void cha_read_rcfile_fp(FILE*);
void cha_init(void);

/* print.c */
char *cha_get_output(void);
void cha_set_fput(int);
void cha_set_output(FILE*);
void cha_print_reset(void);
void cha_printf_mrph(int, mrph2_t*, char*);
void cha_print_path(int, int, char*);
void cha_print_bos_eos(int);
void cha_print_hinsi_table(void);
void cha_print_ctype_table(void);
void cha_print_cform_table(void);

/* parse.c */
void cha_get_mrph_data(mrph2_t*, char*, char*);
int cha_parse_sentence(char*, int, int);

/* chalib.c */
void cha_version(FILE*);
void cha_set_opt_form(char*);
void cha_set_cost_width(int);
void cha_set_language(char*);
char *cha_fgets(char*, int, FILE*);
void cha_read_patdic(chasen_cell_t*);
void cha_read_sufdic(chasen_cell_t*);

/* cha_jfgets.c */
void cha_set_jfgets_delimiter(char*);
char *cha_fget_line(char*, int, FILE*);
char *cha_jfgets(char*, int, FILE*);
int cha_jistoeuc(unsigned char*, unsigned char*);

#endif /* __CHALIB_H__ */
