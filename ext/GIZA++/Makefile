.SUFFIXES: .out .o .c .e .r .f .y .l .s .p .C .cc .alpha2o .pentiumo .sgio .alphao

INSTALLDIR ?= /usr/local/bin/

CXX = g++

CFLAGS = $(CFLAGS_GLOBAL) -Wall -W -Wno-deprecated
CFLAGS_OPT = $(CFLAGS) -O2 -DNDEBUG -DWORDINDEX_WITH_4_BYTE
CFLAGS_PRF = $(CFLAGS) -O2 -pg -DNDEBUG -DWORDINDEX_WITH_4_BYTE
CFLAGS_DBG = $(CFLAGS) -g -DDEBUG -DWORDINDEX_WITH_4_BYTE
CFLAGS_NRM = $(CFLAGS) -DWORDINDEX_WITH_4_BYTE
CFLAGS_VDBG = $(CFLAGS) -g -DDEBUG -DWORDINDEX_WITH_4_BYTE -DVDEBUG
SRC = *.cc
TYPE = 
LDFLAGS = 
include Makefile.src

OBJ_DIR_PRF = profile/
OBJ_DIR_OPT = optimized/
OBJ_DIR_DBG = debug/
OBJ_DIR_VDBG = vdebug/
OBJ_DIR_NRM = norm/
OBJ_OPT2 = ${SRC2:%.cc=$(OBJ_DIR_OPT)%.o}
OBJ_OPT = ${SRC:%.cc=$(OBJ_DIR_OPT)%.o}
OBJ_DBG = ${SRC:%.cc=$(OBJ_DIR_DBG)%.o}
OBJ_VDBG = ${SRC:%.cc=$(OBJ_DIR_VDBG)%.o}
OBJ_NRM = ${SRC:%.cc=$(OBJ_DIR_NRM)%.o}
OBJ_PRF = ${SRC:%.cc=$(OBJ_DIR_PRF)%.o}
OBJ_DIR = 
DATE = `date +%d-%m-%Y`

opt: GIZA++ snt2plain.out plain2snt.out

GIZA++: $(OBJ_DIR_OPT) $(OBJ_OPT) 
	$(CXX) $(CFLAGS_OPT) $(OBJ_OPT) -o GIZA++ $(LDFLAGS)

prf: GIZA++.prf

GIZA++.prf: $(OBJ_DIR_PRF) $(OBJ_PRF) 
	$(CXX) $(CFLAGS_PRF) $(OBJ_PRF) -o GIZA++.prf $(LDFLAGS)

dbg: GIZA++.dbg

GIZA++.dbg: $(OBJ_DIR_DBG) $(OBJ_DBG) 
	$(CXX) $(CFLAGS_DBG) $(OBJ_DBG) -o GIZA++.dbg $(LDFLAGS)

vdbg: GIZA++.vdbg

GIZA++.vdbg: $(OBJ_DIR_VDBG) $(OBJ_VDBG) 
	$(CXX) $(CFLAGS_VDBG) $(OBJ_VDBG) -o GIZA++.vdbg $(LDFLAGS)

nrm: GIZA++.nrm 

GIZA++.nrm: $(OBJ_DIR_NRM) $(OBJ_NRM) 
	$(CXX) $(CFLAGS_NRM) $(OBJ_NRM) -o GIZA++.nrm $(LDFLAGS)

all: dbg opt nrm prf 

$(OBJ_DIR_PRF): $(OBJ_DIR)
	-mkdir $(OBJ_DIR_PRF)

$(OBJ_DIR_OPT): $(OBJ_DIR)
	-mkdir $(OBJ_DIR_OPT)

$(OBJ_DIR_DBG): $(OBJ_DIR)
	-mkdir $(OBJ_DIR_DBG)

$(OBJ_DIR_VDBG): $(OBJ_DIR)
	-mkdir $(OBJ_DIR_VDBG)

$(OBJ_DIR_NRM): $(OBJ_DIR)
	-mkdir $(OBJ_DIR_NRM)

