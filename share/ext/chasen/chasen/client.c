/*
 * client.c - ChaSen client
 *
 * Copyright (C) 1996-1997 Nara Institute of Science and Technology
 *
 * Author: A.Kitauchi <akira-k@is.aist-nara.ac.jp>, Apr. 1996
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
#endif

#if defined _WIN32 && ! defined __CYGWIN__
#include <winsock.h>
#include <windows.h>
#else /* not _WIN32 */
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif /* HAVE_SYS_WAIT_H */
#endif /* _WIN32 */

#include <string.h>
#include <signal.h>
#include <errno.h>

#include "chalib.h"

/*
 * max of the command line length 
 */
#define CHA_COMM_LINE_MAX 1024

#if defined _WIN32 && ! defined __CYGWIN__
#define fgets	fgets_sock

DWORD WINAPI fork_and_gets(LPVOID, FILE *);

/*
 * fgets_sock:  get strings not from file stream but from socket
 */
char *
fgets_sock(char *buf, int size, int s)
{
    int i, ret;

    i = 0;
    for (i = 0; i < size - 1; i++) {
	ret = recv(s, buf + i, 1, 0);
	if (ret == 0) {
	    *(buf + i) = 0;
	    return (char *) NULL;
	}

	if (*(buf + i) == '\n') {
	    i++;
	    break;
	}
    }
    *(buf + i) = 0;

    return buf;
}
#endif /* _WIN32 */


/*
 * check_status
 */
#if defined _WIN32 && ! defined __CYGWIN__
static void
check_status(SOCKET ifp, char *mes)
#else
static void
check_status(FILE * ifp, char *mes)
#endif /* _WIN32 */
{
    char line[CHA_INPUT_SIZE];

    fgets(line, sizeof(line), ifp);
    if (strncmp(line, "200 ", 4)) {
	if (mes == NULL)
	    fputs(line + 4, stderr);
	else
	    cha_exit(1, mes);
	exit(1);
    }
}

/*
 * do_chasen_client
 */
#if defined _WIN32 && ! defined __CYGWIN__
static void
fp_copy(SOCKET ofp, FILE * ifp)
#else
static void
fp_copy(FILE * ofp, FILE * ifp)
#endif /* _WIN32 */
{
    char line[CHA_INPUT_SIZE];
    /*
     * whether output is stdout or not 
     */
    int istty = isatty(fileno(stdout));

    /*
     * sizeof(line)-1: space for "\n" at the end of line 
     */
    while (cha_fgets(line, sizeof(line) - 1, ifp) != NULL) {
	int len = strlen(line);
	if (line[len - 1] != '\n') {
	    line[len] = '\n';
	    line[len + 1] = '\0';
	}
#if defined _WIN32 && ! defined __CYGWIN__
	if (line[0] == '.')
	    send(ofp, ".", 1, 0);
	send(ofp, line, strlen(line), 0);
#else /* not _WIN32 */
	if (line[0] == '.')
	    fputc('.', ofp);
	fputs(line, ofp);
	if (istty)
	    fflush(ofp);
#endif /* _WIN32 */
    }

    if (ifp != stdin)
	fclose(ifp);
}

/*
 * send_chasenrc
 */
#if defined _WIN32 && ! defined __CYGWIN__
static void
send_chasenrc(SOCKET ifp, SOCKET ofp)
#else
static void
send_chasenrc(FILE * ifp, FILE * ofp)
#endif /* _WIN32 */
{
    /*
     * If chasenrc file is "*", don't read it 
     */
    if (!strcmp(cha_get_rcpath(), "*"))
	return;

#if defined _WIN32 && ! defined __CYGWIN__
    send(ofp, "RC\n", 3, 0);
    fp_copy(ofp, cha_fopen_rcfile());
    send(ofp, ".\n", 2, 0);
#else /* not _WIN32 */
    fputs("RC\n", ofp);
    fp_copy(ofp, cha_fopen_rcfile());
    fputs(".\n", ofp);
    fflush(ofp);
#endif /* _WIN32 */

    check_status(ifp, NULL);
}

/*
 * escape_string
 */
static char *
escape_string(char *dst_str, char *src_str)
{
    char *src, *dst;

    dst = dst_str;
    for (src = src_str; *src; src++) {
	if (*src == ' ' || *src == '"' || *src == '\'' || *src == '\\')
	    *dst++ = '\\';
	*dst++ = *src;
    }
    *dst = '\0';

    return dst_str;
}

/*
 * getopt_client
 */
static char *
getopt_client(char **argv)
{
    static char option[CHA_COMM_LINE_MAX];
    static char arg[CHA_COMM_LINE_MAX];
    char *op;
    int c;

    op = option;

    Cha_optind = 0;
    while ((c = cha_getopt_chasen(argv, stderr)) != EOF) {
	switch (c) {
	case 'a':
	case 's':
	case 'D':
	case 'P':
	    break;
	default:
	    if (Cha_optarg != NULL)
		sprintf(op, "-%c %s ", c, escape_string(arg, Cha_optarg));
	    else
		sprintf(op, "-%c ", c);
	    op += strlen(op);
	}
    }

    return option;
}

