/*
 * Copyright (C) 1996, 2000, 2001,
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
 * modified by A.Kitauchi <akira-k@is.aist-nara.ac.jp>, Sep. 1996
 * $Id$
 */

#include "chalib.h"
#include "pat.h"
#include "sufary.h"
#include "tokenizer.h"

#define CHA_NAME       "ChaSen"

int Cha_cost_width = -1;
enum cha_lang Cha_lang = CHASEN_LANG_JA;
enum cha_encode Cha_encode = CHASEN_ENCODE_EUCJP;

static int cost_width0;

static char patdic_filename[PAT_DIC_NUM][CHA_FILENAME_LEN];
static char sufdic_filename[PAT_DIC_NUM][CHA_FILENAME_LEN];

static int obj_dic_no = 0;	/* 動的処理(追加)の対象となる辞書の番号 */

static int opt_show = 'b', opt_form = 'f', opt_ja, opt_cmd, opt_nobk;
static char *opt_form_string;

/*
 *  cha_version()
 */
void
cha_version(FILE * fp)
{
    if (!fp)
	return;

    fprintf(fp,
	    "%s version %s (c) 1996-2001 Nara Institute of Science and Technology\n",
	    CHA_NAME, VERSION);
    fprintf(fp, "Grammar files are in ChaSen's new v-gram format.\n");
}

/*
 * cha_set_opt_form()
 */
void
cha_set_opt_form(char *format)
{
    char *f;

    /*
     * -[fecdv] 
     */
    if (format &&
	format[0] == '-' && strchr("fecdv", format[1])
	&& format[2] == '\0') {
	opt_form = format[1];
	format = NULL;
    }

    if (format == NULL) {
	if (opt_form == 'd' || opt_form == 'v')
	    opt_show = 'm';
	switch (opt_form) {
	case 'd':
	    opt_form_string =
		"morph(%pi,%ps,%pe,%pc,'%m','%U(%y)','%M',%U(%P'),NIL,%T0,%F0,'%I0',%c,[%ppc,],[%ppi,])";
	    break;
	case 'v':
	    opt_form_string =
		"%pb%3pi %3ps %3pe %5pc %m\t%U(%y)\t%U(%a)\t%M\t%U(%P-) NIL %T0 %F0 %I0 %c %ppi, %ppc,\n";
	    break;
	case 'f':
	    opt_form_string = "%m\t%y\t%M\t%U(%P-)\t%T \t%F \n";
	    break;
	case 'e':
	    opt_form_string = "%m\t%U(%y)\t%M\t%P- %h %T* %t %F* %f\n";
	    break;
	case 'c':
	    opt_form_string = "%m\t%y\t%M\t%h %t %f\n";
	    break;
	}
	return;
    }

    /*
     * format string 
     */
    opt_form_string = format;
    /*
     * opt_form_string = cha_convert_escape(cha_strdup(format), 1); 
     */

    f = opt_form_string + strlen(opt_form_string);
    if (f[-1] == '\n')
	opt_form = 'F';
    else
	opt_form = 'W';
}

/*
 * cha_set_language()
 */
void
cha_set_language(char *langstr)
{
    Cha_lang = CHASEN_LANG_JA;

    if (langstr[0] == 'j') {
	Cha_lang = CHASEN_LANG_JA;
    } else if (langstr[0] == 'e') {
	Cha_lang = CHASEN_LANG_EN;
    }
}

/*
 * cha_set_cost_width()
 */
void
cha_set_cost_width(int cw)
{
    cost_width0 = cw * MRPH_DEFAULT_WEIGHT;

    /*
     * 最適解以外も表示するときは Cha_cost_width を生かす 
     */
    Cha_cost_width = opt_show == 'b' ? -1 : cost_width0;
}

/*
 * chasen_getopt_argv - initialize and read options
 *
 * return value:
 *   0 - ok
 *   1 - error
 */
