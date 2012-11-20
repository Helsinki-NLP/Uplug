/*
 * suffix array 作成プログラム
 * 
 * このプログラムの原型は、 NLPRS '95 Invited Lecture Kenneth W. Church
 * のものを使用しました。 
 *
 * $Id$
 */

#include "config.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#include "chadic.h"
#include "htobe.h"

#define FNLEN 1000		/* ファイル名の長さ */

#define DELIM '\n'

FILE* open_array_file(char*);
size_t open_text_file(char*);
void sort_array_file(char*, long);
long dump_index_to_file(FILE*, off_t);
void dump_file(char*, long*, long);
void usage(void);
void message(char*, ...);

/*
 * global variables
 */
char *text;			/* 処理対象となるテキスト */
char *progname;			/* program name */

int
suffix_compare(long *a, long *b)
{
    long ha, hb;

    ha = betoh(*a);
    hb = betoh(*b);
    return strcmp(text + ha, text + hb);
}

int
main(int argc, char *argv[])
{
    char in_fname[FNLEN];	/* 入力ファイル名 */
    char ary_fname[FNLEN];	/* 出力先ファイル名 */
    FILE *ofd;
    off_t text_size;
    long index_num = 0;

    in_fname[0] = '\0';
    ary_fname[0] = '\0';

    progname = argv[0];		/* プログラム名 */

  /*
   * オプション処理
   */
    if (argc <= 1) {
	usage();
	exit(1);
    }
    while (argc > 1) {
	if (argv[1][0] == '-')
	    switch (argv[1][1]) {
	    case 'o':		/* 出力ファイル名の指定 */
		if (argc == 2) {
		    fprintf(stderr,
			    "-o <filename> --- 出力ファイル名を指定\n");
		    exit(1);
		}
		strcpy(ary_fname, argv[2]);
		argc--;
		argv++;
		break;
	    case 'l':	/* obsolete */
		break;
	    default:	/* エラー */
		fprintf(stderr, "%c: 無効なオプションです。\n",
			argv[1][1]);
		usage();
		exit(1);
	} else {
	    strcpy(in_fname, argv[1]);	/* テキストファイル名 */
	}
	argc--;
	argv++;
    }


    /* Open the text file */
    text_size = cha_mmap_file(in_fname, (void **) &text);

    if (ary_fname[0] == '\0')
	sprintf(ary_fname, "%s.ary", in_fname);
    ofd = open_array_file(ary_fname);

    message("Reading text file \"%s\"\n", in_fname);
    index_num = dump_index_to_file(ofd, text_size);

    fclose(ofd);


    sort_array_file(ary_fname, index_num);

    message("Done.\n");

    return 0;
}

FILE *
open_array_file(char *fname)
{
    FILE *ofd;

    if ((ofd = fopen(fname, "wb")) == NULL) {
	cha_exit_perror(fname);
    }
    message("Save to \"%s\"\n", fname);

    return ofd;
}

long
dump_index_to_file(FILE *ofd, off_t text_size)
{
    long i, jj = 0, index;
    int last_char_is_delimitter = 1;

    for (i = 0; i < text_size; i++) {
	if (text[i] == DELIM) {
	    last_char_is_delimitter = 1;
	} else {
	    if (last_char_is_delimitter == 1) {
		/* 前の文字が区切り文字ならば */
		index = htobe(i);
		fwrite(&index, 1, sizeof(long), ofd);
		jj++;
		last_char_is_delimitter = 0;
	    }
	}
	if (i == 0)
	    continue;
	if (!(i % 500000))
	    message(".");
	if (!(i % 10000000))
	    message(" %ldM\n", i / (1024 * 1024));
    }
    message(" %ldM\n", i / (1024 * 1024));

    return jj;
}

void
dump_file(char *ary_fname, long *buf, long num)
{
    FILE *out = open_array_file(ary_fname);

    if (fwrite(buf, sizeof(long), num, out) < num)
	cha_exit_perror(ary_fname);
}

void
sort_array_file(char *ary_fname, long pointer_cnt)
{
    void *suf;

    cha_mmap_file_w(ary_fname, &suf);

    message("Sorting...\n");
    qsort(suf, (size_t) pointer_cnt, sizeof(long),
	  (int (*)()) suffix_compare);

    message("Saving...\n");

#ifndef HAVE_MMAP
    dump_file(ary_fname, suf, pointer_cnt);
#endif
}

/*
 * usage --- 使い方 
 */
void
usage(void)
{
    static char *messages[] = {
	"\n",
	"Version 1.4 980602 (SUFARY Version 2.0)\n\n",
	"USAGE   mkary [ -l ] [ -o filename ] filename\n",
	"OPTION\n",
	"  -o <filename> : 出力ファイルを指定 ( default は stdout )\n",
	"  -l            : 行でソート ( \"\\n\" で区切る )\n",
	NULL
    };
    char **mes;

    for (mes = messages; *mes; mes++)
	fputs(*mes, stderr);
}

void
message(char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
}
