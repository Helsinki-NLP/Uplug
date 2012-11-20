/*
 * mmap.c - library for mmap
 *
 * Copyright (C) 2000, 2001, 
 *                            Nara Institute of Science and Technology
 *                           
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *      This product includes software developed by Nara Institute of 
 *      Science and Technology.
 * 4. The name Nara Institute of Science and Technology may not be used to
 *    endorse or promote products derived from this software without specific
 *    prior written permission.
 *    
 *
 * THIS SOFTWARE IS PROVIDED BY Nara Institute of Science and Technology 
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
 * PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE Nara Institute
 * of Science and Technology BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id$
 */

#include "config.h"

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif

#ifdef __MINGW32__
#undef HAVE_MMAP
#endif
#ifdef HAVE_MMAP
#include <sys/mman.h>
#endif

#if ! defined _WIN32 && ! defined __CYGWIN__
#define O_BINARY 0
#endif

#ifndef HAVE_MMAP
#define PROT_WRITE  0
#define PROT_READ   0
#endif

#include "chadic.h"

static off_t
mmap_file(char *filename, void **map, int prot)
{
    int fd;
    int flag = O_RDONLY;
    struct stat st;
    off_t size;

    if ((prot & PROT_WRITE) != 0)
	flag = O_RDWR;
	
    if ((fd = open(filename, flag)) < 0)
	cha_exit_perror(filename);
    if (fstat(fd, &st) < 0)
	cha_exit_perror(filename);
    size = st.st_size;
#ifdef HAVE_MMAP
    if ((*map = mmap((void *) 0, size, prot, MAP_SHARED, fd, 0))
	== MAP_FAILED) {
	cha_exit_perror(filename);
    }
#else
    *map = cha_malloc(size);
    if (read(fd, *map, size) < 0)
	cha_exit_perror(filename);
#endif
    close(fd);

    return size;
}

off_t
cha_mmap_file(char *filename, void **map)
{
    return mmap_file(filename, map, PROT_READ);
}

off_t
cha_mmap_file_w(char *filename, void **map)
{
    return mmap_file(filename, map, PROT_READ | PROT_WRITE);
}

void
cha_munmap_file(void *map, off_t size)
{
#ifdef HAVE_MMAP
    munmap(map, size);
#else
    cha_free(map);
#endif
}
