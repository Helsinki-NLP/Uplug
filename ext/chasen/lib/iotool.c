/*
 * iotools.c 
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
 *
 * 1990/12/14/Fri       Yutaka MYOKI(Nagao Lab., KUEE)
 * 1990/12/25/Tue       Modified
 * Oct. 1996       A.Kitauchi <akira-k@is.aist-nara.ac.jp>
 * $Id$
 */
#include <stdio.h>
#include <stdarg.h>
#include "chadic.h"
#include "config.h"

#ifdef PATHTYPE_MSDOS
#define RCFILE "\\chasenrc"
#define RC2FILE "\\chasen2rc"
#else
#define RCFILE "/.chasenrc"
#define RC2FILE "/.chasen2rc"
#endif

#define OLDRCFILE "/.jumanrc"

int Cha_lineno, Cha_lineno_error;
int Cha_errno = 0;

static FILE *cha_stderr = NULL;
static char progpath[CHA_FILENAME_LEN] = "chasen";
static char filepath[CHA_FILENAME_LEN];
static char grammar_dir[CHA_FILENAME_LEN];
static char chasenrc_path[CHA_FILENAME_LEN];

/*
 * cha_convert_escape - convert escape characters
 */
char *
cha_convert_escape(char *str, int ctrl_only)
{
    char *s1, *s2;

    for (s1 = s2 = str; *s1; s1++, s2++) {
	if (*s1 != '\\')
	    *s2 = *s1;
	else {
	    switch (*++s1) {
	    case 't':
		*s2 = '\t';
		break;
	    case 'n':
		*s2 = '\n';
		break;
	    default:
		if (ctrl_only)
		    *s2++ = '\\';
		*s2 = *s1;
		break;
	    }
	}
    }
    *s2 = '\0';

    return str;
}

#if defined _WIN32 && ! defined __CYGWIN__
/*
 * cha_set_progpath - set program pathname
 *
 *	progpath is used in cha_exit() and cha_exit_file()
 */
static void
which(char *filename, char *path)
{
    char *ps, *pe;
    int fl;

    strcpy(path, ".\\");
    strcat(path, filename);
    if (fopen(path, "r") != NULL)
	return;

    ps = getenv("PATH");

    for (pe = ps, fl = 0; !fl; pe++) {
	if (*pe == '\0') {
	    *pe = ';';
	    fl = 1;
	}
	if (*pe == ';') {
	    *pe = '\0';
	    strcpy(path, ps);
	    if (pe[-1] != '\\')
		strcat(path, "\\");
	    strcat(path, filename);
	    if (fopen(path, "r") != NULL)
		return;
	    ps = pe + 1;
	}
    }
}
#endif /* _WIN32 */

void
cha_set_progpath(char *path)
{
#if defined _WIN32 && ! defined __CYGWIN__
    if (strchr(path, PATH_DELIMITER) != NULL)
	strcpy(progpath, path);
    else
	which("chasen.exe", progpath);
#else /* not _WIN32 */
    strcpy(progpath, path);
#endif /* _WIN32 */
}

/*
 * cha_set_rcpath - set chasenrc file path
 *
 *	this function is called when -r option is used.
 */
void
cha_set_rcpath(char *filename)
{
    strcpy(chasenrc_path, filename);
}

/*
 * cha_get_rcpath
 *
 *	called only from chasen.c
 */
char *
cha_get_rcpath(void)
{
    return chasenrc_path;
}

/*
 * cha_get_grammar_dir
 *
 *	called only from chasen.c
 */
char *
cha_get_grammar_dir(void)
{
    return grammar_dir;
}

void
cha_set_filepath(char *filename)
{
    strcpy(filepath, filename);
    Cha_lineno = Cha_lineno_error = 0;
}

/*
 * cha_fopen - open file, or error end
 *
 * inputs:
 *	ret - exit code (don't exit if ret < 0)
 */
FILE *
cha_fopen(char *filename, char *mode, int ret)
{
    FILE *fp;

    if (filename[0] == '-' && filename[1] == '\0')
	return stdin;

    if ((fp = fopen(filename, mode)) != NULL) {
	/*
	 * filepath is used in cha_exit_file() 
	 */
	if (*mode == 'r') {
	    if (filename != filepath)
		strcpy(filepath, filename);
	    Cha_lineno = Cha_lineno_error = 0;
	}
    } else if (ret >= 0)
	cha_exit_perror(filename);

    return fp;
}

