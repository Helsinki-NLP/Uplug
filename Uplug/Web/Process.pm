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

package Uplug::Web::Process;

use strict;
use IO::File;
use POSIX qw(tmpnam);
use File::Copy;
use ExtUtils::Command;

use Uplug::Web;
use Uplug::Web::Process::Stack;
use Uplug::Web::User;
use Uplug::Web::Corpus;
use Uplug::Config;


our $UPLUG=$ENV{UPLUGHOME}.'/uplug';

#-------------------------------------------------------------
#          RUN: script for running jobs
# CLUEDBMFILES: file-base for word alignment clue databases

my $RUN=$ENV{UPLUGHOME}.'/web/bin/run.pl';
my $INDEX=$ENV{UPLUGHOME}.'/web/bin/index.pl';
my @CLUEDBMFILES=('giza','dice','mi','tscore','str',
		  'chunk','chunktri','chunktripos','chunktriposi',
		  'lex','lexpos','pos','pos_coarse','position',
		  'posposi','postri','postriposi');
#-------------------------------------------------------------

my $ProcHome = $ENV{UPLUGDATA};

my $todoFile = $ProcHome.'/.todo';
my $queuedFile = $ProcHome.'/.queued';
my $workingFile = $ProcHome.'/.working';
my $doneFile = $ProcHome.'/.done';
my $failedFile = $ProcHome.'/.failed';
my $serverlogFile = $ProcHome.'/.serverlog';

if (not -e $ProcHome){mkdir $ProcHome;}

my $todo=Uplug::Web::Process::Stack->new($todoFile);
my $queued=Uplug::Web::Process::Stack->new($queuedFile);
my $working=Uplug::Web::Process::Stack->new($workingFile);
my $done=Uplug::Web::Process::Stack->new($doneFile);
my $failed=Uplug::Web::Process::Stack->new($failedFile);

if (not -e $serverlogFile){
    open F,">$serverlogFile";close F;  # create a serverlogfile
    system "chmod g+w $serverlogFile"; # add group write access
}

sub AvailableUplugSystems{
    return &GetApplications(@_);
}

sub GetSubmodules{
    my $user=shift;
    my $module=shift;
    if (ref($module) ne 'HASH'){
	my %config=();
	&GetConfiguration(\%config,$user,$module);
	$module=$config{module};
    }
    if (ref($module) ne 'HASH'){return undef;}
    if (ref($$module{submodules}) ne 'ARRAY'){return undef;}
    my $names=$$module{submodules};
    if (ref($$module{'submodule names'}) eq 'ARRAY'){
	$names=$$module{'submodule names'};
    }
    my @mod=();
    foreach (0..$#{$$module{submodules}}){
	push (@mod,$$module{submodules}[$_]);
	push (@mod,$$names[$_]);
    }
    return @mod;
}


sub UplugSystemIni{
    my $data=shift;
    my $user=shift;
    my $name=shift;

    if (not -e $name){chdir &Uplug::Web::Corpus::GetCorpusDir($user);}
    return &LoadConfiguration($data,$name);
}

sub GetConfiguration{
    my $data=shift;
    my $user=shift;
    my $name=shift;

    if (not -e $name){chdir &Uplug::Web::Corpus::GetCorpusDir($user);}
    return &LoadIniData($data,$name);
}


sub SaveUplugSettings{
    my $user=shift;
    my $configfile=shift;
    my $para=shift;
    if (not defined $configfile){return 0;}

    my $UserDir=&Uplug::Web::Corpus::GetCorpusDir($user);
    chdir $UserDir;
    my %config=();

    &LoadIniData(\%config,$configfile);
    &ExpandParameter(\%config,$para);
    return &WriteIniFile($configfile,\%config);
}

sub ResetUplugSettings{
    my $user=shift;
    my $configfile=shift;
    my $para=shift;
    if (not defined $configfile){return 0;}

    my $UserDir=&Uplug::Web::Corpus::GetCorpusDir($user);
    chdir $UserDir;
    if (-f $configfile){unlink $configfile;}
}



sub MakeIndexerProcess{
    my ($user,$corpus,$srcenc,$trgenc)=@_;
    my $command="$INDEX '$user' '$corpus' '$srcenc' '$trgenc'";
    $todo->push($user,$corpus,$command);
}

