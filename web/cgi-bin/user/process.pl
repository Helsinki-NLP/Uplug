#!/usr/bin/perl
#---------------------------------------------------------------------------
# 
#
#---------------------------------------------------------------------------
# Copyright (C) 2004 J�rg Tiedemann  <joerg@stp.ling.uu.se>
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
use Uplug::Web;

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

print "tasks: ",&Uplug::Web::ActionLinks($url,@actions);
print &hr;

&Uplug::Web::Process::ClearStack('done',$user,5);

if ($action eq 'jobs'){
    print &Uplug::Web::ShowProcessInfo($url,$user);
}
elsif ($action eq 'clear'){
    &Uplug::Web::Process::ClearStack($type,$user);
    print &Uplug::Web::ShowProcessInfo($url,$user);
}
elsif ($process){
    if ($action eq 'remove'){
	&Uplug::Web::Process::RemoveProcess($type,$user,$process);
	print &Uplug::Web::ShowProcessInfo($url,$user);
    }
    else{
	print &Uplug::Web::ShowProcessInfo($url,$user,$process);
    }
}
else{
    my %params;
    if (param()) {%params=&CGI::Vars();}
    print &Uplug::Web::ShowApplications($query,$user,$task,\%params);
    print &hr;
    print &h3('Jobs');
    print &Uplug::Web::ShowProcessInfo($url,$user);
}


print &end_html;

