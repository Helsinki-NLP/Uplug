#!/usr/bin/perl
#---------------------------------------------------------------------------
# index.pl - a corpus indexer using CWB
#
#---------------------------------------------------------------------------
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#---------------------------------------------------------------------------

require 5.002;
use strict;

use CGI qw/:standard/;
use FindBin qw($Bin);
# use lib "$Bin/../lib";
use lib "/home/staff/joerg/html_bin/uplug";
use Uplug::Web::User;
use Uplug::Web::Corpus;
use Uplug::Web;


#BEGIN { 
#    use CGI::Carp qw(carpout);
#    open L, ">>/tmp/uplugWeb.log" || die ("could not open log\n");
#    carpout(*L);
#}
#`chmod g+w /corpora/OPUS/uplug2/joerg\@stp.ling.uu.se/ini/uplugUserStreams.ini`;

if (defined &url_param('action')){&param('action',&url_param('action'));}
if (defined &url_param('corpus')){&param('corpus',&url_param('corpus'));}
if (defined &url_param('owner')){&param('owner',&url_param('owner'));}

my $user = &remote_user;
my $action = param('action');
my $corpus = param('corpus');
my $owner = param('owner');

my $url=url();
my $query=url(-query=>1);

######################################################################

print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug - Corpus Index',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$CSS},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));


print &h2("UplugWeb - Corpus Index");

print "tasks: ",&Uplug::Web::ActionLinks($url,'query','add'),&p();
print 'Select "query" to reset the corpus query form!',&br();
print 'Select "add" to create a new CWB index!',&br();
print &hr;

if ($action eq 'add'){
    if ($corpus){
	my $srcenc=param('srcenc');
	my $trgenc=param('trgenc');
	if (&UplugProcess::MakeIndexerProcess($user,$corpus,$srcenc,$trgenc)){
	    print "Job added to process queue!",&p();
	}
#	print &Uplug::Web::ShowProcessInfo($url,$user);
    }
#    else{
#	print &Uplug::Web::CorpusIndexerForm($user);
#    }
}
elsif (param('query')){
    my $lang = param('lang');
    my $cqp = param('query');
    my @alg = param('alg');
    my $style = param('style');
    print &Uplug::Web::CorpusQuery($user,$owner,$corpus,$lang,
				 $cqp,\@alg,$style);
}
else{
    my $lang = param('lang');
    my $alg = param('alg');
    print &Uplug::Web::CorpusQueryForm($user,$owner,$corpus,$lang,$alg);
}

print &end_html;

#------------------------------------------------------------