sub MakeUplugProcess{
    my $user=shift;
    my $corpus=shift;
    my $configfile=shift;
    my $para=shift;

    my $UserDir=&Uplug::Web::Corpus::GetCorpusDir($user);
    my $DocConfig=&Uplug::Web::Corpus::DocumentConfigFile($user,$corpus);
    my $ThisProcDir=$UserDir;
    my $process=time().'_'.$$;
    $ThisProcDir.='/'.$process;

    mkdir $ThisProcDir,0755;
    mkdir "$ThisProcDir/ini",0755;
    system "cp -R $UserDir/systems $ThisProcDir/";   # copy config files
    copy ($DocConfig,                                # copy document config-
	  "$ThisProcDir/ini/UserDataStreams.ini");   #   file to process-dir
#    system "cp -R $UserDir/ini $ThisProcDir/";       # copy ini files
#    system "chmod g+w $ThisProcDir";
    chdir $ThisProcDir;


    my %config=();
    if (not defined $configfile){return 0;}
    &LoadIniData(\%config,$configfile);
    &ExpandParameter(\%config,$para);
    &PrepareProcess($user,$corpus,$process,$configfile,\%config);
    &WriteIniFile($configfile,\%config);

#     my $command="$RUN '$user' '$process' '$configfile'";

    $todo->push($user,$process,$corpus,$configfile);
    return $process;
}

##---------------------------------------
## PrepareProcess: 
##   do some special preperations for certain Uplug processes
##   e.g. create output files, set permissions, change configurations
##   set postprocessing tasks for client processes (run.pl)
##     - config->postprocessing->STDOUT = file-to-save-stdout-in
##     - config->postprocessing->corpus = hash of new corpus streams
##                                        (to be set in user's corpus config)
##   this is highly specific and dependent on uplug modules!
##

sub PrepareProcess{
    my ($user,$corpus,$process,$configfile,$config)=@_;

    ## 2) touch output files and give write permissions

    my $output;

    #---------------------------------
    # sentence alignment
    #
    if ($configfile=~/align\/sent$/){
	my $src=$$config{input}{'source text'}{'stream name'};
	my $trg=$$config{input}{'target text'}{'stream name'};
	my $srccorpus=&Uplug::Web::Corpus::GetCorpusInfo($user,$corpus,$src);
	my $trgcorpus=&Uplug::Web::Corpus::GetCorpusInfo($user,$corpus,$trg);
	my ($srcname,$srclang)=&Uplug::Web::Corpus::SplitCorpusName($src);
	my ($trgname,$trglang)=&Uplug::Web::Corpus::SplitCorpusName($trg);
#	my $dir=&Uplug::Web::Corpus::GetCorpusDir($user,$trgname);
	my $dir=&Uplug::Web::Corpus::GetCorpusDir($user,$corpus);
	$output=$dir.'/'.$trgname.'.'.$srclang.'-'.$trglang;
#	$output=$dir.'/'.$srclang.'-'.$trglang.'.gz';
	if (not -e $output){open F,">$output";close F;}
	chmod 0664,$output;
	my $lockfile=$output.'.lock';
	if (not -e $lockfile){open F,">$lockfile";close F;}
	chmod 0664,$lockfile;

	$$config{output}{bitext}{corpus}=$srcname;
	if ($srcname ne $trgname){
	    $$config{output}{bitext}{corpus}.='-'.$trgname;
	}
	$$config{output}{bitext}{fromDoc}=$$srccorpus{file};
	$$config{output}{bitext}{toDoc}=$$trgcorpus{file};
	$$config{output}{bitext}{file}=$output;
	$$config{output}{bitext}{language}=$srclang.'-'.$trglang;
    }
    elsif ($configfile=~/(align\/word\/..\-..|giza)$/){
	my $bitext=$$config{input}{'bitext'}{'stream name'};
	my $corp=&Uplug::Web::Corpus::GetCorpusInfo($user,$corpus,$bitext);
	my ($name,$lang)=&Uplug::Web::Corpus::SplitCorpusName($bitext);
	my $dir=&Uplug::Web::Corpus::GetCorpusDir($user,$corpus);
	$output=$dir.'/'.$name.'.'.$lang.'.links';
	if (not -e $output){open F,">$output";close F;}
	chmod 0664,$output;
	my $lockfile=$output.'.lock';
	if (not -e $lockfile){open F,">$lockfile";close F;}
	chmod 0664,$lockfile;
	my $dir=&Uplug::Web::Corpus::GetCorpusDir($user);
	if (not -d "$dir/data"){mkdir "$dir/data",0755;}
	if (not -d "$dir/data/runtime"){
	    mkdir "$dir/data/runtime",0755;
	    system "chmod g+w $dir/data/runtime";
	}
	$dir.='/data/runtime/';
#	foreach (@CLUEDBMFILES){
#	    if (not -e "$dir$_.dbm"){open F,">$dir$_.dbm";close F;}
#	    chmod 0664,"$dir$_.dbm";
#	    if (not -e "$dir$_.dbm.head"){open F,">$dir$_.dbm.head";close F;}
#	    chmod 0664,"$dir$_.dbm.head";
#	}

	$$config{output}{bitext}{corpus}=$name.' word';
	if (-e $$corp{fromDoc}){
	    $$config{output}{bitext}{fromDoc}=$$corp{fromDoc};
	}
	if (-e $$corp{toDoc}){
	    $$config{output}{bitext}{toDoc}=$$corp{toDoc};
	}
	$$config{output}{bitext}{file}=$output;
	$$config{output}{bitext}{language}=$lang;
    }
}

