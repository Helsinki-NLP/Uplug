/*
 * server.c - ChaSen server
 *
 * Copyright (c) 1996,1997 Nara Institute of Science and Technology
 *
 * Author: M.Izumo <masana-i@is.aist-nara.ac.jp>, Tue Feb 11 1997
 *         A.Kitauchi <akira-k@is.aist-nara.ac.jp>, Apr 1997
 * $Id$
 *
 */

#ifndef NO_SERVER

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <sys/types.h>
#include <unistd.h>
#include <sys/stat.h>
#endif

#if defined _WIN32 && ! defined __CYGWIN__
#include <winsock.h>
#else /* not _WIN32 */
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/wait.h>
#endif /* _WIN32 */

#include <string.h>
#include <signal.h>
#include <errno.h>

#include "chalib.h"

#define SERVER_VERSION        "茶筌 2.0 protocol 1.0 ChaSen server 1.5"
#ifndef SOMAXCONN
#define SOMAXCONN 5
#endif

#if defined _WIN32 && ! defined __CYGWIN__
#define fgets	fgets_sock
#else
static int client_fd = -1;
static FILE *client_ofp = NULL;
static FILE *client_ifp = NULL;
#endif

/*
 * skip_until_dot()
 */
static void
skip_until_dot(FILE * fp)
{
    char buff[BUFSIZ];
    while (fgets(buff, BUFSIZ, fp)) {
	if (buff[0] == '.' &&
	    (buff[1] == '\n' || (buff[1] == '\r' && buff[2] == '\n')))
	    break;
    }
}

/*
 * chomp()
 */
static char *
chomp(char *s)
{
    int len = strlen(s);

    if (len < 2) {
	if (len == 0)
	    return s;
	if (s[0] == '\n' || s[0] == '\r')
	    s[0] = '\0';
	return s;
    }
    if (s[len - 1] == '\n')
	s[--len] = '\0';
    if (s[len - 1] == '\r')
	s[--len] = '\0';
    return s;
}

/*
 * read_chasenrc_server()
 */
static int
read_chasenrc_server(void)
{
    cha_set_filepath("chasenrc");

    cha_set_getc_server();
    cha_read_rcfile_fp(client_ifp);
    cha_set_getc_alone();

    if (!Cha_errno)
	fputs("200 OK\n", client_ofp);

    Cha_errno = 0;
    fflush(client_ofp);
    return 1;
}

/*
 * do_chasen()
 */
static int
do_chasen(void)
{
    char line[CHA_INPUT_SIZE], *end_of_line, *buf;
    int ret;

    /*
     * fgets() のチェックのための番人 
     */
    end_of_line = line + sizeof(line) - 1;
    *end_of_line = '\n';

    while (fgets(line, sizeof(line), client_ifp) != NULL) {
	if (*end_of_line != '\n') {
	    fputs("Line too long\n", client_ofp);
	    skip_until_dot(client_ifp);
	    *end_of_line = '\n';
	    return 1;
	}

	chomp(line);
#if 0
	printf("## %d: %s\n", __LINE__, line);
	fflush(stdout);
#endif
	buf = line;
	if (line[0] == '.') {
	    if (line[1] == '\0')
		return 1;
	    /*
	     * remove stuff byte '.' 
	     * s/^\.\././; 
	     */
	    if (line[1] == '.')
		buf++;
	}

	/*
	 * chasen_fparse() returns 0/1/2 
	 * 0/1 is OK 
	 */
	if ((ret = chasen_sparse(buf, client_ofp)) == 2)
	    return 0;

	fflush(client_ofp);
    }

    return 0;			/* Connection Closed */
}

/*
 * chasen_run()
 */
static int
chasen_run(char **argv)
{
    int ret;

    if (chasen_getopt_argv(argv, NULL) || argv[Cha_optind]) {
	skip_until_dot(client_ifp);
	fputs("500 Option Error\n", client_ofp);
	fflush(client_ofp);
	return 1;
    }
    Cha_optind = 0;

    fputs("200 OK\n", client_ofp);
    ret = do_chasen();
    fputs(".\n", client_ofp);
    fflush(client_ofp);

    return ret;
}

/*
 * expand_string()
 */
static void
expand_string(char *str)
{
    char *in, *out;

    for (out = in = str; *in; in++) {
	/*
	 * quotation 
	 */
	if (*in == '"' || *in == '\'')
	    continue;
	if (*in != '\\')
	    *out++ = *in;
	else {
	    switch (*++in) {
	    case 'n':
		*out++ = '\n';
		break;
	    case 't':
		*out++ = '\t';
		break;
	    case 'v':
		*out++ = '\v';
		break;
	    case 'b':
		*out++ = '\b';
		break;
	    case 'r':
		*out++ = '\r';
		break;
	    case 'f':
		*out++ = '\f';
		break;
	    case 'a':
		*out++ = 0x07;
		break;
	    case '\0':
		break;
	    default:
		*out++ = *in;
	    }
	}
    }
    *out = '\0';
}

/*
 * split_args()
 */
static int
split_args(char *argbuff, int maxargc, char **argv)
{
    char *arg;
    int argc, i;

    arg = argbuff;
    maxargc--;

    for (argc = 0; argc < maxargc; argc++) {
	/*
	 * skip space 
	 */
	while (*arg == ' ')
	    arg++;
	if (*arg == '\0')
	    break;

	argv[argc] = arg;

	/*
	 * find end of arg. 
	 */
	while (*arg && *arg != ' ') {
	    /*
	     * quoted string 
	     */
	    if (*arg == '"' || *arg == '\'') {
		char *s = strchr(arg + 1, *arg);
		if (s != NULL)
		    arg = s + 1;
		else
		    arg += strlen(arg);
	    }
	    /*
	     * escaped character 
	     */
	    else if (*arg++ == '\\' && *arg)
		arg++;
	}

	if (*arg == '\0') {
	    argc++;
	    break;
	}
	*arg++ = '\0';
    }
    argv[argc] = NULL;

    for (i = 0; i < argc; i++)
	expand_string(argv[i]);

    return argc;
}

