#!/usr/bin/perl
#---------------------------------------------------------------------------
# process.pl
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

use lib '/home/staff/joerg/user_perl/lib/perl5/site_perl/5.6.1/';
use Mail::Mailer;
use CGI qw/:standard/;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use ProcessStack;
use UplugWeb qw($CSS);



#BEGIN { 
#    use CGI::Carp qw(carpout);
#    open L, ">>/tmp/uplugWeb.log" || die ("could not open log\n");
#    carpout(*L);
#}


my $type = param('type');
my $user = param('user');
my $process = param('process');
my $action = param('action');
my $query=url(-query=>1);
my $url=url();

######################################################################

print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug admin - process management',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$CSS},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));

print &h2("UplugWeb process management");
print &a({-href => 'admin.pl'},'Main admin menu'),&p();
print "tasks: ",&UplugWeb::ActionLinks($url,'view all');
print &hr;



##########################


if ($process){
    if ($action eq 'remove'){
	&UplugProcess::RemoveProcess($type,$user,$process);
	print &UplugWeb::ShowProcessInfo($query);
    }
    elsif ($action eq 'restart'){
	&UplugProcess::RestartProcess($type,$user,$process);
	print &UplugWeb::ShowProcessInfo($query);
    }
#    elsif ($action eq 'edit'){
#	&UplugProcess::EditProcess($process);
#	print &UplugWeb::ShowProcessInfo($query);
#    }
    elsif ($action eq 'run'){
	&UplugProcess::RunProcess($type,$user,$process);
	print &UplugWeb::ShowProcessInfo($query);
    }
    else{
	print &UplugWeb::ShowProcessInfo($query,undef,$process);
    }
}
elsif ($action eq 'clear'){
    &UplugProcess::ClearStack($type);
    print &UplugWeb::ShowProcessInfo($query);
}
else{
    print &UplugWeb::ShowProcessInfo($query);
}

print &end_html;




