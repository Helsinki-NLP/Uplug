#!/usr/bin/perl
#---------------------------------------------------------------------------
# server.pl
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

use FindBin qw($Bin);
use lib "$Bin/../lib";
use UplugProcess;
use POSIX qw(uname);

my $HOST=(uname)[1];
my $ME=(getpwuid($>))[0];


######################################################################

my $LogFile='/corpora/OPUS/uplug2-server.log';

BEGIN{
    setpgrp(0,0);              # become leader of the process group
}

END{
    local $SIG{HUP}='IGNORE';  # ignore HANGUP signal for right now
    kill ('HUP',-$$);          # kill child processes before you die
}

######################################################################

# don't start if already running or if not alone!!

if (&nmbr_running('server.pl')){die "already running!";}
my @u=`w | sed '1,2d' | cut -f1 -d ' ' | sort | uniq | grep -v '$ME'`;
if (@u){die "I'm not alone!\n";}

my @data=();
my $pid=fork();                              # create a new child process


#----------------------------------------------------------------------------
# this is the parent:
#   * check if I'm alone anbd die if not

if ($pid){
    local $SIG{HUP}= sub { die "$$: got hangup signal!\n" };
    local $SIG{CHLD}= sub { if (wait() eq $pid){die "server stopped!";} };
    while (1){
	my @u=`w | sed '1,2d' | cut -f1 -d ' ' | sort | uniq | grep -v '$ME'`;
	if (@u){die "I'm not alone!\n";}
	sleep(2);
    }
}



#----------------------------------------------------------------------------
# this is the child process: 
#   this is the actual server:
#     * get the next process
#     * run it and check the return value
#     * move process to 'failed' if there were any problems!

else{

    local $SIG{HUP} = \&interrupt;

    &my_log("server started!");
    while (not -e "$Bin/STOPSERVER"){
	while (@data=&UplugProcess::GetNextProcess('todo')){
	    $data[3]='('.$HOST.')';
#	    push (@data,'('.$HOST.')');
	    &UplugProcess::AddProcess('queued',@data);
	    if (my $sig=system "$data[2]"){
		print "got signal $sig! -> Re-schedule process!\n";
		&UplugProcess::MoveJobTo($data[0],$data[1],'failed');
	    }
	    @data=();
	}
	sleep(1);
    }              # found STOPSERVER: stop the server!
    &my_log("server stopped!");
    exit();
}


#--------------------------
# check if the server is running already on this client

sub nmbr_running {
    my $prog = $_[0];
    $prog =~ s/^(.*\/)*//;
#    my $who=`whoami`;
#    chomp $who;
#     my $nmbr=grep(/\s$who\s/,`/usr/sbin/lsof | grep 'cwd' | grep '^$prog '`);
    my @nmbr=`ps ax | grep '$prog' | grep -v 'grep '`;

    return $#nmbr;
}



sub interrupt{ 
    if(@data){
	&UplugProcess::MoveJobTo($data[0],$data[1],'todo');
    }
    &my_log("server interrupted!");
    exit();
}





sub my_log{
    my $message=shift;
    open F,">>$LogFile";
    chomp($message);
    my $time=localtime();
    print F "[$HOST:$time] ",$message,"\n";
    close F;
}