int
chasen_getopt_argv(char **argv, FILE * fp)
{
    int c;

    /*
     * read -r option 
     */
    Cha_optind = 0;
    while ((c = cha_getopt_chasen(argv, fp)) != EOF) {
	switch (c) {
	case 'r':
	    /*
	     * chasenrc file 
	     */
	    cha_set_rcpath(Cha_optarg);
	    break;
	case '?':
	    return 1;
	}
    }

    /*
     * initialize if not done 
     */
    if (!Cha_undef_info_num)
	cha_init();

    /*
     * read options 
     */
    Cha_optind = 0;
    while ((c = cha_getopt_chasen(argv, fp)) != EOF) {
	switch (c) {
	case 'b':
	case 'm':
	case 'p':
	    opt_show = c;
	    break;
	case 'd':
	case 'v':
	case 'f':
	case 'e':
	case 'c':
	    opt_form = c;
	    cha_set_opt_form(NULL);
	    break;
	case 'F':
	    cha_set_opt_form(cha_convert_escape
			     (cha_strdup(Cha_optarg), 0));
	    break;
	case 'L':
	    cha_set_language(Cha_optarg);
	    break;
	case 'w':		/* コスト幅の指定 */
	    cha_set_cost_width(atoi(Cha_optarg));
	    break;
	case 'O':
	    Cha_output_iscompound = *Cha_optarg == 'c';
	    break;
	case 'l':
	    cha_set_output(stdout);
	    switch (*Cha_optarg) {
	    case 'p':
		/*
		 * display the list of Cha_hinsi table 
		 */
		cha_print_hinsi_table();
		exit(0);
		break;
	    case 't':
		cha_print_ctype_table();
		exit(0);
		break;
	    case 'f':
		cha_print_cform_table();
		exit(0);
		break;
	    default:
		break;
	    }
	    break;
	case 'j':
	    opt_ja = 1;
	    break;
	case 'B':
	    opt_nobk = 1;
	    break;
	case 'C':
	    opt_cmd = 1;
	    break;
#if 0				/* not necessary */
	case '?':
	    return 1;
#endif
	}
    }

    /*
     * 最適解以外も表示するときは Cha_cost_width を生かす 
     */
    Cha_cost_width = opt_show == 'b' ? -1 : cost_width0;

    return 0;
}

/*
 * command_usage()
 */
static void
command_usage(void)
{
    static char *message[] = {
	"commands are:\n",
	"#V        print ChaSen version\n",
	"#F format show morpheme with formatted output\n",
	"#w num    change the cost width  ex. #w 500\n",
	"#i        various information\n",
	"#e word   check if the word exists in the dictionary  ex. #e 茶筌\n",
	"#a        resister the word into the dictionary\n",
	"#f        designate the dictionary which a word resistered\n",
	"#s        save the patricia tree after resistering the words\n",
	"#h        show this help\n",
	"#q        quit\n",
	NULL
    };
    char **mes;

    for (mes = message; *mes; mes++)
	fputs(*mes, stdout);
}

/*
 * chomp a string
 */
static void
chomp(char *str)
{
    int len;

    len = strlen(str);
    if (str[len - 1] == '\n')
	str[--len] = '\0';
    if (str[len - 1] == '\r')
	str[--len] = '\0';
}

/*
 * chasen_command()
 *
 * return value:
 *     0 - succeed
 *     1 - quit chasen
 */
