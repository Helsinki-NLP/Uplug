/*
 * make patricia tree for ChaSen
 *
 * $Id$
 */

#include <stdio.h>
#include <string.h>
#include "pat.h"

#define PAT_DIC_NUM 5
#define CHA_FILENAME_LEN 1024

static pat_t *dicfile[PAT_DIC_NUM];
static int ndicfile;

static char line[50000];	/* input line */
static char inkey[10000];	/* key (search/insert) */

static int command(void);
static void lookup(char *key);
static void make_pat_from_file(char *textname);
static void insert_from_file(pat_t * pat);
static char *seek_eol(register char *p, const char *eof);
static void prog_bar(FILE * fp, int count);

/*
 * Usage
 */
static void
usage(void)
{
    printf("Usage: pattool [-F filename]\n");
    printf("\tNo option    ---  Interpreter Mode\n");
    printf("\t-F filename  ---  Make PAT file (\"filename.pat\")\n");
    exit(1);
}

/*
 * Main
 */
int
main(int argc, char *argv[])
{
    if (argc == 1)		/* no option */
	command();
    else if (argc >= 3 && (strcmp(argv[1], "-F") == 0)) {
	char textname[CHA_FILENAME_LEN];
	char patname[CHA_FILENAME_LEN];
	char *basename;

	basename = argv[2];
	printf("Make Index File \"%s.pat\" from \"%s.int\"\n",
	       basename, basename);

	/* file open & make patricia tree */
	sprintf(textname, "%s.int", basename);
	make_pat_from_file(textname);

	/* save patricia tree */
	sprintf(patname, "%s.pat", basename);
	pat_save(dicfile[0], patname);
    } else
	usage();

    return 0;
}

/*
 * Command interpriter
 */
static int
command(void)
{
    char comm;
    int i;
    char *rslt[500];
    char strtmp[1000];
    char textname[CHA_FILENAME_LEN];
    char patname[CHA_FILENAME_LEN];

    ndicfile = 0;		/* the number of dictionary */

    printf("Interpreter Mode:  \'q\' exit, '?\' help\n");

    /* Command interpriter */
    while (1) {
	printf("> ");
	fflush(stdout);

	fgets(line, sizeof(line), stdin); /* input of command */

	sscanf(line, "%c %s", &comm, inkey);
	switch (comm) {

	case 'F':		/* insert from file*/
	    sprintf(textname, "%s.int", inkey);
	    make_pat_from_file(textname);
	    break;

	case 'e':		/* search key (exact match) */
	    if (ndicfile == 0) {	/* process ERROR */
		fprintf(stderr,
			"!!! make or load PAT data before SEARCH.\n");
		break;
	    }
	    rslt[0] = '\0';
	    for (i = 0; i < ndicfile; i++) {
		pat_search_exact(dicfile[i], inkey, rslt);
	    }
	    printf("%s", rslt[0]);
	    break;

	case 'j': /* lookup dictionary for sentence (1 step of ChaSen) */
	    if (ndicfile == 0) {	/* process ERROR */
		fprintf(stderr,
			"!!! make or load PAT data before SEARCH.\n");
		break;
	    }
	    lookup(inkey);
	    break;

	case 'S':		/* save tree */
	    strcat(inkey, ".pat");
	    pat_save(dicfile[0], inkey);
	    break;

	case 'L':		/* load tree */
	    strcpy(strtmp, inkey);
	    sprintf(textname, "%s.int", inkey);
	    sprintf(patname, "%s.pat", inkey);
	    /* open corpus */
	    dicfile[ndicfile] = pat_open(textname, patname);
	    ndicfile++;
	    break;

	case 'q':		/* end of interpreter */
	case 'Q':	        /* end of interpreter */
	    printf("QUIT\n");
	    return 0;

	default:		/* help */
	    printf("command:\n\
              \tj [string] --- ChaSen search\n\
              \te [string] --- exact match search\n\
              \tF [file] --- make patricia tree from file\n\
              \tS [file] --- save patricia tree\n\
              \tL [file] --- load patricia tree\n\
              \tq --- quit\n");
	    break;
	}

	printf("ok\n");
	fflush(stdout);		/* prompt */
    }
}


static void
make_pat_from_file(char *textname)
{
    if ((dicfile[ndicfile] = pat_open(textname, NULL))
	== NULL) {
	fprintf(stderr, "No such File: %s\n", textname);
	exit(1);
    }

    insert_from_file(dicfile[ndicfile]);
    ndicfile++;
}

static void
insert_from_file(pat_t * pat)
{
    int count = 0;
    char *c, *bof, *eof;

    bof = pat_get_text(pat, 0);
    eof = bof + pat_text_size(pat);

    for (c = bof; c < eof; c = seek_eol(c, eof)) {
	pat_insert(pat, c, c - bof);
	prog_bar(stdout, ++count);
    }

    printf(" %d\n", count);
    printf("read %d words, %d bytes\n", count, c - bof);
}

static char *
seek_eol(register char *p, const char *eof)
{
    for (; p < eof; p++) {
	if (*p == '\n')
	    return p + 1;
    }
    return p;
}

static void
prog_bar(FILE * fp, int count)
{
    if (count % 10000 == 0) {
	fputc('.', fp);
	if (count % 200000 == 0)
	    fprintf(fp, " %d\n", count);
	fflush(fp);
    }
}

static void
lookup(char *key)
{
    int dic_no, i;
    char *dic_buffer[256], *dic_bof;

    for (dic_no = 0; dic_no < ndicfile; dic_no++) {
	dic_bof = pat_get_text(dicfile[dic_no], 0);
	pat_search(dicfile[dic_no], key, dic_buffer);
	for (i = 0; dic_buffer[i] != NULL; i++)
	    printf("%s: %d\n", dic_buffer[i], dic_buffer[i] - dic_bof);
    }
}
