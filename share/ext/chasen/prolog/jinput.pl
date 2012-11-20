/*******************************************************/
/*             Input Routine for Japanese              */
/*                                                     */ 
/*                  (28 December 1992)                 */
/*  by Yuji Matsumoto (matsu@pine.kuee.kyoto-u.ac.jp)  */
/*     Yasuharu Den   (den@forest.kuee.kyoto-u.ac.jp)  */
/*  Dept. of Electrical Engineering, Kyoto University  */
/*******************************************************/

%   input_jstring(-List)
%   全角・半角混じり文字列を読み込んでリスト List に変換する．
%
input_jstring(List) :-
	input_jstring1(List),
	( List == end_of_file -> true
	; zenkaku_space_chk(List)
	).

zenkaku_space_chk([C|R]) :-
	( C \== 161 -> true
	; !,zenkaku_space_chk(R)
	).

input_jstring1(List) :-
	get(C),
	C \== -1,
	!,
	(   jspace(C) -> input_jstring1(List)
	;   jwords(C, List)
	).
input_jstring1(end_of_file).

jwords(C, [C|Tail]) :- jletter(C), !,
	get0(C1),
	jwords(C1, Tail).
jwords(_, []).

%   Charactor Types
jspace(9).   %  9 = "\t"
jspace(32).  % 32 = " "

jletter(C) :- C >= 32, C =< 126.
jletter(C) :- C >= 128.
