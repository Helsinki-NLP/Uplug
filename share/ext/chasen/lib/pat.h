/*
 * $Id$
 */

#ifndef __PAT_H__
#define __PAT_H__

#include "config.h"

#ifdef HAVE_UNISTD_H
#include <sys/types.h>
#endif

#define SIKII_BIT 16  /* which bit is word segmentation? (8 or 16) */


/* list for indexes */
typedef struct __pat_index_list {
  struct __pat_index_list *next;  /* next */
  long index;                     /* index to file */
} pat_index_list;

/* node of patricia tree */
typedef struct pat_node {
  pat_index_list il;              /* list of index */
  short checkbit;                 /* which bit should be checked? */
  struct pat_node *right;         /* right node */
  struct pat_node *left;          /* left node */
} pat_node;

/* patricia tree */
typedef struct __pat_h {
    pat_node *root;               /* pointer to the root node */ 
    void *_map;                   /* pointer of the mapped text */
    off_t _size;                  /* size of the mapped text */
} pat_t;

/* 
 * functions in patfile.c 
 */

/* 
    pat_open  -- open the patricia tree
    parameter: pat_open(char *textfile, char *patfile)
    return:    pat_t*
*/
pat_t *pat_open(char*, char*);

/* 
    pat_load  -- load the patricia tree
    parameter: pat_load(pat_t * pat, char *patfile)
    return:    none
*/
void pat_load(pat_t*, char*);

/* 
    pat_save  -- save the patricia tree
    parameter: pat_save(pat_t * pat, char *patfile)
    return:    none
*/
void pat_save(pat_t*, char*);

/* 
    pat_text_reopen -- reopen textfile
    parameter: pat_text_reopen(pat_t * pat, char *textfile)
    return:    none
*/
void pat_text_reopen(pat_t*, char*);

/* 
    pat_text_size -- return the size of text file
    parameter: pat_text_size(pat_t * pat)
    return:    the size of text file
*/
#define pat_text_size(pat) ((pat)->_size)

/* 
    pat_get_text -- get text
    parameter: pat_get_text(pat_t * pat, position)
    return:    (char *) string
*/
#define pat_get_text(pat, pos) ((char *)((pat)->_map + (pos)))

/* 
 * functions in pat.c
 */
/* 
    pat_search -- search the key in patricia tree exactly
    parameter: pat_search(pat_t * pat, char *key, char **result)
    return:    pointer to a node which the search ended
*/
pat_node *pat_search(pat_t*, char*, char**);

/* 
    pat_search_exact -- search the key in patricia tree
    parameter: pat_search_exact(pat_t * pat, char *key, char **result)
    return:    pointer to a node which the search ended
*/
pat_node *pat_search_exact(pat_t*, char*, char**);

/* 
    pat_insert -- insert data for patricia tree
    parameter: pat_insert(pat_t * pat, char *line, long index)
    return:    none
*/
void pat_insert(pat_t *, char*, long);

/* 
 * functions in patfile.c
 */
/* 
    pat_malloc_node -- malloc for pat_node
    parameter: none
    return:    pat_node
*/
pat_node *pat_malloc_node(void);

/* 
    pat_malloc_index_list -- malloc for pat_index_list
    parameter: none
    return:    pat_index_list
*/
pat_index_list *pat_malloc_index_list(void);

/*
 * 
 * pat --- パトリシア木の探索と挿入
 * 
 * 作者: たつを(tatuo-y@is.aist-nara.ac.jp)
 * 
 * 目的: パトリシア木の探索と挿入を行う
 * 
 * 参考文献: 
 *   アルゴリズムの理解のために文献[1]を参照した。C言語での実装は
 *   文献[2]のプログラムを参考にした。
 * [1] R. Sedgewick 著 野下浩平、星守、佐藤創、田口東 共訳
 *     アルゴリズム (Algorithms) 原書第2版 第2巻 探索・文字列・計算幾何
 *     近代科学社,1992. (B195-2,pp.68-72)
 * [2] 島内剛一、有澤誠、野下浩平、浜田穂積、伏見正則 編集委員
 *     アルゴリズム辞典
 *     共立出版株式会社,1994. (D74,pp.624-625)
 * 
 * 履歴:
 *   1996/04/09  動く! (ただし扱えるデータの最大長は8bit。[2]を模倣。)
 *           10  出力ルーチンを再帰に改良。文字列データ対応(最大長無制限)。
 *           30  セーブ/ロード機能。ノードのデータ構造にID番号を追加(仮)。
 *         5/06  部分木の全データ出力処理。
 *         6/11  ChaSenの辞書引き用に改造．
 *           21  連想配列を導入(INDEXをキャッシュする)
 *         7/01  複数の辞書ファイル(パト木)から検索できるようにした．
 * 
 * メモ: ChaSenの辞書引きに利用する
 * 
 */
#endif /* __PAT_H__ */
