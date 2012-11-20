/* 
 * chasen.h - header file for ChaSen library
 *
 * $Id$
 */

#ifndef __CHASEN_H__
#define __CHASEN_H__

#ifdef __cplusplus
extern "C" {
#endif
   
#ifdef _WIN32
#  ifdef CHASEN_DLL_EXPORT
#    define CHASEN_DLL_EXTERN    __declspec(dllexport)
#  else
#    ifdef  CHASEN_DLL_IMPORT
#      define CHASEN_DLL_EXTERN  __declspec(dllimport)
#    endif
#  endif
#endif
   
#ifndef CHASEN_DLL_EXTERN
#  define CHASEN_DLL_EXTERN extern
#endif 

/* variables */
CHASEN_DLL_EXTERN int Cha_optind;

/* functions */
CHASEN_DLL_EXTERN int   chasen_getopt_argv       (char**, FILE*);
CHASEN_DLL_EXTERN int   chasen_fparse            (FILE*, FILE*);
CHASEN_DLL_EXTERN int   chasen_sparse            (char*, FILE*);
CHASEN_DLL_EXTERN char *chasen_fparse_tostr      (FILE*);
CHASEN_DLL_EXTERN char *chasen_sparse_tostr      (char*);
   
#ifdef __cplusplus
}
#endif   

#endif /* __CHASEN_H__ */