static int
chasen_command(char *comm)
{
    char *arg;
    int i;
    char *rslt[256]; /* 辞書引き結果変数 for 単語チェック(exact match) */
    FILE *of;	     /* intファイルに書き込む(追加)ためのもの */
    long new_word_index = 0;
    char tmpstr[2000];

    arg = comm + 2;
    chomp(arg);

    switch (comm[0]) {		/* command */
    case 'V':
	cha_version(stdout);
	break;
    case 'F':
	cha_set_opt_form(cha_convert_escape(cha_strdup(arg), 0));
	break;
    case 'L':
	cha_set_language(Cha_optarg);
	break;
    case 'w':
	/*
	 * cost width 
	 */
	cha_set_cost_width(atoi(arg));
	break;
    case 'i':
	/*
	 * information 
	 */
	cha_version(stdout);
	printf("\ncost width:           %d\n", Cha_cost_width);
	printf("weight of conn. cost: %d\n", Cha_con_cost_weight);
	printf("weight of morph cost: %d\n", Cha_mrph_cost_weight);
	printf("output format:        \"%s\"\n",
	       opt_form_string ? opt_form_string : "(none)");
	printf("chasenrc file:        %s\n", cha_get_rcpath());
	printf("grammar file:         %s\n", cha_get_grammar_dir());
	printf("dic file:\n");
	for (i = 0; patdic_filename[i][0]; i++)
	    printf("\t%s\n", patdic_filename[i]);
	printf("dic file for processing:\n\t%s\n",
	       patdic_filename[obj_dic_no]);
	break;
    case 'f':
	/*
	 * 処理対象となる辞書の変更 file name -> dic No. 
	 */
	for (i = 0; patdic_filename[i][0]; i++) {
	    printf("\t%s\n", patdic_filename[i]);
	    if (strcmp(patdic_filename[i], arg) == 0) {
		obj_dic_no = i;	/* 動的処理(追加)の対象となる辞書の番号 */
		printf("dic number = %d\n", obj_dic_no);
		/*
		 * 書き込み禁止ならばエラーにしたい 
		 */
		break;
	    }
	}
	break;
    case 'a':
	/*
	 * パト木への単語の追加・挿入
	 */
	if (strlen(arg) < 4) {
	    printf("invalid format\n");
	    break;
	}
	/*
	 * 追加する単語をintファイルに追加 
	 */
	sprintf(tmpstr, "%s.int", patdic_filename[obj_dic_no]);
	of = cha_fopen(tmpstr, "ab", 1);
	fputs(arg, of);
	fputc(0, of);
	printf("add [%s] at %ld\n", arg, new_word_index);
	fclose(of);
	/*
	 * マップをやり直してもらうための処理 
	 */
	pat_text_reopen(Pat_dicfile[obj_dic_no], tmpstr);
	pat_insert(Pat_dicfile[obj_dic_no], arg, new_word_index);
	break;
    case 's':
	/*
	 * 木のセーブ 
	 */
	sprintf(tmpstr, "%s.pat", patdic_filename[obj_dic_no]);
	pat_save(Pat_dicfile[obj_dic_no], tmpstr);
	break;
    case 'e':
	/*
	 * キーの検索 (exact match) 
	 */
	for (i = 0; patdic_filename[i][0]; i++) {
	    mrph2_t mrph;
	    printf("DIC No. %d   \"%s\"\n", i, patdic_filename[i]);
	    pat_search_exact(Pat_dicfile[i], arg, rslt);
	    if (!rslt[0])
		printf("Not Found.\n");
	    else {
		char **pbuf;
		for (pbuf = rslt; *pbuf; pbuf++) {
		    cha_get_mrph_data(&mrph, *pbuf, arg);
		    if (Cha_hinsi[mrph.hinsi].kt && mrph.kform) {
			mrph.base_length = 0;
			mrph.yomi = "";
		    }
		    cha_printf_mrph(0, &mrph, opt_form_string);
		}
	    }
	}
	break;
    case 'q':			/* quit */
	return 1;
    case 'h':
	command_usage();
	break;
    default:
	printf("invalid command: %s\n", comm);
    }

    fputs("ok\n", stdout);
    fflush(stdout);

    return 0;
}

/*
 * parse a string and output to fp or str
 *
 * return value:
 *     0 - ok / no result / too many morphs
 *     1 - quit
 */
static int
chasen_sparse_main(char *input, FILE * output)
{
    char *crlf;

    /*
     * initialize if not done 
     */
    if (!Cha_undef_info_num)
	cha_init();
    if (!opt_form_string)
	cha_set_opt_form(NULL);

    cha_set_output(output);

    if (input[0] == '\0') {
	cha_print_bos_eos(opt_form);
	return 0;
    }

    /*
     * コマンド・インタプリタ 
     */
    if (opt_cmd && *input == '#')
	return chasen_command(input + 1);

    /*
     * conversion of ISO-2022-JP string to EUC-JP 
     */
    /*
     * jis_to_euc(input);
     */

    /*
     * parse a sentence and print 
     */
    while (*input) {
	int c = 0, len;
	if ((crlf = strpbrk(input, "\r\n")) == NULL)
	    len = strlen(input);
	else {
	    len = crlf - input;
	    c = *crlf;
	    *crlf = '\0';
	}
#ifdef SJIS
	sjis2euc(input);
#endif
	cha_print_reset();
	if (len > 0 && !cha_parse_sentence(input, len, opt_nobk)) {
	    cha_print_path(opt_show, opt_form, opt_form_string);
	} else if (!opt_ja)
	    cha_print_bos_eos(opt_form);

	if (crlf == NULL)
	    break;
	if (c == '\r' && crlf[1] == '\n')
	    input = crlf + 2;
	else
	    input = crlf + 1;
    }


    return 0;
}

