#!/usr/bin/perl
#---------------------------------------------------------------------------
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