/*
 * do_cmd()
 *
 * return:
 * 1 - continue
 * 0 - connection closed
 */
static int
do_cmd(char *line)
{
    char *argv[64];
    int argc;

#if 0
    printf("## %s\n", line);
#endif
    argc = split_args(line, 64, argv);

    if (!strcasecmp(argv[0], "RUN"))
	return chasen_run(argv);
    if (!strcasecmp(argv[0], "RC"))
	return read_chasenrc_server();
    if (!strcasecmp(argv[0], "QUIT"))
	return 0;
    if (!strcasecmp(argv[0], "HELP")) {
	static char *message[] = {
	    "200 OK\n",
	    "RUN [options]\n",
	    "  -b          show best path (default)\n",
	    "  -m          show all morphemes\n",
	    "  -p          show all paths\n",
	    "\n",
	    "  -f          show formatted morpheme data (default)\n",
	    "  -e          show entire morpheme data\n",
	    "  -c          show coded morpheme data\n",
	    "  -d          show detailed morpheme data\n",
	    "  -v          show detailed morpheme data for ViCha\n",
	    "  -F format   show morpheme with formatted output\n",
	    "\n",
	    "  -j          Japanese sentence mode\n",
	    "  -w width    specify the cost width\n",
	    "  -C          use command mode\n",
	    "\n",
	    "RC\n",
	    "QUIT\n",
	    "HELP\n",
	    ".\n",
	    NULL
	};
	char **mes;

	for (mes = message; *mes; mes++)
	    fputs(*mes, client_ofp);
	fflush(client_ofp);

	return 1;
    }

    fprintf(client_ofp, "500 What ?\n");
    fflush(client_ofp);
    return 1;
}

static void
cmd_loop(void)
{
    static char buff[BUFSIZ];

    while (fgets(buff, BUFSIZ, client_ifp)) {
	chomp(buff);
	if (!buff[0])
	    continue;
	if (!do_cmd(buff))
	    break;
    }

    fprintf(client_ofp, "205 Quit\n");
    fflush(client_ofp);
}

static int
open_server_socket(unsigned short port)
{
    int sfd;
    struct sockaddr_in sin;

    if ((sfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
	cha_perror("socket");
	return -1;
    }

    memset(&sin, 0, sizeof(sin));
    sin.sin_port = htons(port);
    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = htonl(INADDR_ANY);

#ifdef SO_REUSEADDR
    {
	int on = 1;
	setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, (caddr_t) & on,
		   sizeof(on));
    }
#endif /* SO_REUSEADDR */

    if (bind(sfd, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
	cha_perror("bind");
	close(sfd);
	return -1;
    }

    /*
     * Set it up to wait for connections. 
     */
    if (listen(sfd, SOMAXCONN) < 0) {
	cha_perror("listen");
	close(sfd);
	return -1;
    }

    return sfd;
}

static void
sigchld_handler(int sig)
{
    int status;

    while (waitpid(-1, &status, WNOHANG) > 0);
    signal(SIGCHLD, sigchld_handler);
}

static int sfd = -1;
static void
sig_term(int dummy)
{
    shutdown(client_fd, 2);
    shutdown(sfd, 2);
    exit(0);
}

/*
 * chasen_server()
 *
 * return code: exit code
 */
int
chasen_server(char **argv, int port)
{
    extern void cha_set_stderr(FILE *);
    int i;

    if (chasen_getopt_argv(argv, stderr))
	return 1;
    argv += Cha_optind;
    Cha_optind = 0;

    /*
     * parse a dummy sentense to check the format of patdic
     * in parse.c:cha_get_mrph_data()
     */
    chasen_sparse_tostr("こんにちは。");

    /*
     * daemon initialization 
     */
    umask(0);

    if ((i = fork()) > 0)
	return 0;
    else if (i == -1) {
	fprintf(stderr, "chasend: unable to fork new process\n");
	cha_perror("fork");
	return 1;
    }

    if (setsid() == -1)
	cha_perror("Warning: setsid");

    signal(SIGHUP, SIG_IGN);
    signal(SIGPIPE, SIG_IGN);
    signal(SIGTERM, sig_term);
    signal(SIGINT, sig_term);
    signal(SIGQUIT, sig_term);

    /*
     * make a socket 
     */
    if ((sfd = open_server_socket(port)) < 0)
	return 1;

    signal(SIGCHLD, sigchld_handler);

    fputs("ChaSen server started\n", stdout);

    while (1) {
	int pid;

	if ((client_fd = accept(sfd, NULL, NULL)) < 0) {
	    if (errno == EINTR)
		continue;
	    cha_perror("accept");
	    return 1;
	}

	if ((pid = fork()) < 0) {
	    cha_perror("fork");
	    sleep(1);
	    continue;
	}

	if (pid == 0) {		/* child */
	    close(sfd);
	    client_ofp = fdopen(client_fd, "w");
	    client_ifp = fdopen(client_fd, "r");
	    cha_set_stderr(client_ofp);

	    fprintf(client_ofp, "200 Running ChaSen version: %s\n",
		    SERVER_VERSION);
	    fflush(client_ofp);

	    cmd_loop();

	    shutdown(client_fd, 2);
	    fclose(client_ofp);
	    fclose(client_ifp);
	    close(client_fd);

	    exit(0);
	}

	close(client_fd);
    }
}

#endif /* !NO_SERVER */
