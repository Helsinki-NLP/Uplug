/*
 *  SUFARY --- Suffix Array �����Τ���Υ饤�֥��
 *  sufary.h - SUFARY�饤�֥��إå��ե�����
 *
 * $Id$
 */

#ifndef __SUFARY_H__
#define __SUFARY_H__

#include "config.h"

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif

#ifndef KEYWORD_MAX_LENGTH
#define KEYWORD_MAX_LENGTH 5000
#endif

/* ���ޥ�ɤ������ */
typedef enum eresult_{
    CONT,
    FAIL,
    EXIT,
    _ERROR
} eresult;

/* ���顼������ */
typedef enum eerror_ {
    _NOERROR,
    COMMAND,
    MEMORY,
    FILEIN,
    FILEOUT,
    STRUCTURE,
    UNKNOWN
} eerror;

/* SUFARY��¤�� */
typedef struct {
    eerror ee;      /* �����Х륨�顼�����ɤ��ݻ� */
    long arraysize; /* Array ���礭�� */
    long left;  /* �����ϰϤκ�ü(�ϰϤ���¦��ؤ�)  �� g_bottom */
    long right;     /* �����ϰϤα�ü(�ϰϤ���¦��ؤ�)  �� g_top */
    off_t txtsz;    /* �ƥ����ȥե�����Υ����� */
    off_t arysz;    /* ���쥤�ե�����Υ����� */
    void *txtmap; /* �ƥ����ȥե�����Υޥåץ��ɥ쥹 */
    void *arymap; /* ���쥤�ե�����Υޥåץ��ɥ쥹 */
} SUFARY;

/* �ץ�ȥ�������� ���ѥ롼���� */
/*** select.c ***/
char **sa_common_prefix_search(SUFARY*, char*, int, char**);

/*** chfile.c ***/
SUFARY *sa_openfiles(char*, char*);
void sa_closefiles(SUFARY*);

#endif /* __SUFARY_H__ */
