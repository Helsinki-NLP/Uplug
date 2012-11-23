/*
 *  SUFARY --- Suffix Array 検索のためのライブラリ
 *  sufary.h - SUFARYライブラリヘッダファイル
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

/* コマンドの戻り値 */
typedef enum eresult_{
    CONT,
    FAIL,
    EXIT,
    _ERROR
} eresult;

/* エラーコード */
typedef enum eerror_ {
    _NOERROR,
    COMMAND,
    MEMORY,
    FILEIN,
    FILEOUT,
    STRUCTURE,
    UNKNOWN
} eerror;

/* SUFARY構造体 */
typedef struct {
    eerror ee;      /* グローバルエラーコードを保持 */
    long arraysize; /* Array の大きさ */
    long left;  /* 検索範囲の左端(範囲の内側を指す)  旧 g_bottom */
    long right;     /* 検索範囲の右端(範囲の内側を指す)  旧 g_top */
    off_t txtsz;    /* テキストファイルのサイズ */
    off_t arysz;    /* アレイファイルのサイズ */
    void *txtmap; /* テキストファイルのマップアドレス */
    void *arymap; /* アレイファイルのマップアドレス */
} SUFARY;

/* プロトタイプ宣言 汎用ルーチン */
/*** select.c ***/
char **sa_common_prefix_search(SUFARY*, char*, int, char**);

/*** chfile.c ***/
SUFARY *sa_openfiles(char*, char*);
void sa_closefiles(SUFARY*);

#endif /* __SUFARY_H__ */
