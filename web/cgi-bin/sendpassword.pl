#!/usr/bin/perl
#---------------------------------------------------------------------------
# sendpassword.pl
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

my $css = "/~joerg/uplug2/menu.css";
my $UplugUrl = '/~joerg/uplug2';
my $Uplug2Dir='/corpora/OPUS/uplug2/';
my $UserDataFile=$Uplug2Dir.'user';
my $UplugAdmin='joerg@stp.ling.uu.se';

my $user = param('User');

######################################################################

print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug admin - send password',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$css},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));

print &h2("UplugWeb - send password");

my %UserData;
&ReadUserInfo(\%UserData,$user);
if (not defined $UserData{$user}{Password}){
    print "Cannot find user $user!".&br();
    print "Please ";
    print &a({-href => "$UplugUrl/register.html"},'register');
    print ' your account!';
    print &end_html;
    exit;
}

&SendMail($UplugAdmin,$user,'UplugWeb password',
"UplugWeb account: $user\nUplugWeb password: $UserData{$user}{Password}");
print "Mail send to $user!";

print &end_html;


##########################################

sub ReadUserInfo{
    my $data=shift;
    my $user=shift;
    open F,"<$UserDataFile";
    while (<F>){
	chomp;
	my ($u,$f)=split(/\:/);
	$$data{$u}{info}=$f;
	if (not -e $f){$$data{$u}{status}='removed';}
	elsif ($user eq $u){
	    open U,"<$f";
	    while (<U>){
		chomp;
		my ($k,$v)=split(/\:/);
		$$data{$u}{$k}=$v;
	    }
	    close U;
	}
    }
    close F;
}


sub SendMail{

    my ($from,$to,$subject,$message)=@_;

    my $mailer=Mail::Mailer->new("sendmail");
    $mailer->open({From    => $from,
		   To      => $to,
		   Subject => $subject});
    print $mailer $message;
    $mailer->close();
}
