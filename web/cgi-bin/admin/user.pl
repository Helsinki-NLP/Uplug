#!/usr/bin/perl
#---------------------------------------------------------------------------
# user.pl
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
use UplugUser;
use UplugWeb qw($CSS);

my $user = &remote_user;
my $name = param('name');
my $action = param('action');
my $query=url(-query=>1);

######################################################################

print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug admin - user management',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src' => $CSS},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));

print &h2("UplugWeb user management");
print &a({-href => 'admin.pl'},'Main admin menu');
print &p();

my %UserData;
if ($name){
    if ($action eq 'remove'){
	&UplugUser::RemoveUser($name);
	&UplugUser::ReadUserInfo(\%UserData,$name);
	print &UplugWeb::ShowUserInfo($query,\%UserData,$user,$name);
    }
    elsif ($action eq 'edit'){
	&UplugUser::EditUser($user);
	&UplugUser::ReadUserInfo(\%UserData,$user);
	print &UplugWeb::ShowUserInfo($query,\%UserData,$user,$name);
    }
    else{
	&UplugUser::ReadUserInfo(\%UserData,$name);
	print &UplugWeb::ShowUserInfo($query,\%UserData,$user,$name);
    }
}
else{
    &UplugUser::ReadUserInfo(\%UserData);
    print &UplugWeb::ShowUserInfo($query,\%UserData,$user,$name);
}


print &end_html;

######################################################################



