/*
 *      sortdic.c - sort a dictionary
 *
 *      it does same as "sort -s +0 -1 | uniq | gawk -e '{printf("%s\0",$0)}'"
 *
 *      by A.Kitauchi <akira-k@is.aist-nara.ac.jp>, Oct. 1996
 *
 */

#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include "chadic.h"

#define LINEMAX 8192
#define DEFAULT_NLINE (1024 * 256)

typedef struct _line_info {
    long ptr;
    long len;
    char *midasi;
} line_info;

#define BLOCK_SIZE (1024 * 256)
#define BLOCK_MAX 1024
static char *buffer_ptr[BLOCK_MAX];
static int buffer_ptr_num = 0;
static int buffer_idx = BLOCK_SIZE;

static char *
cha_malloc_char(int size)
{
    if (buffer_idx + size >= BLOCK_SIZE) {
	if (buffer_ptr_num == BLOCK_MAX)
	    cha_exit(1, "Can't allocate memory");
	buffer_ptr[buffer_ptr_num++] = cha_malloc(BLOCK_SIZE);
	buffer_idx = 0;
    }

    buffer_idx += size;
    return buffer_ptr[buffer_ptr_num - 1] + buffer_idx - size;
}

static int
ustrcmp(unsigned char *s1, unsigned char *s2)
{
    for (; *s1 && *s1 == *s2; s1++, s2++);
    return (int) (*s1 - *s2);
}

static int
midasi_compare(line_info * l1, line_info * l2)
{
    int rc;

    rc = ustrcmp(l1->midasi, l2->midasi);
    if (rc)
	return rc;
    else
	return (int) (l1->ptr - l2->ptr);
}

static void
normal_sort(FILE * fpi, FILE * fpo, char *filebuf)
{
    line_info *line;
    long nline, l;
    long n_line_info = DEFAULT_NLINE;
    char *bol, *b, *pre = "";
    long len;
    int c;

    line = cha_malloc(sizeof(line_info) * n_line_info);

    fprintf(stderr, "reading... ");

    nline = 0;
    bol = filebuf;
    while ((c = fgetc(fpi)) != EOF) {
	*filebuf = c;
	filebuf++;
	if (c == '\n') {
	    if (nline >= n_line_info) {
		n_line_info *= 2;
		line = cha_realloc(line, n_line_info);
	    }
	    line[nline].midasi = bol;
	    line[nline].ptr = nline;
	    line[nline].len = filebuf - bol;
	    nline++;
	    bol = filebuf;
	}
    }
    fprintf(stderr, "(%ld lines) ", nline);

    fprintf(stderr, "sorting... ");
    qsort(line, nline, sizeof(line_info), (int (*)()) midasi_compare);

    fprintf(stderr, "writing... ");

    for (l = 0; l < nline; l++) {
	b = line[l].midasi;
	len = line[l].len;
	if (memcmp(pre, b, len) != 0) {	/* uniq */
	    fwrite(b, len, 1, fpo);
	    pre = b;
	}
    }
}

static void
nomem_sort(FILE * fpi, FILE * fpo)
{
    line_info *line;
    int nline, l;
    char buf[LINEMAX];
    char prebuf[LINEMAX];
    int len;

    fprintf(stderr, "counting lines... ");
    for (nline = 0; fgets(buf, sizeof(buf), fpi) != NULL; nline++);
    fprintf(stderr, "(%d lines) ", nline);
    line = (line_info *) cha_malloc(sizeof(line_info) * nline);

    fprintf(stderr, "reading... ");
    rewind(fpi);
    for (l = 0; l < nline; l++) {
	line[l].ptr = ftell(fpi);
	fgets(buf, sizeof(buf), fpi);
	line[l].midasi = cha_malloc_char(strlen(buf) + 1);
	strcpy(line[l].midasi, buf);
    }

    fprintf(stderr, "sorting... ");
    qsort(line, nline, sizeof(line_info), (int (*)()) midasi_compare);

    fprintf(stderr, "writing... ");

    prebuf[0] = '\0';
    for (l = 0; l < nline; l++) {
	fseek(fpi, line[l].ptr, SEEK_SET);
	fgets(buf, sizeof(buf), fpi);
	len = (char *) memchr(buf, '\n', sizeof(buf)) + 1 - buf;
	if (memcmp(prebuf, buf, len)) {
	    fwrite(buf, len, 1, fpo);
	    memcpy(prebuf, buf, len);
	}
    }
}

static void
sortdic(char *infile, char *outfile)
{
    FILE *fpi, *fpo;
    struct stat st;
    char *filebuf;

    /*
     * eol is "\n" for UNIX/Win 
     */
    fpi = cha_fopen(infile, "rb", 1);
    fpo = outfile ? cha_fopen(outfile, "wb", 1) : stdout;

    fstat(fileno(fpi), &st);
    filebuf = malloc(st.st_size);

    if (filebuf != NULL) {
	normal_sort(fpi, fpo, filebuf);
    } else {
	nomem_sort(fpi, fpo);
    }

    fclose(fpi);
    fclose(fpo);

    fprintf(stderr, "done.\n");
}

int
main(int argc, char *argv[])
{
    time_t t0, t1;

    if (argc < 2) {
	fprintf(stderr, "usage: sortdic input-file [ output-file ]\n");
	exit(1);
    }

    cha_set_progpath(argv[0]);

    time(&t0);
    sortdic(argv[1], argv[2]);
    time(&t1);
    fprintf(stderr, "processing time: %d sec\n", (int) (t1 - t0));

    return 0;
}
