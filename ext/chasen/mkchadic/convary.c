/*
 * convary
 * 
 * Read a sorted dictionary from stdin, and write an array for SUFARY
 * to stdout.
 *
 * $Id$
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>

#include "htobe.h"

char *prog_name;

void
usage(void)
{
    printf("\
Usage: convary < INPUT > OUTPUT\n");
    exit(1);
}

void
eexit(void)
{
    perror(prog_name);
    exit(2);
}

void
dump_offset(FILE * fp, long offset)
{
    offset = htobe(offset);
    if (fwrite(&offset, sizeof(offset), 1, stdout) != 1)
	eexit();
}

void
convert(FILE * in, FILE * out)
{
    int c;
    long offset, bol;

    offset = bol = 0;
    while ((c = fgetc(in)) != EOF) {
	offset++;
	if (c == '\n') {
	    dump_offset(out, bol);
	    bol = offset;
	}
    }
    if (ferror(in))
	eexit();
}

int
main(int argc, char *argv[])
{
    prog_name = argv[0];

    if (argc > 1)
	usage();

    convert(stdin, stdout);

    return EXIT_SUCCESS;
}