/*
 * read from file/str, parse, and write to file
 * 
 * return value:
 *     0 - ok / no result / too many morphs
 *     1 - quit / eof
 */
/*
 * file -> file
 */
int
chasen_fparse(FILE * fp_in, FILE * fp_out)
{
    char line[CHA_INPUT_SIZE];

    if (cha_fgets(line, sizeof(line), fp_in) == NULL)
	return 1;

    return chasen_sparse_main(line, fp_out);
}
/*
 * string -> file
 */
int
chasen_sparse(char *str_in, FILE * fp_out)
{
    int rc;
    char *euc_str;

    euc_str = cha_malloc(strlen(str_in) + 1);
    cha_jistoeuc(str_in, euc_str);
    rc = chasen_sparse_main(euc_str, fp_out);
    free(euc_str);

    return rc;
}

/*
 * read from file/str, parse, and output to string
 * 
 * return value: string
 *     !NULL - ok / no result / too many morphs
 *     NULL - quit / eof
 */

/*
 * file -> string
 */
char *
chasen_fparse_tostr(FILE * fp_in)
{
    char line[CHA_INPUT_SIZE];

    if (cha_fgets(line, sizeof(line), fp_in) == NULL)
	return NULL;

    if (chasen_sparse_main(line, NULL))
	return NULL;

    return cha_get_output();
}

/*
 * string -> string
 */
char *
chasen_sparse_tostr(char *str_in)
{
    char *euc_str;

    euc_str = cha_malloc(strlen(str_in) + 1);
    cha_jistoeuc(str_in, euc_str);

    if (chasen_sparse_main(euc_str, NULL))
	return NULL;

    free(euc_str);

    return cha_get_output();
}

char *
cha_fgets(char *s, int n, FILE * fp)
{
    if (opt_ja)
	return cha_jfgets(s, n, fp);
    else
	return cha_fget_line(s, n, fp);
}

static void
set_dic_filename(char *filename, char *s)
{
#ifdef PATHTYPE_MSDOS
    if (*s == PATH_DELIMITER || *s && s[1] == ':')
	strcpy(filename, s);
#else
    if (*s == PATH_DELIMITER)
	strcpy(filename, s);
#endif /* PATHTYPE_MSDOS */
    else
	sprintf(filename, "%s%s", cha_get_grammar_dir(), s);
}

/*
 * cha_read_patdic - read patricia dictionaries
 */
void
cha_read_patdic(chasen_cell_t * cell)
{
    int num;
    char patname[CHA_FILENAME_LEN];
    char textname[CHA_FILENAME_LEN];

    /*
     * return if already read 
     */
    if (patdic_filename[0][0])
	return;

    for (num = 0; !nullp(cell); num++, cell = cha_cdr(cell)) {
	if (num >= PAT_DIC_NUM)
	    cha_exit_file(1, "too many patricia dictionary files");
	set_dic_filename(patdic_filename[num], cha_s_atom(cha_car(cell)));

	/*
	 * open patdic 
	 */
	sprintf(textname, "%s.int", patdic_filename[num]);
	sprintf(patname, "%s.pat", patdic_filename[num]);
	Pat_dicfile[num] = pat_open(textname, patname);
    }
    Pat_ndicfile = num;
}

/*
 * cha_read_sufdic - read SUFARY dictionaries
 */
void
cha_read_sufdic(chasen_cell_t * cell)
{
    int num;
    char filename[CHA_FILENAME_LEN];
    char ary_filename[CHA_FILENAME_LEN];

    /*
     * return if already read 
     */
    if (sufdic_filename[0][0])
	return;

    for (num = 0; !nullp(cell); num++, cell = cha_cdr(cell)) {
	if (num >= PAT_DIC_NUM)
	    cha_exit_file(1, "too many SUFARY dictionary files");
	set_dic_filename(sufdic_filename[num], cha_s_atom(cha_car(cell)));

	/*
	 * open sufdic 
	 */
	sprintf(filename, "%s.int", sufdic_filename[num]);
	sprintf(ary_filename, "%s.ary", sufdic_filename[num]);
	Suf_dicfile[num] = sa_openfiles(filename, ary_filename);
    }
    Suf_ndicfile = num;
}
