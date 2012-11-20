/*
 *      convdic.c - convert JUMAN's connect file & grammar file to ChaSen's
 *
 * $Id$
 */

#include "chadic.h"
#include <unistd.h>
#include <sys/stat.h>
#include <dirent.h>

#define LINEMAX 8192

#define JM_CONNECT_FILE   "JUMAN.connect.c"
#define JM_CONNTMP_FILE   "JUMAN.connect"
#define JM_GRAMMAR_FILE   "JUMAN.grammar"
#define JM_CFORM_FILE     "JUMAN.katuyou"
#define JM_CTYPE_FILE     "JUMAN.kankei"
#define JM_TABLE_FILE     "JUMANTREE.table"
#define JM_MATRIX_FILE    "JUMANTREE.matrix"

static int
match_hinsi_name(char *str)
{
    int i, d;

    if (!strncmp(str, "*", 1) ||
	!strncmp(str, JSTR_BOS, strlen(JSTR_BOS)) ||
	!strncmp(str, ESTR_BOS, strlen(ESTR_BOS)) ||
	!strncmp(str, JSTR_EOS, strlen(JSTR_EOS)) ||
	!strncmp(str, ESTR_EOS, strlen(ESTR_EOS)))
	return 1;

    for (i = 0; (d = Cha_hinsi[0].daughter[i]) != 0; i++)
	if (!strncmp(str, Cha_hinsi[d].name, strlen(Cha_hinsi[d].name)))
	    return 1;

    return 0;
}

static void
convert_grammar(char *vdicdir)
{
    extern void cha_read_class(FILE *);	/* grammar.c */
    FILE *fpi, *fpo;
    char line[LINEMAX], *s, *filein, fileout[CHA_FILENAME_LEN];
    int parlevel, npar2;

    fpi =
	cha_fopen_grammar2(CHA_GRAMMAR_FILE, JM_GRAMMAR_FILE, "r", 1, 0,
			   &filein);
    sprintf(fileout, "%s/%s", vdicdir, VCHA_GRAMMAR_FILE);
    fpo = cha_fopen(fileout, "w", 1);

    fprintf(stderr, "converting %s -> %s\n", filein, fileout);

    parlevel = npar2 = 0;
    while (fgets(line, sizeof(line), fpi) != NULL) {
	for (s = line; *s; s++) {
	    switch (*s) {
	    case '(':
		if (++parlevel == 2) {
		    if (++npar2 > 1)
			fputc(' ', fpo);
		    continue;
		}
		break;
	    case ')':
		if (parlevel-- == 2)
		    continue;
		if (parlevel == 0)
		    npar2 = 0;
		break;
	    case ' ':
	    case '\t':
		if ((parlevel == 2 && npar2 == 1) ||
		    (parlevel == 3 && npar2 > 1))
		    continue;
		break;
	    case ';':
		fputs(s, fpo);
		goto next_line;
	    }
	    fputc(*s, fpo);
	}
      next_line:;
    }
    fclose(fpi);
    fclose(fpo);

    fpi = cha_fopen(fileout, "r", 1);
    cha_read_class(fpi);
    fclose(fpi);
}

static void
convert_connect(char *vdicdir)
{
    FILE *fpi, *fpo;
    char fileout[CHA_FILENAME_LEN];
    char line[LINEMAX], *s, *filein;
    int parlevel, nelem, korean, in_rule, nhinsi, skip;
    int cost = INT_MAX;

    nhinsi = 0;			/* to avoid warning */
    sprintf(fileout, "%s/%s", vdicdir, VCHA_CONNECT_FILE);

    fpi =
	cha_fopen_grammar2(JM_CONNECT_FILE, CHA_CONNECT_FILE, "r", 1, 0,
			   &filein);
    fpo = cha_fopen(fileout, "w", 1);

    /*
     * cha_read_grammar(stderr, 1, 0); 
     */
    fprintf(stderr, "converting %s -> %s\n", filein, fileout);

    parlevel = nelem = 0;
    skip = korean = 0;
    while (fgets(line, sizeof(line), fpi) != NULL) {
	in_rule = parlevel == 0 && line[0] != '(';

	for (s = line; *s; s++) {
	    if (*s == '(') {
		if (match_hinsi_name(s + 1)) {
		    fputc('(', fpo);
		    nhinsi = 1;
		}
	    } else if (nhinsi) {
		/*
		 * nhinsi - 1: first hinsi
		 *          2: first space
		 *          3: second hinsi
		 */
		int space = (*s == ' ' || *s == '\t' || *s == '\n');
		if (nhinsi == 2) {
		    if (space)
			continue;
		    nhinsi++;
		    if (*s != '*') {
			skip = 0;
			fputc(' ', fpo);
		    }
		} else {
		    if (space)
			if (++nhinsi == 2)
			    skip = 1;
		}
		if (nhinsi == 4 || *s == ')') {
		    nhinsi = 0;
		    skip = 0;
		    fputc(')', fpo);
		}
	    }

	    if (skip)
		continue;

	    if (in_rule || (korean && *s != 033)) {
		fputc(*s, fpo);
		continue;
	    }

	    switch (*s) {
	    case 033:
		if (s[1] == '(') {
		    fputc(*s++, fpo);
		    korean = 0;
		} else if (s[1] == '$' && s[2] == '(') {
		    /*
		     * Korean 
		     */
		    korean = 1;
		    fputc(*s++, fpo);
		    fputc(*s++, fpo);
		}
		break;
	    case ';':
		fputs(s, fpo);
		goto next_line;
	    case '(':
		if (++parlevel == 1)
		    fputc('(', fpo);
		break;
	    case ')':
		if (--parlevel == 1) {
		    if (++nelem == 2) {
			fputc(')', fpo);
			nelem = 0;
		    }
		} else if (parlevel == 0) {
		    fprintf(fpo, "%d",
			    !cost ? -1 : cost == INT_MAX ? 10 : cost * 10);
		    cost = INT_MAX;
		}
		break;
	    }
	    if (parlevel == 1 && *s >= '0' && *s <= '9')
		cost = (cost == INT_MAX ? 0 : cost * 10) + *s - '0';
	    else
		fputc(*s, fpo);
	}
      next_line:;
    }
    fclose(fpi);
    fclose(fpo);
}

