/*
 * makeint.c ユーザ辞書を maketree 可読形式（バイナリファイル）に変換する
 * 1990/11/09/Fri Yutaka MYOKI(Nagao Lab., KUEE) 1991/01/08/Tue Ver 1.00
 *
 * $Id$
 */

#include "chadic.h"
#include <time.h>

/*
 * trans.c 
 */
extern void trans(FILE *, FILE *);

/*
 * usage()
 */
static void
usage(void)
{
    fprintf(stderr, "usage: makeint [ -q ] [ -o outfile ] dicfile...\n");
    exit(1);
}

/*
 * translate()
 */
static void
translate(char *dicfile, FILE * fp_out, FILE * fp_w)
{
    FILE *fp_in;

    fp_in = cha_fopen(dicfile, "r", 1);
    if (fp_out)
	fprintf(stderr, "%s\n", dicfile);
    trans(fp_in, fp_w);
    fclose(fp_in);
}

/*
 * mainproc()
 */
static void
mainproc(char *argv[], FILE * fp_out, FILE * fp_w)
{
    time_t t0, t1;
#if defined _WIN32 && ! defined __CYGWIN__ && ! defined __MINGW32__
    struct _finddata_t file;
    long hFile;
#endif

    time(&t0);

    if (fp_out)
	fprintf(stderr, "parsing dictionaries...\n");

    for (; *argv != NULL; argv++) {
#if defined _WIN32 && ! defined __CYGWIN__ && ! defined __MINGW32__
	hFile = _findfirst(*argv, &file);
	do {
	    translate(file.name, fp_out, fp_w);
	} while (!_findnext(hFile, &file));
	_findclose(hFile);
#else
	translate(*argv, fp_out, fp_w);
#endif
    }

    time(&t1);

    if (fp_out)
	fprintf(stderr, "processing time: %d sec\n", (int) (t1 - t0));
}

/*
 * main()
 */
int
main(int argc, char *argv[])
{
    FILE *fp_out, *fp_w;
    int c;

    cha_set_progpath(argv[0]);

    fp_out = stderr;
    fp_w = stdout;

    while ((c = cha_getopt(argv, "qo:", stderr)) != EOF) {
	switch (c) {
	case 'q':
	    fp_out = NULL;
	    break;
	case 'o':
	    fp_w = cha_fopen(Cha_optarg, "wb", 1);
	    break;
	case '?':
	    usage();
	}
    }
    argv += Cha_optind;

    if (argv[0] == NULL)
	usage();

    cha_read_grammar(fp_out, 1, 2);
    cha_read_katuyou(fp_out, 2);
    cha_read_table(fp_out, 2);
    mainproc(argv, fp_out, fp_w);

    return 0;
}
