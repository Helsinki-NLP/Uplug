#!/usr/bin/perl
#---------------------------------------------------------------------------
# index.pl - a corpus indexer using CWB
#
#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------

require 5.002;
use strict;

use CGI qw/:standard/;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use UplugUser;
use UplugCorpus;
use UplugWeb;


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

print "tasks: ",&UplugWeb::ActionLinks($url,'query','add'),&p();
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
#	print &UplugWeb::ShowProcessInfo($url,$user);
    }
#    else{
#	print &UplugWeb::CorpusIndexerForm($user);
#    }
}
elsif (param('query')){
    my $lang = param('lang');
    my $cqp = param('query');
    my @alg = param('alg');
    my $style = param('style');
    print &UplugWeb::CorpusQuery($user,$owner,$corpus,$lang,
				 $cqp,\@alg,$style);
}
else{
    my $lang = param('lang');
    my $alg = param('alg');
    print &UplugWeb::CorpusQueryForm($user,$owner,$corpus,$lang,$alg);
}

print &end_html;

#------------------------------------------------------------

