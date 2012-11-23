%**********************************************************************
% User definition file for ChaSen 1.5
% 
% Date: Jul 9, 1997
%   by Osamu Imaichi <osamu-im@is.aist-nara.ac.jp>
%   Graduate School of Information Science, NAIST
%**********************************************************************

:- asserta(library_directory('~/nltools/chasen/prolog')).
:- use_module(library(chasen)).

%----------------------------------------------------------------------
% JUMAN path and option
%----------------------------------------------------------------------
cha_path('~/nltools/chasen/chasen/chasen').
:- cha_print_form(e). % f(formatted)/e(entire)/s(simple)
:- cha_print_mode(m). % m(all morphemes)/b(best path)
