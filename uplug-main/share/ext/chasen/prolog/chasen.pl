%**********************************************************************
% Interface for ChaSen 1.5
% 
% Date: Jul 9, 1997
%   by Osamu Imaichi <osamu-im@is.aist-nara.ac.jp>
%   Graduate School of Information Science, NAIST
%**********************************************************************
% NOTE: This program works on SICStus Prolog Release 3 or later.
:- module(chasen, [
	cha_version/0,
	cha_open/0,
	cha_close/0,
	chatty/0,
	cha/0,
	cha/1,
	cha/3,
	cha_show_option/0,
	cha_print_form/1,
	cha_print_mode/1
	       ]).
:- ensure_loaded([jinput,utils]).
:- use_module(library(system)).
:- use_module(library(lists), [last/2,append/3,member/2]).
%----------------------------------------------------------------------
% ChaSen default path and option
%----------------------------------------------------------------------
cha_default_path('/usr/local/bin/chasen').
cha_default_option(d). % don't change this option.
%----------------------------------------------------------------------
% ChaSen option
%----------------------------------------------------------------------
:- dynamic 
	'$cha_print_form'/1,
	'$cha_print_mode'/1.
'$cha_print_form'(e).  % f(formatted)/e(entire)/s(simple)
'$cha_print_mode'(m).  % m(all morphemes)/b(best path)
%----------------------------------------------------------------------
% show ChaSen option
%----------------------------------------------------------------------
cha_show_option :-
	'$cha_print_form'(PrintForm),
	'$cha_print_mode'(Mode),
	format(user_error, "Current print form is ~w. \n", [PrintForm]), 
	format(user_error, "  You can change this option", []),
	format(user_error, " using cha_print_form/1.~n", []),
	format(user_error, "  Following options is available.~n", []),
	format(user_error, "    f(formatted)/e(entire)/s(simple)~n", []),
	format(user_error, "Current print mode is ~w. \n", [Mode]),
	format(user_error, "  You can change this option", []),
	format(user_error, " using cha_print_mode/1.~n", []),
	format(user_error, "  Following options is available.~n", []),
	format(user_error, "    m(all morphemes)/b(best path)~n", []).
%----------------------------------------------------------------------
% change ChaSen option
%----------------------------------------------------------------------
cha_print_form(ChaPrintForm) :-
	var(ChaPrintForm),
	format(user_error, "Please specify the option.", []),
	format(user_error, "  Following options is available.~n", []),
	format(user_error, "    f(formatted)/e(entire)/s(simple)~n", []).
cha_print_form(ChaPrintForm) :- 
	lists:member(ChaPrintForm, [f,e,s]),
	retract('$cha_print_form'(_)),
	asserta('$cha_print_form'(ChaPrintForm)).
cha_print_form(ChaPrintForm) :- 
	format(user_error, "~w is not available.~n", [ChaPrintForm]),
	format(user_error, "Following options is available.~n", []),
	format(user_error, "  f(formatted)/e(entire)/s(simple)~n", []).
cha_print_mode(ChaPrintMode) :-
	var(ChaPrintMode),
	format(user_error, "Please specify the option.", []),
	format(user_error, "  Following options is available.~n", []),
	format(user_error, "    m(all morphemes)/b(best path)~n", []).
cha_print_mode(ChaPrintMode) :-
	lists:member(ChaPrintMode, [m,b]),
	retract('$cha_print_mode'(_)),
	asserta('$cha_print_mode'(ChaPrintMode)).
cha_print_mode(ChaPrintMode) :- 
	format(user_error, "~w is not available.~n", [ChaPrintMode]),
	format(user_error, "Following options is available.~n", []),
	format(user_error, "    m(all morphemes)/b(best path)~n", []).
%----------------------------------------------------------------------
% ChaSen Version
%----------------------------------------------------------------------
cha_version('ChaSen version 1.5 (c) 1996-1997 NAIST').
cha_version :-
	cha_version(Version),
	format(user_error, "~`*t ~w ~`*t ~70|~n", [Version]).
%----------------------------------------------------------------------
% ChaSenと接続/切断
%----------------------------------------------------------------------

% cha_open
%   chasenとパイプを通して接続
%
cha_open :- 
	(   user:cha_path(ChaPath) 
	;   cha_default_path(ChaPath)
	),
	cha_default_option(ChaOpt),
	'$cha_print_mode'(Mode),
	absolute_file_name(ChaPath, ChaFullPath),
	all_concat_atoms([ChaFullPath, ' ', '-', ChaOpt, Mode], Command),
	system:exec(Command, [pipe(OutStr), pipe(InStr), null], ChaPid),
	asserta(cha_stream(OutStr, InStr)),
	asserta(cha_pid(ChaPid)).

% cha_close
%   chasenとのパイプを切断
%
cha_close :-
	flush_output,
	cha_stream(OutStr, InStr),
	cha_pid(ChaPid),
	close(OutStr),
	close(InStr),
	retract(cha_stream(OutStr, InStr)),
	retract(cha_pid(ChaPid)),
	system:wait(ChaPid, _).
%----------------------------------------------------------------------
% ChaSen
%----------------------------------------------------------------------

% chatty
%   茶筌システムを実行する(tty版)．
%
chatty :-
	cha_open,
	repeat,
	input_jstring(SentenceList),
	(   SentenceList = end_of_file
	;   name(Sentence, SentenceList),
	    display(Sentence), ttynl,
	    cha(Sentence), ttynl,
	    fail
	),
	cha_close.

