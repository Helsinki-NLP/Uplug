#!/usr/bin/perl
#---------------------------------------------------------------------------
# 
#
#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------

require 5.002;
use strict;

use CGI qw/:standard/;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use UplugWeb;

# `rm -fr /corpora/OPUS/uplug2/joerg\@stp.ling.uu.se/106*`;
#`rm -fr /corpora/OPUS/uplug2/joerg\@stp.ling.uu.se/systems/*`;
#`rm -fr /corpora/OPUS/uplug2/joerg\@stp.ling.uu.se/data/*`;

#BEGIN { 
#    use CGI::Carp qw(carpout);
#    open L, ">>/tmp/uplugWeb.log" || die ("could not open log\n");
#    carpout(*L);
#}

if (defined &url_param('action')){&param('action',&url_param('action'));}
if (defined &url_param('task')){&param('task',&url_param('task'));}

my $user = &remote_user;
my $task = param('task');
my $action = param('action');
my $process = param('process');
my $type = param('type');

my $query=url(-query=>1);
my $url=url();

# my @actions=('add','info','remove all');
my @actions=('add','jobs');

# `rm -fr /corpora/OPUS/uplug2/systems/*`;
# `chmod u-w /corpora/OPUS/uplug2/systems/`;

######################################################################

print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug - Task Manager',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$CSS},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));


print &h2("UplugWeb - Task Manager");

print "tasks: ",&UplugWeb::ActionLinks($url,@actions);
print &hr;

&UplugProcess::ClearStack('done',$user,5);

if ($action eq 'jobs'){
    print &UplugWeb::ShowProcessInfo($url,$user);
}
elsif ($action eq 'clear'){
    &UplugProcess::ClearStack($type,$user);
    print &UplugWeb::ShowProcessInfo($url,$user);
}
elsif ($process){
    if ($action eq 'remove'){
	&UplugProcess::RemoveProcess($type,$user,$process);
	print &UplugWeb::ShowProcessInfo($url,$user);
    }
    else{
	print &UplugWeb::ShowProcessInfo($url,$user,$process);
    }
}
else{
    my %params;
    if (param()) {%params=&CGI::Vars();}
    print &UplugWeb::ShowApplications($query,$user,$task,\%params);
    print &hr;
    print &h3('Jobs');
    print &UplugWeb::ShowProcessInfo($url,$user);
}


print &end_html;

