#!/usr/bin/perl
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
#
#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------

require 5.002;
use strict;

use CGI qw/:standard/;
use Fcntl qw(:DEFAULT :flock);
use FindBin qw($Bin);
use lib "$Bin/../lib";
use UplugProcess;
use UplugCorpus;
use UplugUser;

#$SIG{TERM} = \&interrupt;
#$SIG{INT} = \&interrupt;

our $OUTPUT;       # file to store stdout
our $LOCK;         # lock file for $OUTPUT

my ($user,$process,$config)=@ARGV;


# my  $UPLUGHOME='/home/staff/joerg/cvs/upl_dev';
my  $UPLUGHOME='/corpora/OPUS/upl';
my  $UPLUG=$UPLUGHOME.'/uplug';
$ENV{UPLUGHOME}=$UPLUGHOME;

my $TempDir='/tmp/uplugweb'.$process;           # run the program in a temp-dir
my $UserDir=&UplugCorpus::GetCorpusDir($user);  # the user's home directory
my $ConfigDir=$UserDir.'/'.$process;            # the process home dir
if (not -e "$ConfigDir/$config"){
    die "# run.pl: Cannot find config file: $config!\n";
}


if (not &UplugProcess::MoveJobTo($user,$process,'working')){
    die "# run.pl: Cannot find job $process for user $user!\n";
}

system "cp -R $ConfigDir $TempDir";
if (-e "$UserDir/ini"){system "cp -R $UserDir/ini $TempDir/";}
if (-e "$UserDir/lang"){system "cp -R $UserDir/lang $TempDir/";}
chdir $TempDir;

&PreProcessing($user,$config);
#----------------------------------------------------------
if (my $sig=system "$UPLUG $config >uplugweb.out 2>uplugweb.err"){
    &UplugProcess::MoveJobTo($user,$process,'failed');
    die "# run.pl: Got signal $? from $UPLUG! I'm going to die!\n";
}
#----------------------------------------------------------
&PostProcessing($user,$config);

if (not &UplugProcess::MoveJob($user,$process,'working','done')){
    die "# run.pl: Couldn't move job $process of user $user to done-stack!\n";
}




END {
    chdir '/';
    system "rm -fr $TempDir";
}


#-----------------------------------------
# lock output file that will be overwritten by this modules STDOUT
# (other processes should not be allowed to do anything with it
#  as long as the process is not finished!)


sub PreProcessing{
    my $user=shift;
    my $config=shift;

    my %data;
    &UplugProcess::UplugSystemIni(\%data,$user,$config);
    my $stdout;
    if (ref($data{module}) eq 'HASH'){    # is there a STDOUT stream?
	$stdout=$data{module}{stdout};
    }
    if (not $stdout){return;}             # no! --> return

    # yes:
    #   if there's no file defined for stdout-output
    #   and if there is a file for an input stream with the same name
    #   --> this will be the location of stdout! (check PostProcessing)

    if (ref($data{output}) eq 'HASH'){
	if (ref($data{output}{$stdout}) eq 'HASH'){
	    if (not defined $data{output}{$stdout}{file}){
		if (ref($data{input}) eq 'HASH'){
		    if (ref($data{input}{$stdout}) eq 'HASH'){
			if (defined $data{input}{$stdout}{file}){
			    $OUTPUT=$data{input}{$stdout}{file};
			}
		    }
		}
	    }
	}
    }
    if (-e $OUTPUT){
	$LOCK=$OUTPUT.'.lock';
	sysopen(LCK,$LOCK,O_RDONLY|O_CREAT) or die "can't open $LOCK: $!\n";
	while (not flock(LCK,LOCK_EX)){sleep 1;}
    }
}




sub PostProcessing{
    my $user=shift;
    my $config=shift;

    my %data;
    &UplugProcess::UplugSystemIni(\%data,$user,$config);
    my $stdout;
    if (ref($data{module}) eq 'HASH'){
	$stdout=$data{module}{stdout};
    }
    if (ref($data{output}) eq 'HASH'){
	foreach my $s (keys %{$data{output}}){

	    #---------------------
	    # copy input stream attributes to output streams
	    # for data streams with identical names!!
	    # (if the attributes are not set already)
	    # - sets e.g. the file attribute for STDOUT streams
	    # - copies STDOUT to the new file attribute (dangerous!!)
	    #    ----> overwrites input files!!!!!

	    if (ref($data{input}{$s}) eq 'HASH'){
		foreach $a (keys %{$data{input}{$s}}){
		    if (not defined $data{output}{$s}{$a}){
			if (($s eq $stdout) and ($a eq 'file')){
			    if ($data{input}{$s}{file}=~/\.gz$/){
				system "gzip uplugweb.out";
			    }
			    system "cp uplugweb.out.gz $data{input}{$s}{file}";
			}
			$data{output}{$s}{$a}=$data{input}{$s}{$a};
		    }
		}
	    }

	    #-----------------------
	    # register output streams for which the 'corpus' attribute is set!

	    if ((ref($data{output}{$s}) eq 'HASH') and 
		(defined $data{output}{$s}{corpus})){
		if (not defined $data{output}{$s}{status}){
		    $config=~s/^.*[\\\/]([^\\\/]+)$/$1/;      # set status attr
		    $data{output}{$s}{status}=$config;        # (=config name)
		}
		&RegisterCorpus($user,$data{output}{$s});     # register corpus
	    }
	}
    }
    if ($config=~/align\/word\/..\-..$/){
	my $dir=&UplugCorpus::GetCorpusDir($user);
	if ((-d "$dir/data/runtime") and (-d "data/runtime")){
	    `cp data/runtime/*.dbm* $dir/data/runtime/`;
	}
    }
}

sub RegisterCorpus{
    my $user=shift;
    my $corpus=shift;

    if (defined $$corpus{file}){
	&UplugUser::SendFile($user,"UplugWeb result",$$corpus{file});
    }
    my $name=$$corpus{corpus};
    delete $$corpus{'stream name'};
    delete $$corpus{'write_mode'};
    &UplugCorpus::ChangeCorpusInfo($user,$name,$corpus);
}






#sub interrupt{
#    print STDERR "client interrupted!\n";
#    &UplugProcess::MoveJobTo($user,$process,'failed');
#    exit;
#}

