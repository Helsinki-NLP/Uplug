#include <stdio.h>
#include "chasen.h"

char *opt[] = { "chasmpl", "-F", "%m / %y / %P- / %T  / %F \n", NULL };

int
main(int argc, char *argv[])
{
    if (chasen_getopt_argv(opt, stdout))
	exit(1);

#if 0
    while (!chasen_fparse(stdin, stdout));
#else
    chasen_sparse("茶筌でおいしいお茶を立てました。", stdout);
#endif

    return 0;
}