static void
get_dic_filenames(char **dicfiles)
{
    char **df;
    DIR *dfd;
    struct dirent *dp;

    if ((dfd = opendir(".")) == NULL) {
	perror("opendir");
	exit(1);
    }

    df = dicfiles;
    while ((dp = readdir(dfd)) != NULL) {
	if (!memcmp(dp->d_name + strlen(dp->d_name) - 4, ".dic", 4))
	    *df++ = cha_strdup(dp->d_name);
    }
    *df = NULL;

    closedir(dfd);
}

static void
convert_dic(char *dicdir)
{
    char *dicfiles[1024];
    char **dicp, fileout[CHA_FILENAME_LEN];
    FILE *fpi, *fpo;

    get_dic_filenames(dicfiles);

    for (dicp = dicfiles; *dicp; dicp++) {
	fpi = cha_fopen(*dicp, "r", 1);
	sprintf(fileout, "%s/%s", dicdir, *dicp);
	fpo = cha_fopen(fileout, "w", 1);
	fprintf(stderr, "converting %s -> %s\n", *dicp, fileout);

	fprintf(fpo, "(%s 10)\n", ESTR_DEF_POS_COST);
	while (!cha_s_feof(fpi)) {
	    chasen_cell_t *cell, *cell2, *cell3;
	    cell = cell2 = cha_s_read(fpi);
	    while (atomp(cha_car(cell2)))
		cell2 = cha_car(cha_cdr(cell2));
	    if (nullp(cell3 = cha_assoc(cha_tmp_atom(JSTR_WORD), cell2)))
		if (nullp
		    (cell3 = cha_assoc(cha_tmp_atom(ESTR_WORD), cell2)))
		    cha_exit(1, "can't find midasi\n");	/* cha_exit_file */
	    for (cell2 = cha_cdr(cell3); !nullp(cell2);
		 cell2 = cha_cdr(cell2)) {
		cell3 = car_val(cell2);
		if (!atomp(cell3) && !nullp(cdr_val(cell3))) {
		    char cost_str[256];
		    sprintf(cost_str, "%.0f",
			    atof(s_atom_val(car_val(cdr_val(cell3)))) *
			    10);
		    s_atom_val(car_val(cdr_val(cell3))) =
			cha_strdup(cost_str);
		}
	    }
	    cha_s_print(fpo, cell);
	    fputc('\n', fpo);
	    cha_s_free(cell);
	}
	fclose(fpi);
	fclose(fpo);
    }
}

static void
mkdir_dicdir(char *dicdir)
{
#if defined _WIN32 && ! defined __CYGWIN__   
   mkdir(dicdir);
#else
   mkdir(dicdir, 0755);
#endif
}

#if defined _WIN32 && ! defined __CYGWIN__
#define COPY_COMMAND "copy"
#else
#define COPY_COMMAND "cp"
#endif
static void
copy_file(char *dstdir, char *dstfile, char *srcfile)
{
    char command[1024];

    fprintf(stderr, "copying %s -> %s/%s\n", srcfile, dstdir, dstfile);
    sprintf(command, "%s %s %s/%s", COPY_COMMAND, srcfile, dstdir,
	    dstfile);
    if (system(command))
	cha_exit(1, "copy failed.");
}

static int
file_readable(char *file)
{
    FILE *fp;

    if ((fp = fopen(file, "r")) == NULL)
	return 0;
    fclose(fp);
    return 1;
}

int
main(int argc, char *argv[])
{
    char *dicdir;

    cha_set_progpath(argv[0]);

    if (argc != 2) {
	fprintf(stderr, "usage: convdic new_dic_dir\n");
	fprintf(stderr,
		"    convdic needs to be run in the directory which contains bi-gram version\n");
	fprintf(stderr, "    of the dictionaries.\n");
	exit(1);
    }

    dicdir = argv[1];
    mkdir_dicdir(dicdir);

    /*
     * copy to cforms.cha 
     */
    if (file_readable(CHA_CFORM_FILE))
	copy_file(dicdir, VCHA_CFORM_FILE, CHA_CFORM_FILE);
    else if (file_readable(JM_CFORM_FILE))
	copy_file(dicdir, VCHA_CFORM_FILE, JM_CFORM_FILE);
    else
	cha_exit(1, "can't open %s or %s.", CHA_CFORM_FILE, JM_CFORM_FILE);

    /*
     * copy to ctypes.cha 
     */
    if (file_readable(CHA_CTYPE_FILE))
	copy_file(dicdir, VCHA_CTYPE_FILE, CHA_CTYPE_FILE);
    else if (file_readable(JM_CTYPE_FILE))
	copy_file(dicdir, VCHA_CTYPE_FILE, JM_CTYPE_FILE);
    else
	cha_exit(1, "can't open %s or %s.", CHA_CTYPE_FILE, JM_CTYPE_FILE);

    convert_grammar(dicdir);
    convert_connect(dicdir);
    convert_dic(dicdir);

    return 0;
}