% cha
%   茶筌システムを実行する．
%
cha :-
	format(user_error, 'Input file name?  ', []),
	read(InFile),
	format(user_error, 'Output file name? ', []),
	read(OutFile),
	(   InFile = user -> InStr = user_input
	;   open(InFile, read, InStr)
	),
	(   OutFile = user -> OutStr = user_output
	;   open(OutFile, write, OutStr)
	),
	current_input(SaveInput),
	current_output(SaveOutput),
	set_input(InStr),
	set_output(OutStr), !,
	cha_open,
	cha1,
	cha_close,
	set_input(SaveInput),
	set_output(SaveOutput).

cha1 :-
	repeat,
	input_jstring(SentenceList),
	(   SentenceList = end_of_file
	;   name(Sentence, SentenceList),
	    display(Sentence), ttynl,
	    cha(Sentence), ttynl,
	    fail
	).

% cha(+Sentence)
%   入力文 Sentence を形態素解析する．
%
cha(Sentence) :-
	statistics(runtime, _),	
	cha(Sentence, MorphList, Cost),
	TotalCost is Cost//10,
	statistics(runtime, [_, Time]), nl,
	format('total cost = ~D~n', [TotalCost]),
	format('execution time = ~d msec~2n', [Time]),
	print_morphs(MorphList, -1), !.

% cha(+Sentence, -MorphList, -Cost)
%   入力文 Sentence を形態素解析し，形態素のリスト MorphList を返す．
%   Cost は解析のコスト． 
%
cha(Sentence, MorphList, Cost) :-
	cha_stream(OutStr, InStr),
	write(OutStr, Sentence),
	nl(OutStr),
	flush_output(OutStr),
	read(InStr, MorphList),
	last(MorphList, LastMorph),
	get_cost(LastMorph, Cost), !.

%----------------------------------------------------------------------
% Handling morph data
%----------------------------------------------------------------------

% 形態素情報: 
% morph(ID,From,To,Cost,Md,Ym,Kh,Hn0,Hn,KT,KF,Imi,MrphCost,PreCCL,PreIDL)
%
%   ID        識別子
%   From      開始位置
%   To        終了位置
%   Cost      コスト
%   Md        見出し語
%   Ym        読み
%   Kh        基本形
%   Hn0       品詞名
%   Hn        品詞名 (細分類)
%   KT        活用型名
%   KF        活用形名
%   Imi       付加情報
%   MrphCost  形態素コスト
%   PreCCL    前接形態素との連接コストのリスト (Connection Cost List)
%   PreIDL    前接形態素の識別子のリスト (ID List)
%
get_ID(Morph, ID) :- arg(1, Morph, ID).
get_from(Morph, From) :- arg(2, Morph, From).
get_to(Morph, To) :- arg(3, Morph, To).
get_cost(Morph, Cost) :- arg(4, Morph, Cost).
get_midasi(Morph, Md) :- arg(5, Morph, Md).
get_yomi(Morph, Ym) :- arg(6, Morph, Ym).
get_kihon(Morph, Kh) :- arg(7, Morph, Kh).
get_hinsi0(Morph, Hn0) :- arg(8, Morph, Hn0).     
get_hinsi(Morph, Hn) :- arg(9, Morph, Hn).
get_katuyo_type(Morph, KT) :- arg(10, Morph, KT).
get_katuyo_form(Morph, KF) :- arg(11, Morph, KF).
get_imi(Morph, Imi) :- arg(12, Morph, Imi).
get_mrph_cost(Morph, MrphCost) :- arg(13, Morph, MrphCost).
get_preCCL(Morph, PreCCL) :- arg(14, Morph, PreCCL).
get_preIDL(Morph, PreIDL) :- arg(15, Morph, PreIDL).

% print_morphs(+MorphList, +OldFrom)
%   MorphList内の形態素を出力する．
%   OldFromは直前に出力した形態素の開始位置で，行頭の字下げに利用(現在は無
%   効化)． 
%
print_morphs([], _).
print_morphs([Morph|Rest], OldFrom) :-
	get_from(Morph, From),
	(   From = OldFrom -> tab(0)
	;   true
	),
	line_print(Morph),
	!, print_morphs(Rest, From).

line_print(Morph) :-
	'$cha_print_form'(PrintForm),
	get_midasi(Morph, Md),
	get_hinsi(Morph, Hn),
	(   PrintForm = s, 
	    format('~p ~p~n', [Md,Hn])
	;
	    get_hinsi0(Morph, Hn0),
	    get_yomi(Morph, Ym),
	    get_kihon(Morph, Kh),
	    get_katuyo_type(Morph, KT),
	    get_katuyo_form(Morph, KF),
	    get_imi(Morph, Imi),
	    (   PrintForm = e,
		format('~p ~p ~p ~p ~p', [Md,Ym,Kh,Hn0,Hn]),
		(   KT = 0, KF = 0 -> 
		    format(' * *', [])
		;   format(' ~p ~p', [KT,KF])
		),
		(   Imi = '0' ->
		    format(' *~n', [])
		;   format(' ~p~n', [Imi])
		)
	    ;
		name(Md, Midasi),
		name(Ym, Yomi0), append([40|Yomi0], [41], Yomi),
		name(Kh, Kihon),
		name(Hn, Hinsi),
		format('~12s~13s ~10s ~14s', [Midasi,Yomi,Kihon,Hinsi]),
		(   KT = 0, KF = 0 -> true
		;   name(KT, KatuyoType),
		    format(' ~14s ~p', [KatuyoType,KF])
		),
		nl
	    )
	).