FILE *
cha_fopen2(char *filename1, char *filename2, char *mode, int ret)
{
    FILE *fp;

    if ((fp = cha_fopen(filename1, mode, -1)) != NULL)
	return fp;

    if ((fp = cha_fopen(filename2, mode, -1)) != NULL)
	return fp;

    cha_exit(ret, "can't open %s or %s", filename1, filename2);

    /*
     * to avoid warning 
     */
    return NULL;
}

/*
 * cha_fopen_grammar - open file from current or grammar directory
 *
 * inputs:
 *	dir - 0: read from current directory
 *	      1: read from grammar directory
 *	      2: read from current directory or grammar directory
 *
 *	ret - return the code when fopen() fails
 *
 * outputs:
 *	filepathp - file path string
 */
FILE *
cha_fopen_grammar(char *filename, char *mode, int ret, int dir,
		  char **filepathp)
{
    FILE *fp;

    *filepathp = filename;
    switch (dir) {
    case 0:
	/*
	 * カレントディレクトリから読み込む 
	 */
	return cha_fopen(filename, mode, ret);
    case 2:
	/*
	 * カレントディレクトリから読み込む 
	 */
	if ((fp = cha_fopen(filename, mode, -1)) != NULL)
	    return fp;
	/*
	 * FALLTHRU 
	 */
    default:			/* should be 1 */
	/*
	 * 文法ディレクトリから読み込む 
	 * 文法ディレクトリが設定されていなければ .chasenrc を読み込む 
	 */
	if (grammar_dir[0] == '\0')
	    cha_read_grammar_dir();
	sprintf(filepath, "%s%s", grammar_dir, filename);
	*filepathp = filepath;
	return cha_fopen(filepath, mode, ret);
    }
}

FILE *
cha_fopen_grammar2(char *filename1, char *filename2, char *mode, int ret,
		   int dir, char **filepathp)
{
    FILE *fp;

    if (dir == 2) {
	if ((fp =
	     cha_fopen_grammar(filename1, mode, -1, 0, filepathp)) != NULL)
	    return fp;
	if ((fp =
	     cha_fopen_grammar(filename2, mode, -1, 0, filepathp)) != NULL)
	    return fp;
	if ((fp =
	     cha_fopen_grammar(filename1, mode, -1, 1, filepathp)) != NULL)
	    return fp;
	if ((fp =
	     cha_fopen_grammar(filename2, mode, -1, 1, filepathp)) != NULL)
	    return fp;
    } else {
	if ((fp =
	     cha_fopen_grammar(filename1, mode, -1, dir,
			       filepathp)) != NULL)
	    return fp;
	if ((fp =
	     cha_fopen_grammar(filename2, mode, -1, dir,
			       filepathp)) != NULL)
	    return fp;
    }

    cha_exit(ret, "can't open %s or %s", filename1, filename2);

    /*
     * to avoid warning 
     */
    return NULL;
}

/*
 * cha_malloc()
 */
void *
cha_malloc(size_t n)
{
    void *p;

    if ((p = malloc(n)) == NULL)
	cha_exit_perror("malloc");

    return p;
}

void *
cha_realloc(void *ptr, size_t n)
{
    void *p;

    if ((p = realloc(ptr, n)) == NULL)
	cha_exit_perror("realloc");

    return p;
}

#define CHA_MALLOC_SIZE (1024 * 64)
static char *
cha_malloc_char(int size)
{
    static int idx = CHA_MALLOC_SIZE;
    static char *ptr;

    if (idx + size >= CHA_MALLOC_SIZE) {
	ptr = (char *) cha_malloc(CHA_MALLOC_SIZE);
	idx = 0;
    }

    idx += size;
    return ptr + idx - size;
}

char *
cha_strdup(char *str)
{
    char *newstr;

    newstr = cha_malloc_char(strlen(str) + 1);
    strcpy(newstr, str);

    return newstr;
}

/*
 * cha_exit() - print error messages on stderr and exit
 */
void
cha_set_stderr(FILE * fp)
{
    cha_stderr = fp;
}

void
cha_exit(int status, char *format, ...)
{
    va_list ap;

    if (Cha_errno)
	return;

    if (!cha_stderr)
	cha_stderr = stderr;
    else if (cha_stderr != stderr)
	fputs("500 ", cha_stderr);

    if (progpath)
	fprintf(cha_stderr, "%s: ", progpath);
    va_start(ap, format);
    vfprintf(cha_stderr, format, ap);
    va_end(ap);
    if (status >= 0) {
	fputc('\n', cha_stderr);
	if (cha_stderr == stderr)
	    exit(status);
	Cha_errno = 1;
    }
}

