%**********************************************************************
% Interface for ChaSen 1.5 (JUMAN2.0ÉÕÂ°ÈÇ¸ß´¹)
%
% Date: Jul 8, 1997
%   by Osamu Imaichi <osamu-im@is.aist-nara.ac.jp>
%   Graduate School of Information Science, NAIST
%**********************************************************************
% NOTE: This program works on SICStus Prolog Release 3 or later.
:- module(juman, [
	juman_start_server/0,
	juman_kill_server/0,
	juman_start_client/0,
	juman_kill_client/0,
	juman/0,
	juman/1,
	juman/3
	       ]).
:- use_module(library(chasen)).
%----------------------------------------------------------------------
% JUMAN2.0ÉÕÂ°ÈÇ¸ß´¹
%----------------------------------------------------------------------
juman_start_server :- true.
juman_kill_server :- true.
juman_start_client :- chasen:cha_open.
juman_kill_client :- chasen:cha_close.
juman :- chasen:cha.
juman(Sentence) :- chasen:cha(Sentence).
juman(Sentence, MorphList, Cost) :- chasen:cha(Sentence, MorphList, Cost).
% Handling morph data
get_ID(Morph, ID) :- chasen:get_ID(Morph, ID).
get_from(Morph, From) :- chasen:get_from(Morph, From).
get_to(Morph, To) :- chasen:get_to(Morph, To).
get_score(Morph, Score) :- chasen:get_cost(Morph, Score).
get_midasi(Morph, Md) :- chasen:get_midasi(Morph, Md).
get_yomi(Morph, Ym) :- chasen:get_yomi(Morph, Ym).
get_kihon(Morph, Kh) :- chasen:get_kihon(Morph, Kh).
get_hinsi(Morph, Hn) :- chasen:get_hinsi(Morph, Hn).
get_katuyo_type(Morph, KT) :- chasen:get_katuyo_type(Morph, KT).
get_katuyo_form(Morph, KF) :- chasen:get_katuyo_form(Morph, KF).
get_imi(Morph, Imi) :- chasen:get_imi(Morph, Imi).
get_preIDL(Morph, PreIDL) :- chasen:get_preIDL(Morph, PreIDL).
% Print morpheme list
print_morphs(MorphList, From) :- chasen:print_morphs(MorphList, From).
