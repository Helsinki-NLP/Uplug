/*********************************************************/
/*                        Utility                        */
/*                                                       */
/*                   (22 December 1992)                  */
/*  by Takehito Utsuro (utsuro@pine.kuee.kyoto-u.ac.jp)  */
/*     Yasuharu Den    (den@forest.kuee.kyoto-u.ac.jp)   */
/*   Dept. of Electrical Engineering, Kyoto University   */
/*********************************************************/

%  Needs append/3 from library lists.
:- use_module(library(lists), [append/3]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Basic Predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   all_concat_atoms(+List, ?NewAtom)
%   リスト List ないのアトムをすべて連接したものを NewAtom
%   とする．
%
all_concat_atoms([Atom], NewAtom) :- !, NewAtom = Atom.
all_concat_atoms([Atom1|Rest], NewAtom) :-
	name(Atom1, Name1),
	all_concat_atoms(Rest, Name1, Name),
	name(Atom, Name),
	!, NewAtom = Atom.

all_concat_atoms([], Name, Name) :- !.
all_concat_atoms([Atom2|Rest], Name1, Name) :-
	name(Atom2, Name2),
	append(Name1, Name2, Name3),
	!, all_concat_atoms(Rest, Name3, Name).