void
cha_exit_file(int status, char *format, ...)
{
    va_list ap;

    if (Cha_errno)
	return;

    if (!cha_stderr)
	cha_stderr = stderr;
    else if (cha_stderr != stderr)
	fputs("500 ", cha_stderr);

    if (progpath)
	fprintf(cha_stderr, "%s: ", progpath);

    if (Cha_lineno == 0)
	;	/* do nothing */
    else if (Cha_lineno == Cha_lineno_error)
	fprintf(cha_stderr, "%s:%d: ", filepath, Cha_lineno);
    else
	fprintf(cha_stderr, "%s:%d-%d: ", filepath, Cha_lineno_error,
		Cha_lineno);

    va_start(ap, format);
    vfprintf(cha_stderr, format, ap);
    va_end(ap);

    if (status >= 0) {
	fputc('\n', cha_stderr);
	if (cha_stderr == stderr)
	    exit(status);
	Cha_errno = 1;
    }
}

void
cha_perror(char *s)
{
    cha_exit(-1, "");
    perror(s);
}

void
cha_exit_perror(char *s)
{
    cha_perror(s);
    exit(1);
}

FILE *
cha_fopen_rcfile(void)
{
    FILE *fp;
    char *home_dir, *rc_env, *getenv();

    /*
     * -R option (standard alone) 
     */
    if (!strcmp(chasenrc_path, "*")) {
	/*
	 * RCPATH in rcpath.h 
	 */
	strcpy(chasenrc_path, RCPATH);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
	cha_exit(1, "can't open %s", chasenrc_path);
    }

    /*
     * -r option 
     */
    if (chasenrc_path[0])
	return cha_fopen(chasenrc_path, "r", 1);

    /*
     * environment variable CHASENRC 
     */
    if ((rc_env = getenv("CHASENRC")) != NULL) {
	strcpy(chasenrc_path, rc_env);
	return cha_fopen(chasenrc_path, "r", 1);
    }

    /*
     * .chasenrc in the home directory 
     */
    if ((home_dir = getenv("HOME")) != NULL) {
	/*
	 * .chasenrc 
	 */
	sprintf(chasenrc_path, "%s%s", home_dir, RC2FILE);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
	sprintf(chasenrc_path, "%s%s", home_dir, RCFILE);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
    }
#ifdef PATHTYPE_MSDOS
    else if ((home_dir = getenv("HOMEDRIVE")) != NULL) {
	sprintf(chasenrc_path, "%s%s%s", home_dir, getenv("HOMEPATH"),
		RC2FILE);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
	sprintf(chasenrc_path, "%s%s%s", home_dir, getenv("HOMEPATH"),
		RCFILE);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
    }
    /*
    strcpy(chasenrc_path, progpath);
    sprintf(strrchr(chasenrc_path, PATH_DELIMITER) + 1, "dic%s", RC2FILE);
    if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	return fp;
    strcpy(chasenrc_path, progpath);
    sprintf(strrchr(chasenrc_path, PATH_DELIMITER) + 1, "dic%s", RCFILE);
    if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
    return fp; 
    */
#endif /* PATHTYPE_MSDOS */

    /*
     * RCPATH in rcpath.h 
     */
    strcpy(chasenrc_path, RCPATH);

    if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	return fp;

#ifdef PATHTYPE_MSDOS
    cha_exit(1, "can't open chasenrc or %s", chasenrc_path);
#else
    cha_exit(1, "can't open .chasenrc, .jumanrc, or %s", chasenrc_path);
#endif

    /*
     * to avoid warning 
     */
    return NULL;
}

/*
 * read .chasenrc and set grammar directory
 */
void
cha_read_grammar_dir(void)
{
    FILE *fp;
    chasen_cell_t *cell;

    fp = cha_fopen_rcfile();

    while (!cha_s_feof(fp)) {
	char *s;
	cell = cha_s_read(fp);
	s = cha_s_atom(cha_car(cell));
	if (strmatch2(s, JSTR_GRAM_FILE, ESTR_GRAM_FILE)) {
	    strcpy(grammar_dir, cha_s_atom(cha_car(cha_cdr(cell))));
	    s = grammar_dir + strlen(grammar_dir);
	    if (s[-1] != PATH_DELIMITER) {
		s[0] = PATH_DELIMITER;
		s[1] = '\0';
	    }
	    break;
	}
    }

    if (grammar_dir[0] == '\0') {
	char *s;
	strcpy(grammar_dir, chasenrc_path);
	if ((s = strrchr(grammar_dir, PATH_DELIMITER)) != NULL)
	    s[1] = '\0';
	else
	    grammar_dir[0] = '\0';
    }

    fclose(fp);
}
