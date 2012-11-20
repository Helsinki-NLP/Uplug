/*
 * Big Endian <-> Host byte order converter
 *
 * $Id$
 */

#include "config.h"

#ifndef __HTOBE_H__
#define __HTOBE_H__

#ifndef WORDS_BIGENDIAN
#ifdef HAVE_HTONL
#if HAVE_SYS_PARAM_H
#include <sys/param.h> /* FreeBSD htonl() etc */
#endif /* HAVE_SYS_PARAM_H */
#if HAVE_SYS_TYPES_H
/* At least SunOS4 needs
   to include sys/types.h before netinet/in.h. There have also
   been a problem report for FreeBSD which seems to indicate
   the same dependency on that platform aswell. */
#include <sys/types.h>
#endif /* HAVE_SYS_TYPES_H */
#if HAVE_NETINET_IN_H
#include <netinet/in.h> /* Linux htonl() etc */
#endif /* HAVE_NETINET_IN_H */
#define htobe htonl
#define betoh ntohl
#else /* HAVE_HTONL */
#define htobe __htobe
#define betoh __betoh
#endif /* HAVE_HTONL */
#else /* WORDS_BIGENDIAN */
#define htobe
#define betoh
#endif /* WORDS_BIGENDIAN */
#endif /* __HTOBE_H__ */