$(OBJ_DIR):
	-mkdir $(OBJ_DIR)

$(OBJ_DIR_DBG)%.o: %.cc
	$(CXX)  $(CFLAGS_DBG)  -c $< -o $@

$(OBJ_DIR_VDBG)%.o: %.cc
	$(CXX)  $(CFLAGS_VDBG)  -c $< -o $@

$(OBJ_DIR_NRM)%.o: %.cc
	$(CXX)  $(CFLAGS_NRM)  -c $< -o $@

$(OBJ_DIR_PRF)%.o: %.cc
	$(CXX)  $(CFLAGS_PRF) -c $< -o $@

$(OBJ_DIR_OPT)%.o: %.cc
	$(CXX)  $(CFLAGS_OPT)  -c $< -o $@

iinstall: opt prf dbg
	-mkdir $(INSTALLDIR)/$(ARCH)
	-cp GIZA++ $(INSTALLDIR)/GIZA++
	-cp GIZA++.prf $(INSTALLDIR)/GIZA++.prf
	-cp GIZA++.dbg $(INSTALLDIR)/GIZA++.dbg

install: opt 
	-mkdir $(INSTALLDIR)
	-cp GIZA++ $(INSTALLDIR)/GIZA++

ci:
	ci -mautomaticMessage -u *.cc *.h *.C Makefile 

clean:
	-rm $(ARCH)/profile/*.o $(ARCH)//optimized/*.o $(ARCH)//debug/*.o $(ARCH)//norm/*.o
	-rmdir $(ARCH)/profile $(ARCH)//optimized $(ARCH)//debug $(ARCH)//norm
	-rmdir $(ARCH)
	-rm snt2plain.out plain2snt.out snt2cooc.out


backup: clean
	tar cf - . | gzip -9 > ../GIZA++src.tar.gz

depend: depend_CLEAN dependencies

depend_CLEAN:
	rm dependencies

dependencies:
	@(echo "#Automatically generated dependecy list" >>  dependencies ;\
	$(CXX) -Wno-deprecated -MM *.cc $(CFLAGS_OPT) | perl -e 'while(<>){s?^([^\:]+\.o:)?$(OBJ_DIR_OPT)\1?g;print;}'>>  dependencies)
	@(echo "#Automatically generated dependecy list" >>  dependencies ;\
	$(CXX) -Wno-deprecated -MM *.cc $(CFLAGS_DBG) | perl -e 'while(<>){s?^([^\:]+\.o:)?$(OBJ_DIR_DBG)\1?g;print;}'>>  dependencies)
	@(echo "#Automatically generated dependecy list" >>  dependencies ;\
	$(CXX) -Wno-deprecated -MM *.cc $(CFLAGS_VDBG) | perl -e 'while(<>){s?^([^\:]+\.o:)?$(OBJ_DIR_VDBG)\1?g;print;}'>>  dependencies)
	@(echo "#Automatically generated dependecy list" >>  dependencies ;\
	$(CXX) -Wno-deprecated -MM *.cc $(CFLAGS_NRM) | perl -e 'while(<>){s?^([^\:]+\.o:)?$(OBJ_DIR_NRM)\1?g;print;}'>>  dependencies)
	@(echo "#Automatically generated dependecy list" >>  dependencies ;\
	$(CXX) -Wno-deprecated -MM *.cc $(CFLAGS_PRF) | perl -e 'while(<>){s?^([^\:]+\.o:)?$(OBJ_DIR_PRF)\1?g;print;}'>>  dependencies)

-include dependencies

snt2plain.out: snt2plain.cc
	$(CXX) -O2 -Wno-deprecated -W -Wall snt2plain.cc -o snt2plain.out

plain2snt.out: plain2snt.cc
	$(CXX) -O2 -Wno-deprecated -W -Wall plain2snt.cc -o plain2snt.out

snt2cooc.out: snt2cooc.cc
	$(CXX) -g -W -Wall -Wno-deprecated snt2cooc.cc -o snt2cooc.out