## end of PrepareProcess
##--------------------------------------------------------------------------


sub GetOutputFiles{
    my $user=shift;
    my $configfile=shift;

    my %config=();
    my @files;
    &UplugSystemIni(\%config,$user,$configfile);
    if (ref($config{output}) ne 'HASH'){return undef;}
    foreach (keys %{$config{output}}){
	if (ref($config{output}{$_}) eq 'HASH'){
	    if (defined $config{output}{$_}{file}){
		push (@files,$config{output}{$_}{file});
	    }
	}
    }
    return @files;
}





sub ExpandParameter{
    my $config=shift;
    my $para=shift;
    if (ref($para) ne 'HASH'){return;}
    if (ref($config) ne 'HASH'){return;}

    foreach (keys %{$para}){
	my $key=$_;
	if (/^\-(.*)$/){
	    if (defined $$config{arguments}{shortcuts}{$1}){
		$key=$$config{arguments}{shortcuts}{$1};
	    }
	    else{next;}
	}
#	print "$key=$$para{$_}".'<br>';
	my @arr=split(/\:/,$key);
	if (defined $arr[4]){
	    $$config{$arr[0]}{$arr[1]}{$arr[2]}{$arr[3]}{$arr[4]}=$$para{$_};
	}
	elsif (defined $arr[3]){
	    $$config{$arr[0]}{$arr[1]}{$arr[2]}{$arr[3]}=$$para{$_};
	}
	elsif (defined $arr[2]){
	    $$config{$arr[0]}{$arr[1]}{$arr[2]}=$$para{$_};
	}
	elsif (defined $arr[1]){
	    $$config{$arr[0]}{$arr[1]}=$$para{$_};
	}
	elsif (defined $arr[0]){
	    $$config{$arr[0]}=$$para{$_};
	}
    }
}



###########################################################################


sub GetProcesses{
    my $type=shift;
    my $stack=&GetJobStack($type);
    return $stack->read();
}

sub GetNextProcess{
    my $type=shift;
    my $stack=&GetJobStack($type);
    return $stack->shift();
}

sub AddProcess{
    my $type=shift;
    my $stack=&GetJobStack($type);
    return $stack->push(@_);
}



sub RemoveProcess{
    my $type=shift;
    my $user=shift;
    my $process=shift;

    my $stack=&GetJobStack($type);
    $stack->remove($user,$process);

    my $UserDir=&Uplug::Web::Corpus::GetCorpusDir($user);
    if (-d "$UserDir/$process"){
	`rm -fr "$UserDir/$process"`;
    }
}


sub RestartProcess{
    my $type=shift;
    my $user=shift;
    my $process=shift;
    &MoveJob($user,$process,$type,'todo');
}

sub MoveJob{
    my $user=shift;
    my $process=shift;
    my $from=shift;
    my $to=shift;

    my $fromstack=&GetJobStack($from);
    my $tostack=&GetJobStack($to);

    if (my @data=$fromstack->find($user,$process)){
	$fromstack->remove($user,$process);
	$tostack->push(@data);
	return 1;
    }
    return 0;
}


sub MoveJobTo{
    my $user=shift;
    my $process=shift;
    my $to=shift;

    foreach ('todo','queued','working','done','failed'){
	if (&MoveJob($user,$process,$_,$to)){return 1;}
    }
    return 0;
}

sub FindJobStack{
    my $user=shift;
    my $process=shift;
    my $type=shift;

    if (not defined $type){
	foreach ('todo','queued','working','done','failed'){
	    if (&FindJobStack($user,$process,$_)){return $_;}
	}
    }
    my $stack=&GetJobStack($type);
    if ($stack->find($user,$process)){return $type;}
    return undef;
}

sub GetJobStack{
    my $type=shift;
    my $stack=$todo;
    if ($type eq 'queued'){$stack=$queued;}
    if ($type eq 'working'){$stack=$working;}
    if ($type eq 'done'){$stack=$done;}
    if ($type eq 'failed'){$stack=$failed;}
    return $stack;
}


#sub RunProcess{
#    my $type=shift;
#    my $user=shift;
#    my $process=shift;
#
#    my $stack=&GetJobStack($type);
#    my @data=$stack->find($user,$process);
#    &MoveJob($user,$process,'type','queued');
#    if (@data){`$data[2]`;}
#}


sub ClearStack{
    my $type=shift;
    my $user=shift;
    my $limit=shift;

    my @data=&GetProcesses($type);
    if (defined $user){
	my $pattern=quotemeta($user);
	@data=grep ($_=~/$user/,@data);
    }
    while (@data and (@data>$limit)){
	my ($u,$p)=split(/\:/,$data[0]);
	&RemoveProcess($type,$u,$p);
	shift @data;
    }
}



#########################################
# return a true value

1;
