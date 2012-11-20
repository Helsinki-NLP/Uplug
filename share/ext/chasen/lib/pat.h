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
 * pat --- �ѥȥꥷ���ڤ�õ��������
 * 
 * ���: ���Ĥ�(tatuo-y@is.aist-nara.ac.jp)
 * 
 * ��Ū: �ѥȥꥷ���ڤ�õ����������Ԥ�
 * 
 * ����ʸ��: 
 *   ���르�ꥺ�������Τ����ʸ��[1]�򻲾Ȥ�����C����Ǥμ�����
 *   ʸ��[2]�Υץ����򻲹ͤˤ�����
 * [1] R. Sedgewick �� ���ʿ�����顢��ƣ�ϡ��ĸ��� ����
 *     ���르�ꥺ�� (Algorithms) ������2�� ��2�� õ����ʸ���󡦷׻�����
 *     ����ʳؼ�,1992. (B195-2,pp.68-72)
 * [2] �����졢ͭ߷�������ʿ���������ѡ�������§ �Խ��Ѱ�
 *     ���르�ꥺ�༭ŵ
 *     ��Ω���ǳ������,1994. (D74,pp.624-625)
 * 
 * ����:
 *   1996/04/09  ư��! (������������ǡ����κ���Ĺ��8bit��[2]�����)
 *           10  ���ϥ롼�����Ƶ��˲��ɡ�ʸ����ǡ����б�(����Ĺ̵����)��
 *           30  ������/���ɵ�ǽ���Ρ��ɤΥǡ�����¤��ID�ֹ���ɲ�(��)��
 *         5/06  ��ʬ�ڤ����ǡ������Ͻ�����
 *         6/11  ChaSen�μ�������Ѥ˲�¤��
 *           21  Ϣ�������Ƴ��(INDEX�򥭥�å��夹��)
 *         7/01  ʣ���μ���ե�����(�ѥ���)���鸡���Ǥ���褦�ˤ�����
 * 
 * ���: ChaSen�μ�����������Ѥ���
 * 
 */
#endif /* __PAT_H__ */
