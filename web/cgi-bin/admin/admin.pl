#!/usr/bin/perl
#---------------------------------------------------------------------------
# remove-user.pl
#
#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------

require 5.002;
use strict;
use CGI qw/:standard/;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use UplugWeb qw($CSS);



######################################################################

print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug admin - user management',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$CSS},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));

print &h2("UplugWeb admin");

print &a({-href => 'user.pl'},'User management').&br();
print &a({-href => 'process.pl'},'Process management').&br();
print &a({-href => 'corpus.pl'},'Corpus management').&br();
# print 'Process management'.&br();
# print 'Corpus management'.&br();





print &end_html;

##############################