#if defined _WIN32 && ! defined __CYGWIN__
DWORD WINAPI
fork_and_gets(LPVOID s, FILE * output)
{
    SOCKET ifp;
#else
static int
fork_and_gets(FILE * ifp, FILE * output)
{
#endif /* _WIN32 */

    int pid;
    int istty;
    char line[CHA_INPUT_SIZE];

#if defined _WIN32 && ! defined __CYGWIN__
    ifp = (SOCKET) s;
#else /* not _WIN32 */
    if ((pid = fork()) < 0) {
	cha_perror("fork");
	return -1;
    }

    if (pid)
	return pid;
#endif /* _WIN32 */

    /*
     * child process 
     * if output is stdout or not 
     */
    istty = output == stdout && isatty(fileno(stdout));

    check_status(ifp, "error");

    while (fgets(line, sizeof(line), ifp) != NULL) {
	if (line[0] == '.' &&
	    (line[1] == '\n' || (line[1] == '\r' && line[2] == '\n')))
	    break;
#if defined _WIN32 && ! defined __CYGWIN__
	euc2sjis(line);
#endif /* _WIN32 */
	fputs(line[0] == '.' ? line + 1 : line, output);
	if (istty)
	    fflush(output);
    }
#if ! (defined _WIN32 && ! defined __CYGWIN__)
    fclose(ifp);
    exit(0);
#endif /* not _WIN32 */
}

/*
 * close_connection
 */
#if defined _WIN32 && ! defined __CYGWIN__
static void
close_connection(int pid, SOCKET ofp)
#else
static void
close_connection(int pid, FILE * ofp)
#endif /* _WIN32 */
{
    int status;

#if defined _WIN32 && ! defined __CYGWIN__
    send(ofp, ".\nQUIT\n", 7, 0);
#else /* not _WIN32 */
    fputs(".\nQUIT\n", ofp);
    fclose(ofp);
    while (wait(&status) != pid);
#endif /* _WIN32 */
}

/*
 * connect_server
 */
#if defined _WIN32 && ! defined __CYGWIN__
static SOCKET
open_connection(char *server, unsigned short port)
#else
static int
open_connection(char *server, unsigned short port)
#endif /* _WIN32 */
{
#if defined _WIN32 && ! defined __CYGWIN__
    SOCKET sfd;
#else
    int sfd;
#endif /* _WIN32 */
    struct sockaddr_in sin;
    struct hostent *host;
#if defined _WIN32 && ! defined __CYGWIN__
    WORD wVersionRequested;
    WSADATA wsaData;
    int err;

    wVersionRequested = MAKEWORD(1, 1);
    err = WSAStartup(wVersionRequested, &wsaData);
#endif /* _WIN32 */

#if defined _WIN32 && ! defined __CYGWIN__
    if ((sfd = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET) {
#else
    if ((sfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
#endif /* _WIN32 */
	cha_perror("socket");
	return -1;
    }

    memset(&sin, 0, sizeof(sin));
    sin.sin_port = htons(port);

    if ((host = gethostbyname(server)) != NULL) {
	memcpy(&sin.sin_addr.s_addr, host->h_addr, host->h_length);
	sin.sin_family = host->h_addrtype;
    } else if ((sin.sin_addr.s_addr = inet_addr(server)) !=
	       (unsigned long) -1) {
	sin.sin_family = AF_INET;
    } else {
	cha_exit(-1, "Can't get address: %s\n", server);
	return -1;
    }

    if (connect(sfd, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
	cha_perror("connect");
#if defined _WIN32 && ! defined __CYGWIN__
	closesocket(sfd);
#else
	close(sfd);
#endif /* _WIN32 */
	return -1;
    }

    return sfd;
}

/*
 * chasen_client
 *
 * return code: exit code
 */
int
chasen_client(char **argv, FILE * output, char *server, int port)
{
    char *option;
#if defined _WIN32 && ! defined __CYGWIN__
    SOCKET pid, sfd;
    SOCKET ifp, ofp;
    char tmp[512];

    HANDLE hThrd;
    DWORD threadId;
#else /* not _WIN32 */
    int pid, sfd;
    FILE *ifp, *ofp;
#endif /* _WIN32 */

    /*
     * open connection to server 
     */
    if ((sfd = open_connection(server, port)) < 0)
	return 1;

#if defined _WIN32 && ! defined __CYGWIN__
    ifp = sfd;
    ofp = sfd;
#else /* not _WIN32 */
    ifp = fdopen(sfd, "r");
    ofp = fdopen(sfd, "w");
#endif /* _WIN32 */
    check_status(ifp, "connection error");

    send_chasenrc(ifp, ofp);

    /*
     * send RUN command with option 
     */
    option = getopt_client(argv);
    argv += Cha_optind;
#if defined _WIN32 && ! defined __CYGWIN__
    sprintf(tmp, "RUN %s\n", option);
    send(ofp, tmp, strlen(tmp), 0);

    hThrd =
	CreateThread(NULL, 0, fork_and_gets, (LPVOID) ifp, 0, &threadId);

#else /* not _WIN32 */
    fprintf(ofp, "RUN %s\n", option);

    if ((pid = fork_and_gets(ifp, output)) < 0)
	return 1;

#endif /* _WIN32 */

    if (*argv == NULL)
	fp_copy(ofp, stdin);
    else
	for (; *argv; argv++)
	    fp_copy(ofp, cha_fopen(*argv, "r", 1));

    close_connection(pid, ofp);
#if defined _WIN32 && ! defined __CYGWIN__
    WaitForSingleObject(hThrd, INFINITE);

    closesocket(ofp);
    closesocket(sfd);
#else
    close(sfd);
#endif /* _WIN32 */

    return 0;
}

#endif				/* !NO_SERVER */
