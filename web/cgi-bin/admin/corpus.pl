#!/usr/bin/perl
#---------------------------------------------------------------------------
# corpus.pl - a simple corpus manager
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
use UplugWeb qw($CSS);


my $user = param('user');
my $action = param('action');
my $corpus = param('corpus');
my $query=url(-query=>1);

######################################################################

print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug admin - corpus manager',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$CSS},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));

print &h2("UplugWeb - Corpus Manager");
print &a({-href => 'admin.pl'},'Main admin menu');
print &p();

print "tasks: ",&UplugWeb::ActionLinks($query,'info'),&p();


my %UserData;
&UplugUser::ReadUserInfo(\%UserData,$user);

foreach my $u (keys %UserData){

    print &h3($u);

#    my %CorpusData=();
#    if (not &UplugCorpus::GetCorpusData(\%CorpusData,$u)){
#	print "No corpora found for user $user!";
#	print &end_html;
#	next;
#    }

    if ($user eq $u){
	if ($action eq 'remove'){
	    &UplugCorpus::RemoveCorpus($u,$corpus);
	    print &UplugWeb::ShowCorpusInfo($query,$u,$corpus);
	}
	elsif ($action eq 'view'){
	    &UplugWeb::ViewCorpus($u,$corpus);
	}
	else{
	    print &UplugWeb::ShowCorpusInfo($query,$u,$corpus);
	}
    }
    else{
	print &UplugWeb::ShowCorpusInfo($query,$u);
    }
}


print &end_html;


