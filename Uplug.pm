#####################################################################
#
# $Author$
# $Id$
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



package Uplug;

require 5.004;

use strict;
use FindBin qw($Bin);
use lib "$Bin/lib";
use IO::File;
use POSIX qw(tmpnam);
use Data::Dumper;
use Uplug::Config;

use vars qw($VERSION);
use vars qw(@TempFiles);

$VERSION = '0.01';

#-----------------------------------------------------------------------
BEGIN{
    setpgrp(0,0);              # become leader of the process group
    $SIG{HUP}=sub{die "# Uplug.pm: hangup";};
}

END{
    local $SIG{HUP}='IGNORE';  # ignore HANGUP signal for right now
    kill ('HUP',-$$);          # kill child processes before you die
}
#-----------------------------------------------------------------------


# my $MOVE= 'mv';
my $ConverterModule='convert.pl';
my %IgnoreAttr=('write_mode' => 1,
		'root' => 1,
		'HeaderTag' => 1,
		'DocRootTag' => 1,
		'DocHeaderTag' => 1,
		'DocBodyTag' => 1,
		'fromDoc' => 1,
		'toDoc' => 1,
		'SkipSrcFile' => 1,
		'SkipTrgFile' => 1,
		'key' => 1,
		'status' => 1,
		'language' => 1,
		'corpus' => 1,
		'columns' => 1,
		'__stdout' => 1,
		);
my @FileAttr=('file','source','target','FileName');


sub new{
    my $class=shift;
    my $self={};
    $self->{config}={};
    bless $self,$class;
    return $self;
}

sub load{
    my $self=shift;
    my $file=shift;
    my $para=shift;
    $self->{config}={};
    if ($file=~/^(\S+)\s+(\S.*)$/){
	$file=$1;
	if (ref($para) eq 'ARRAY'){
	    my @arg=split(/\s/,$2);
	    push (@{$para},@arg);
	}
	else{
	    $para.=' '.$2;
	}
    }
    &LoadConfiguration($self->{config},$file);
    $self->setParameter($para);
    &CheckParameter($self->{config},$para);
    $self->setConfigFile($file);

}

sub setConfigFile{
    my $self=shift;
    my $file=shift;
    ($self->{ConfigDir},$self->{ConfigFile})=&SplitFileName($file);

#------------------
#  create working directory! --> use pid
#
    if ($file!~/[\\\/]$$[\\\/][^\\\/]+$/){
	$self->{WorkingDir}=$self->{ConfigDir}.'/'.$$;
	&CopyFile($self->{ConfigFile},$self->{ConfigDir},$self->{WorkingDir});
    }
    else{
	$self->{WorkingDir}=$self->{ConfigDir};
    }
}

sub save{
    my $self=shift;
    &Uplug::Config::WriteIniFile($self->configFile,$self->{config});
}

sub prepare{
    my $self=shift;
    $self->{commands}=[];
    @{$self->{commands}}=$self->pipe;
#    @{$self->{commands}}=$self->makeCommands(@_);
}

sub commands{
    my $self=shift;
    if (not defined $self->{commands}){
	$self->prepare(@_);
    }
    return $self->{commands};
}

sub start{
    my $self=shift;
    if (not defined $self->{commands}){
	$self->prepare;
    }
    my $time=time();
    foreach (@{$self->{commands}}){
	my $modtime=time();
	print STDERR "$_\n---------------------------------------------\n";

	if (my $sig=system($_)){
	    print STDERR "# Uplug.pm: Got signal $? from child process:\n";
	    print STDERR "# $_\n";
	    return 0;
	}
#	$|=1;print `$_`;$|=0;

	$modtime=time()-$modtime;
	my ($sec,$min,$hour,$mday,$mon,$year)=gmtime($modtime);
	printf STDERR 
	    "      processing time: %2d:%2d:%2d:%2d:%2d:%2d\n", 
	    $year-70,$mon,$mday-1,$hour,$min,$sec;
    }
    if ($#{$self->{commands}}){
	$time=time()-$time;
	my ($sec,$min,$hour,$mday,$mon,$year)=gmtime($time);
	printf STDERR 
	    "total processing time: %2d:%2d:%2d:%2d:%2d:%2d\n", 
	    $year-70,$mon,$mday-1,$hour,$min,$sec;
    }
    return 1;
}

#-----------------------------------------
# usage: $module->run($start,$end,$skip)
#
#   $start - number of start module (complex modules - optional)
#   $end   - number of end module (complex modules - optional)
#   $skip  - array of modules nr's to be skipped (complex modules - optional)

sub run{
    my $self=shift;
    $self->init(@_);
    $self->prepare;
    return $self->start;
#    $self->cleanup;
}

sub init{
    my $self=shift;
    my ($start,$end,$skip)=@_;
    if (defined $start){$self->{start}=$start;}
    if (defined $end){$self->{end}=$end;}
    $self->{skip}={};
    my $config=$self->config;

    my @SkipMods=();
    if (ref($config->{module}->{skip}) eq 'ARRAY'){
	push(@SkipMods,@{$config->{module}->{skip}});
    }
    if (ref($skip) eq 'ARRAY'){
	push(@SkipMods,@{$skip});
    }
    if (@SkipMods){
	$self->{skip}={};
	foreach (@SkipMods){
	    $self->{skip}->{$_}=1;
	}
    }
}

sub setSkipModules{
    my $self=shift;
    my $mods=shift;
    my $config=$self->config;
    $config->{module}->{skip}=$mods;
#     $self->changeConfig('module','skip',{'modules' => $mods});
}

sub skipModule{
    my $self=shift;
    my $mod=shift;
    if (ref($self->{skip}) ne 'HASH'){return 0;}
    if ($self->{skip}->{$mod}){return 1;}
    return 0;
}

sub startModule{
    my $self=shift;
    if (defined $self->{start}){
	return $self->{start};
    }
    return 0;
}

sub endModule{
    my $self=shift;
    if (defined $self->{end}){
	return $self->{end};
    }
    if (ref($self->{submodules}) eq 'ARRAY'){
	return $#{$self->{submodules}};
    }
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{module}) eq 'HASH'){
	    if (ref($self->{config}->{module}->{submodules}) eq 'ARRAY'){
		return $#{$self->{config}->{module}->{submodules}};
	    }
	}
    }
    return 0;
}

sub cleanup{
    my $self=shift;
    $self->rmTempFiles;
    if ($self->{WorkingDir}=~/[\\\/][0-9]+$/){
	&RmDir($self->{WorkingDir});
    }
    if (ref($self->{submodules}) eq 'ARRAY'){
	foreach (0..$#{$self->{submodules}}){
	    if (ref($self->{submodules}->[$_])){
		$self->{submodules}->[$_]->cleanup;
	    }
	}
    }
#    if (ref($self->{convert}) eq 'ARRAY'){
#	foreach (0..$#{$self->{convert}}){
#	    if (ref($self->{convert}->[$_])){
#		$self->{convert}->[$_]->cleanup;
#	    }
#	}
#    }
}

sub DESTROY{
    my $self=shift;
    $self->cleanup();
}


sub configFile{
    my $self=shift;
    my $file="$self->{WorkingDir}/$self->{ConfigFile}";
    return $file;
}

sub makeCommands{
    my $self=shift;

    #---------------------------------------
    # input - hash to store input files
    # output - hash to store output stream configurations
    #   (used for complex modules only!!!!)

    my ($input,$output)=@_;
    if (ref($input) ne 'HASH'){
	$self->{input}={};
	$input=$self->{input};
    }
    if (ref($output) ne 'HASH'){
	$self->{output}={};
	$output=$self->{output};
    }
    #---------------------------------------

    my @commands=();
    my $config=$self->{config};
    if (not defined $config->{module}){
	die "Module.pm: no module definition found in $self->{ConfigFile}!\n";
    }


    #---------------------------------------
    # a simple module command:
    #   a single module with a single command

    if (defined $config->{module}->{program}){
	my $command='';
	if (defined $config->{module}->{location}){
	    $command=$config->{module}->{location}.'/';
	}
	$command.=$config->{module}->{program};
	my $ConfigFile=$self->configFile;
	$command.=' -i '.$ConfigFile;

	my @commands=($command);
	$self->checkModInOut(\@commands);

	return @commands;
    }

    #---------------------------------------
    # a complex module:
    #    the module has several submodules
    #    --> get commands from each submodule!

    elsif (ref($config->{module}->{submodules}) eq 'ARRAY'){

	$self->saveInputFiles($input);

	$self->checkInOut(\@commands,$self,$input,$output);
	$self->makePipe(\@commands,$self,$input,$output);

	$self->setInputStreams($output);
	my $start=$self->startModule;
	my $end=$self->endModule;
	my ($loopStart,$loopEnd)=$self->loop;
	my $iter=$self->iterations;
	my $count=1;

	$self->{submodules}=[];

#	foreach my $i ($start..$end){
	my $i=$start;
	while ($i<=$end){
	    if ($self->skipModule($i)){$i++;next;}
	    $self->{submodules}->[$i]=Uplug->new;
	    my $submod=$self->{submodules}->[$i];
	    $submod->load($config->{module}->{submodules}->[$i]);
	    my %in=();my %out=();
	    &copyHash($input,\%in);
	    &copyHash($output,\%out);

 	    $submod->prepare(\%in,\%out);
#	    $self->checkInOut(\@commands,$submod,\%out,\%out);
	    $self->checkInOut(\@commands,$submod,$input,$output);
	    $self->makePipe(\@commands,$submod,$input,$output);

#	    &copyHash(\%in,$input);
#	    &copyHash(\%out,$output);

	    $submod->saveInputFiles($input);
	    $submod->updateOutputStreams($output);
	    if (($i==$loopEnd) and ($count<$iter)){
		$count++;
		$i=$loopStart;
	    }
	    else{$i++;}
	}

	$self->swapInOut;
	$self->checkInOut(\@commands,$self,$input,$output);
	$self->swapInOut;
    }
    return @commands;
}



sub configSequence{
    my $self=shift;

    my $config=$self->{config};
    if (not defined $config->{module}){
	die "Module.pm: no module definition found in $self->{ConfigFile}!\n";
    }

    #---------------------------------------
    # a simple module command:
    #   a single module with a single command

    if (defined $config->{module}->{program}){
	my $ConfigFile=$self->configFile;
	return ($ConfigFile);
    }

    #---------------------------------------
    # a complex module:
    #    the module has several submodules
    #    --> get commands from each submodule!

    elsif (ref($config->{module}->{submodules}) eq 'ARRAY'){
	my $start=$self->startModule;
	my $end=$self->endModule;
	my ($loopStart,$loopEnd)=$self->loop;
	my $iter=$self->iterations;
	my $count=1;
	my @modConfig=();

	$self->{submodules}=[];

	my $i=$start;
	while ($i<=$end){
	    if ($self->skipModule($i)){next;}
	    $self->{submodules}->[$i]=Uplug->new;
	    my $submod=$self->{submodules}->[$i];
	    $submod->load($config->{module}->{submodules}->[$i]);
	    my @subConfig=$submod->configSequence;
	    push (@modConfig,@subConfig);

	    if (($i==$loopEnd) and ($count<$iter)){
		$count++;
		$i=$loopStart;
	    }
	    else{$i++;}
	}
	return @modConfig;
    }
    return ();
}


sub modSequence{
    my $self=shift;
    my $modSequence=shift;
    if (ref($modSequence) ne 'ARRAY'){return 0;}

    my $config=$self->{config};
    if (not defined $config->{module}){
	die "Module.pm: no module definition found in $self->{ConfigFile}!\n";
    }

    #---------------------------------------
    # a simple module command:
    #   a single module with a single command

    if (defined $config->{module}->{program}){
	my $ConfigFile=$self->configFile;
	return ($ConfigFile);
    }

    #---------------------------------------
    # a complex module:
    #    the module has several submodules
    #    --> get commands from each submodule!

    elsif (ref($config->{module}->{submodules}) eq 'ARRAY'){
	my $start=$self->startModule;
	my $end=$self->endModule;
	my ($loopStart,$loopEnd)=$self->loop;
	my $iter=$self->iterations;
	my $count=1;
	my @modConfig=();

	$self->{submodules}=[];

	my $i=$start;
	while ($i<=$end){
	    if ($self->skipModule($i)){next;}
	    $self->{submodules}->[$i]=Uplug->new;
	    my $submod=$self->{submodules}->[$i];
	    $submod->load($config->{module}->{submodules}->[$i]);
	    my @subConfig=$submod->configSequence;
	    push (@modConfig,@subConfig);

	    if (($i==$loopEnd) and ($count<$iter)){
		$count++;
		$i=$loopStart;
	    }
	    else{$i++;}
	}
	return @modConfig;
    }
    return ();
}

sub makeCommand{
    my $self=shift;

    my $config=$self->{config};

    #---------------------------------------
    # a simple module command:
    #   a single module with a single command

    if (defined $config->{module}->{program}){
	my $command='';
	if (defined $config->{module}->{location}){
	    $command=$config->{module}->{location}.'/';
	}
	$command.=$config->{module}->{program};
	my $ConfigFile=$self->configFile;
	$command.=' -i '.$ConfigFile;
	return $command;
    }
}

sub command{
    my $self=shift;

    my $config=$self->{config};

    #---------------------------------------
    # a simple module command:
    #   a single module with a single command

    if (defined $config->{module}->{program}){
	my $command='';
	if (defined $config->{module}->{location}){
	    $command=$config->{module}->{location}.'/';
	}
	$command.=$config->{module}->{program};
	my $ConfigFile=$self->configFile;
	$command.=' -i '.$ConfigFile;
	my $param=$self->parameter();
	$command.=' '.$param;
	return $command;
    }
}


sub setParameter{
    my $self=shift;
    my $para=shift;
    if (ref($para) eq 'ARRAY'){
	map (s/^(.*\S[\s\|\;]\S.*)$/\'$1\'/,@{$para});
	$self->{parameter}=join ' ',@{$para};
    }
    else{
	$self->{parameter}=$para;
    }
}

sub parameter{
    my $self=shift;
    return $self->{parameter};
}

sub pipe{
    my $self=shift;
    my ($pipe,$prev,$out)=@_;

    if (ref($pipe) ne 'ARRAY'){$pipe=[];}
    if (ref($prev) ne 'HASH'){$prev={};}
    if (ref($out) ne 'HASH'){$out={};}

    #----------------------------------------------------

    my $input=$self->input;
    my $output=$self->output;

    my @convert=$self->checkInput($input,$prev);
    foreach (@convert){
	my $mod=$self->newConvertModule();
#	my $mod=Uplug->new;
	$mod->load($_);
	$mod->pipe($pipe,$prev,$out);
    }

    #----------------------------------------------------

    &SaveStreams($prev,$input);

    my $command=$self->command;
    if ($command){
	my $broken=0;

	my $stdout=undef;
	if (not defined $out->{'__stdout'}){$broken=1;}
	if (ref($out->{$out->{'__stdout'}}) ne 'HASH'){$broken=1;}
	else{$stdout=$out->{'__stdout'};}

	my $stdin=$self->pipeInput;
	if (not defined $stdin){$broken=1;}
	elsif (not defined $input->{$stdin}){$broken=1;}
	elsif ($stdin ne $stdout){$broken=1;}
	elsif (not &IsCompatible($out->{$stdout},$input->{$stdin})){$broken=1;}
	elsif (&WritesOnInput($prev,$output)){$broken=1;}

#	my $ff=$self->configFile;
#	if ($ff=~/Tagger/){
#	    print '';
#	}

	if ($broken or (not @{$pipe})){
	    if ($stdout and @{$pipe}){
		my $tmpfile=$self->setStdoutFile;
		$pipe->[-1].=" > $tmpfile";
		$prev->{'__temp'}->{$tmpfile}=1;
		$out->{$stdout}->{file}=$tmpfile;
		$prev->{$stdout}->{file}=$tmpfile;
	    }
	    if ($stdin){
		if (defined $prev->{$stdin}){
		    $self->changeConfig('input',$stdin,$prev->{$stdin});
		}
		else{
		    my $name=$self->name;
		    die "# Uplug.pm: no input found for module '$name'!\n";
		}
	    }
	    $prev->{'__input'}={};
	    push (@{$pipe},$command);
	}
	else{
	    $pipe->[-1].=' | '.$command;
	}
	$self->matchPreviousOutputWithInput($input,$prev);
    }


    #----------------------------------------------------
    # add pipe-commands for each sub-module

    my @submods=$self->submodules;
    if (@submods){
	my $start=$self->startModule;
	my $end=$self->endModule;
	my ($loopStart,$loopEnd)=$self->loop;
	my $iter=$self->iterations;
	my $count=1;
	$self->{submodules}=[];
	my $i=$start;

	while ($i<=$end){
#	    if ($self->skipModule($i)){next;}
	    if (not $self->skipModule($i)){
		$self->{submodules}->[$i+$count*$end]=Uplug->new;
		$self->{submodules}->[$i+$count*$end]->load($submods[$i]);
		$self->{submodules}->[$i+$count*$end]->pipe($pipe,$prev,$out);
	    }
#	    my $nn=$self->{submodules}->[$i]->name;
	    if (($i==$loopEnd) and ($count<$iter)){
		$count++;
		$i=$loopStart;
	    }
	    else{$i++;}
	}
    }

#    foreach (@submods){
#	my $submod=Uplug->new;
#	$submod->load($_);
#	$submod->pipe($pipe,$prev,$out);
#    }

    #----------------------------------------------------

    my @convert=();
    if (@submods and (not $command)){
	@convert=$self->checkOutput($output,$prev);
	foreach (@convert){
	    my $mod=$self->newConvertModule();
#	    my $mod=Module->new;
	    $mod->load($_);
	    $mod->pipe($pipe,$prev,$out);
	}
    }

    &SaveFiles($prev,$input);
    &SaveStreams($prev,$output);

    if ($command or @convert){
	%{$out}=%{$output};
	$out->{'__stdout'}=$self->pipeOutput;
    }
#    print STDERR $self->configFile,": $out->{'__stdout'}:\n";
    if (ref($prev->{'__temp'}) eq 'HASH'){
	@{$self->{tempFiles}}=keys %{$prev->{'__temp'}};
    }

    return @{$pipe};
}


sub SaveStreams{
    my ($saved,$streams)=@_;
    if (ref($streams) eq 'HASH'){
	foreach my $s (keys %{$streams}){
	    if (keys %{$streams->{$s}}){
		%{$saved->{$s}}=%{$streams->{$s}};
	    }
	}
    }
}

sub SaveFiles{
    my ($saved,$streams)=@_;
    if (ref($streams) ne 'HASH'){return;}
    foreach (keys %{$streams}){
	foreach my $a (@FileAttr){
	    if ($streams->{$_}->{$a}){
		my $file=$streams->{$_}->{$a};
		$saved->{'__input'}->{$file}=$a;
	    }
	}
    }
}

sub WritesOnInput{
    my ($saved,$streams)=@_;
    if (ref($streams) ne 'HASH'){return 0;}
    if (ref($saved->{'__input'}) ne 'HASH'){return 0;}
    foreach my $s (keys %{$streams}){
	foreach my $f (keys %{$saved->{'__input'}}){
	    my $attr=$saved->{'__input'}->{$f};
	    if ($streams->{$s}->{$attr} eq $f){
		return 1;
	    }
	}
    }
    return 0;
}













sub pipeOld{
    my $self=shift;
    $self->{configs}=[];
    $self->{pipe}=[];
    @{$self->{configs}}=$self->configSequence;
    $self->addConvertModules($self->{configs});
    @{$self->{pipe}}=$self->makePipes($self->{configs});
    return  @{$self->{pipe}};
}

sub makePipes{
    my $self=shift;
    my $config=shift;
    if (ref($config) ne 'ARRAY'){return ();}

    my @commands=();
    my @pipe=();
    my %input=();
    my %output=();
    my $pipeOut;
    my $brokenPipe=0;
    my $lastMod;
    my $thisMod;

    while (@{$config}){

	my $file=shift(@{$config});
	$thisMod=Uplug->new;
	$thisMod->load($file);

	if ($thisMod->brokenPipe($pipeOut,\%input)){
	    if (@pipe){
		my $newcom=join ' | ',@pipe;
		push (@commands,$newcom);
		@pipe=();
	    }
	    if ($pipeOut){
		my $tmpfile=$thisMod->setStdoutFile;
		$commands[-1].=" > $tmpfile";
		$output{$lastMod->pipeOutput}{file}=$tmpfile;
	    }
	    my $stdin;
	    if ($stdin=$thisMod->pipeInput){
		if (defined $output{$stdin}){
		    $thisMod->changeConfig('input',$stdin,$output{$stdin});
		}
	    }
	}

	$thisMod->saveInputFiles(\%input);
	$thisMod->updateOutputStreams(\%output);
	$lastMod=$thisMod;

	$pipeOut=undef;
	my $modout=$thisMod->output;
	if (ref($modout) eq 'HASH'){
	    $pipeOut=$modout->{$thisMod->pipeOutput};
	}
	my $command=$thisMod->makeCommand;
	push (@pipe,$command);
    }
    my $newcom=join ' | ',@pipe;
    push (@commands,$newcom);
    return @commands;
}





sub brokenPipe{
    my $self=shift;
    my $stdout=shift;
    my $input=shift;
    if (not $self->checkPipeIn($stdout)){
	return 1;
    }
    if ($self->overwrites($input)){
	return 1;
    }
}

sub overwrites{
    my $self=shift;
    my $input=shift;
    my $output=$self->output;
    if (ref($output) ne 'HASH'){return 0;}
    foreach my $s (keys %{$output}){
	foreach my $f (keys %{$input}){
	    my $attr=$input->{$f};
	    if ($output->{$s}->{$attr} eq $f){
		return 1;
	    }
	}
    }
    return 0;
}


sub checkPipeIn{
    my $self=shift;
    my ($stdout)=@_;
    if (ref($stdout) ne 'HASH'){return 0;}

    my $stdin=$self->pipeInput;
    my $input=$self->input;
    if ((not defined $stdin) or (not defined $input->{$stdin})){
	return 0;
    }

    if (&IsCompatible($input->{$stdin},$stdout)){
	return 1;
    }
    return 0;
}

sub addConvertModules{
    my $self=shift;
    my ($configFiles)=@_;
    if (ref($configFiles) ne 'ARRAY'){return 0;}

    my %output=();
    my $config=$self->config;
    $self->updateStreams($config->{input},\%output);
    my $i=0;
    while ($i<@{$configFiles}){
	my $submod=Uplug->new;
	$submod->load($configFiles->[$i]);
	my $config=$submod->config;
	my @convert=();
	if (ref($config->{input}) eq 'HASH'){
	    @convert=$submod->checkInput($config->{input},\%output);
	    splice (@{$configFiles},$i,0,@convert);
	    $i+=@convert;
	}
	$submod->updateOutputStreams(\%output);
	$i++;
    }
}

sub isProductive{
    my $self=shift;
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{module}) eq 'HASH'){
	    if (defined $self->{config}->{module}->{program}){
		return 1;
	    }
	}
    }
    return 0;
}

sub checkInput{
    my $self=shift;
    my ($input,$output)=@_;
    my @convert=();
    foreach my $s (keys %{$input}){
	if (defined $output->{$s}){
	    if (not &IsCompatible($input->{$s},$output->{$s})){
		if (not keys %{$input->{$s}}){
		    $self->changeConfig('input',$s,$output->{$s});
		}
		elsif ($self->isStdout($input->{$s})){
		    $self->changeConfig('input',$s,$output->{$s});
		}
		elsif ($self->isProductive()){
		    my $new=$self->createConvert($s,$output,$input);
		    push (@convert,$new);
		}
		else{
		    $self->changeConfig('input',$s,$output->{$s});
		}
	    }
	}
    }
    return @convert;
}

sub checkOutput{
    my $self=shift;
    my ($input,$output)=@_;
    my @convert=();
    foreach my $s (keys %{$input}){
	if (defined $output->{$s}){
	    if (not &IsCompatible($input->{$s},$output->{$s})){
		if (not keys %{$input->{$s}}){
		    return ();
		}
		else{
		    my $new=$self->createConvert($s,$output,$input);
		    push (@convert,$new);
		}
	    }
	}
    }
    return @convert;
}


sub createConvert{
    my $self=shift;
    my ($name,$in,$out)=@_;

    if (not keys %{$out->{$name}}){return;}
    my $config=$self->{WorkingDir}.'/convert';
    if (not -d $self->{WorkingDir}){$config=&GetTempFileName;}
    my $i=0;while (-e "$config$i\.ini"){$i++;}
    $config.=$i.'.ini';

#    if (ref($self->{convert}) ne 'ARRAY'){
#	$self->{convert}=[];
#    }
#    my $i=$#{$self->{convert}};$i++;
#    $self->{convert}->[$i]=Uplug->new;
#    my $newModule=$self->{convert}->[$i];
#    my $newModule=$self->{convertmodules}->[$idx];
#    my $newModule=Uplug->new;

    my $newModule=$self->newConvertModule();
    if ($self->isStdin($in->{$name})){
	$newModule->setPipeInput($name);
    }
    if ($self->isStdin($out->{$name})){
	$newModule->setPipeOutput($name);
    }
    &CreateConvertModule($newModule,$config,$name,$in->{$name},$out->{$name});
#    $newModule->updateOutputStreams($in);
    return $config;
}



sub config{
    my $self=shift;
    if (ref($self->{config}) ne 'HASH'){
	$self->{config}={};
    }
    return $self->{config};
}

sub submodules{
    my $self=shift;
    my $config=$self->config;
    if (ref($config->{module}) eq 'HASH'){
	if (ref($config->{module}->{submodules}) eq 'ARRAY'){
	    return @{$config->{module}->{submodules}};
	}
    }
    return ();
}

sub loop{
    my $self=shift;
    my $config=$self->config;
    my ($start,$end)=(0,0);
    if (ref($config->{module}) eq 'HASH'){
	if (defined $config->{module}->{loop}){
	    ($start,$end)=split(/\:/,$config->{module}->{loop});
	}
	else{
	    $end=$self->submodules;
	}
    }
    return ($start,$end);
}

sub iterations{
    my $self=shift;
    my $config=$self->config;
    if (ref($config->{module}) eq 'HASH'){
	if (defined $config->{module}->{iterations}){
	    return $config->{module}->{iterations};
	}
    }
    return 1;
}

sub swapInOut{
    my $self=shift;
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{input}) eq 'HASH'){
	    $self->{config}->{tmpin}=$self->{config}->{input};
	}
	if (ref($self->{config}->{output}) eq 'HASH'){
	    $self->{config}->{tmpout}=$self->{config}->{output};
	}
	$self->{config}->{input}=$self->{config}->{tmpout};
	$self->{config}->{output}=$self->{config}->{tmpin};
    }
}


sub input{
    my $self=shift;
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{input}) eq 'HASH'){
	    return $self->{config}->{input}
	}
    }
    my %in=();
    return \%in;
}

sub output{
    my $self=shift;
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{output}) eq 'HASH'){
	    return $self->{config}->{output}
	}
    }
    my %out=();
    return \%out;
}

sub IsCompatible{
    my ($new,$old)=@_;
    if (ref($old) ne 'HASH'){return 1;}
    if (ref($new) ne 'HASH'){return 1;}
#    if ((keys %{$old})!=(keys %{$new})){return 0;}
    foreach (keys %{$old}){
	if (defined $IgnoreAttr{$_}){next;}
	if ($old->{$_} ne $new->{$_}){return 0;}
    }
    foreach (keys %{$new}){
	if (defined $IgnoreAttr{$_}){next;}
	if ($old->{$_} ne $new->{$_}){return 0;}
    }
    return 1;
}

sub newConvertModule{
    my $self=shift;
    if (not defined $self->{convertmodules}){
	$self->{convertmodules}=[];
    }
    my $idx=@{$self->{convertmodules}};
    $self->{convertmodules}->[$idx]=Uplug->new;
    return $self->{convertmodules}->[$idx];
}

sub CreateConvertModule{
    my ($module,$config,$name,$output,$new)=@_;
    my $data=$module->{config};
    $data->{module}->{name}='convert';
    $data->{module}->{program}=$ConverterModule;
    $data->{module}->{location}="$Bin/bin";

    $data->{input}->{$name}=$output;
    $data->{output}->{$name}=$new;
#    $data->{input}->{$name}=$output->{$name};
#    $data->{output}->{$name}=$new->{$name};
#     $data->{output}->{$name}->{'write_mode'}='overwrite';
    &Uplug::Config::WriteIniFile($config,$data);
    ($module->{WorkingDir},$module->{ConfigFile})=&SplitFileName($config);
}

sub checkModInOut{
    my $self=shift;
    my $commands=shift;
    my $output=$self->output;
    my %InFiles=();
    my %OutFiles=();
    $self->saveInputFiles(\%InFiles);
    $self->saveInputFiles(\%OutFiles);
    foreach my $f (keys %InFiles){
	if (defined $OutFiles{$f}){
	    my $attr=$OutFiles{$f};
	    foreach my $s (keys %{$output}){
		if ((defined $output->{$s}) and 
		    ($output->{$s}->{$attr} eq $f)){
		    my %old=%{$output->{$s}};
		    $output->{$s}->{$attr}=&GetTempFileName;
		    $self->save;
		    $self->addConvertModule($attr,$output->{$s},\%old,
					    $commands,\%InFiles,\%OutFiles);
		}
	    }
	}
    }
}


sub checkInOut{
    my $self=shift;
    my ($prev,$module,$in,$out)=@_;
    my $inStreams=$module->input;
    if (ref($inStreams) ne 'HASH'){return;}
    foreach my $s (keys %{$inStreams}){
	if (defined $out->{$s}){
	    if (not &IsCompatible($inStreams->{$s},$out->{$s})){
		$self->addConvertModule($s,$out->{$s},$inStreams->{$s},
					$prev,$in,$out);
		print '';
	    }
	}
    }
}

sub inStream{
    my $self=shift;
    my $name=shift;
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{input}) eq 'HASH'){
	    return $self->{config}->{input}->{$name};
	}
    }
}
sub outStream{
    my $self=shift;
    my $name=shift;
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{output}) eq 'HASH'){
	    return $self->{config}->{output}->{$name};
	}
    }
}

sub addConvertModule{
    my $self=shift;
    my ($name,$old,$new,$commands,$in,$out)=@_;

    if (not keys %{$new}){return;}
    my $config=$self->{WorkingDir}.'/convert';
    my $i=0;
    while (-e "$config$i\.ini"){$i++;}
    $config.=$i.'.ini';

#    if (ref($self->{convert}) ne 'ARRAY'){
#	$self->{convert}=[];
#    }
#    my $i=$#{$self->{convert}};$i++;
#    $self->{convert}->[$i]=Uplug->new;
#    my $newModule=$self->{convert}->[$i];
#    my $newModule=Uplug->new;

    my $newModule=$self->newConvertModule();

#    $newModule->setPipeInput($self->pipeOutput);
#    $newModule->setPipeOutput($module->pipeInput);
    if ($self->isStdin($old)){
	$newModule->setPipeInput($name);
    }
    if ($self->isStdin($new)){
	$newModule->setPipeOutput($name);
    }
#    $newModule->setPipeInput($self->pipeOutput);
#    $newModule->setPipeOutput($module->pipeInput);
    &CreateConvertModule($newModule,
			 $config,$name,
			 $old,$new);
    $self->makePipe($commands,$newModule,$in,$out);
    $newModule->saveInputFiles($in);
    $newModule->updateOutputStreams($out);
}

sub name{
    my $self=shift;
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{module}) eq 'HASH'){
	    if (defined $self->{config}->{module}->{name}){
		return $self->{config}->{module}->{name};
	    }
	    if (defined $self->{config}->{module}->{program}){
		return $self->{config}->{module}->{program};
	    }
	}
    }
    return 'unknown';
}

sub stdoutFile{
    my $self=shift;
    if (defined $self->{stdoutFile}){
	return $self->{stdoutFile};
    }
    return undef;
}

sub setStdoutFile{
    my $self=shift;
    my $stdoutFile=shift;
    if (not defined $stdoutFile){
	my $fh;
	do {$stdoutFile=tmpnam();}
	until ($fh=IO::File->new($stdoutFile,O_RDWR|O_CREAT|O_EXCL));
	$fh->close;
    }
    $self->{stdoutFile}=$stdoutFile;
    if (not defined $self->{tempFiles}){
	$self->{tempFiles}=[];
    }
    push(@{$self->{tempFiles}},$stdoutFile);
    return $stdoutFile;
}

sub rmStdoutFile{
    my $self=shift;
    if (defined $self->{stdoutFile}){
	if (-e $self->{stdoutFile}){
	    unlink $self->{stdoutFile};
	}
    }
}

sub rmTempFiles{
    my $self=shift;
    if (defined $self->{tempFiles}){
	foreach (@{$self->{tempFiles}}){
	    if (-e $_){
		print STDERR "Uplug.pm: remove temporary file $_!\n";
		unlink $_;
	    }
	}
    }
#    if (ref($self->{submodules}) eq 'ARRAY'){
#	foreach (0..$#{$self->{submodules}}){
#	    $self->{submodules}->[$_]->rmTempFiles;
#	}
#    }
}



#---------------------------------------------------------------------
# makePipe
#
# this is a crucial subfunction for glueing modules together
# ... some parts of makePipe are rather ad hoc and might be buggy ...
#

sub makePipe{
    my $self=shift;
    my ($prev,$module,$in,$out)=@_;
    my $commands=$module->commands;

#    $self->checkInOut($prev,$module,$in,$out);

    if (($self->checkPipeInput($module,$self->pipeOutput,$out)) and
	($self->checkPipeOutput($module,$in))){
	if (@{$prev} and @{$commands}){
	    my $first=shift(@{$commands});
	    $prev->[-1].=' | '.$first;
	}
    }
    else{

        #------------------ 
	# the pipe is broken but the current module
	# writes to STDOUT:

	if ($self->pipeOutput){
	    if (@{$commands} and @{$prev}){
		my $newTmpfile=$self->setStdoutFile;
		$prev->[-1].=" > $newTmpfile";
		$out->{$self->pipeOutput}->{file}=$newTmpfile;
		$out->{'__stdout'}->{$self->pipeOutput}=$newTmpfile;
#		$commands->[0]=~s/(\||\Z)/ \< $newTmpfile $1/s;
	    }
	}

        #------------------ 
	# the pipe is broken but the current module
	# waits for STDIN:

	if ($module->pipeInput){
	    my $name=$module->pipeInput;
	    $module->changeConfig('input',$name,$out->{$name});

	    if ($self->isStdin($out->{$name})){
		if (defined $out->{'__stdout'}->{$name}){
		    my $tmpfile=$out->{'__stdout'}->{$name};
		    $commands->[0]=~s/(\||\Z)/ \< $tmpfile $1/s;
		}
		else{
		    my $name=$module->name;
		    die "Uplug.pm: no input found for module '$name'\n";
		}
	    }

#	    my $new=$module->inStream($name);
#	    my $old=&getFileInput($out,$name);
#
#	    #------------------ 
#	    # 1) check if the stream exists as a temporary file
#
#	    if (defined $out->{'__stdout'}->{$name}){
#		my $tmpfile=$out->{'__stdout'}->{$name};
#		$commands->[0]=~s/(\||\Z)/ \< $tmpfile $1/s;
#	    }
#
#	    #------------------ 
#	    # 2) check if the stream exists as a file stream --> convert
#
#	    elsif ($old and $new){
#		my @comm=();
#		$self->addConvertModule($name,$old,$new,\@comm,$in,$out);
#		$commands->[0]=$comm[0].' | '.$commands->[0];
#	    }
#
#	    #------------------ 
#	    # 3) give up! ---> error message
#
##	    else{
##		my $name=$module->name;
##		die "Uplug.pm: no input found for module '$name'\n";
##	    }
	}
	%{$in}=();
    }
    push (@{$prev},@{$commands});
    $self->setPipeOutput($module->pipeOutput);     # update pipe output
    return 1;
}

#---------------------------------------------------------------------


sub getFileInput{
    my ($streams,$name)=@_;
    if (ref($streams) eq 'HASH'){
	if (ref($streams->{'__file'}) eq 'HASH'){
	    return $streams->{'__file'}->{$name};
	}
    }
}


sub makeSequence{
    my $self=shift;
    my ($prev,$module,$in,$out)=@_;
    my $commands=$module->commands;

    $self->checkOutput($prev,$module,$in,$out);
    $self->checkInput($commands,$module,$in,$out);
    %{$in}=();
    push (@{$prev},@{$commands});
    $self->setPipeOutput($module->pipeOutput);     # update pipe output
}



sub MakeTempStream{
    my ($stream,$dir)=@_;
    foreach (@FileAttr){
	$stream->{$_}="$dir/$_";
    }
}

sub checkPipeOutput{
    my $self=shift;
    my ($module,$in)=@_;
    if (ref($module->{config}) eq 'HASH'){
	if (ref($module->{config}->{output}) eq 'HASH'){
	    my $out=$module->{config}->{output};
	    foreach my $o (keys %{$out}){
		if (&StreamFileExists($out->{$o},$in)){
		    return 0;
		}
	    }
	}
    }
    return 1;
}

sub StreamFileExists{
    my ($out,$in)=@_;
    if (ref($out) ne 'HASH'){return 0;}
    if (ref($in) ne 'HASH'){return 0;}
    foreach my $a (@FileAttr){
	if (defined $out->{$a}){
	    if (defined $in->{$out->{$a}}){
		return 1;
	    }
	}
    }
    return 0;
}


sub checkPipeInput{
    my $self=shift;
    my ($module,$stdout,$out)=@_;

    if (not defined $out->{$stdout}){return 0;}
    if (ref($module->{config}) ne 'HASH'){return 0;}
    if (ref($module->{config}->{module}) ne 'HASH'){return 0;}
    if (not defined $module->{config}->{module}->{stdin}){return 0;}
    my $stdin=$module->{config}->{module}->{stdin};
    if (ref($module->{config}->{input}) ne 'HASH'){return 0;}

    if (&IsCompatible($module->{config}->{input}->{$stdin},
		      $out->{$stdout})){
	return 1;
    }
    return 0;
}


sub setPipeOutput{
    my $self=shift;
    my $output=shift;
    $self->{config}->{module}->{stdout}=$output;
}

sub setPipeInput{
    my $self=shift;
    my $input=shift;
    $self->{config}->{module}->{stdin}=$input;
}

sub pipeOutput{
    my $self=shift;
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{module}) eq 'HASH'){
	    if (defined $self->{config}->{module}->{stdout}){
		return $self->{config}->{module}->{stdout};
	    }
	}
	if (ref($self->{config}->{output}) eq 'HASH'){
	    foreach (keys %{$self->{config}->{output}}){
		if ($self->isStdin($self->{config}->{output}->{$_})){
		    return $_;
		}
	    }
	}
    }
    return undef;
}

sub pipeInput{
    my $self=shift;
    if (ref($self->{config}) eq 'HASH'){
	if (ref($self->{config}->{module}) eq 'HASH'){
	    if (defined $self->{config}->{module}->{stdin}){
		return $self->{config}->{module}->{stdin};
	    }
	}
#	if (ref($self->{config}->{input}) eq 'HASH'){
#	    foreach (keys %{$self->{config}->{input}}){
#		if ($self->isStdin($self->{config}->{input}->{$_})){
#		    return $_;
#		}
#	    }
#	}
    }
    return undef;
}

sub matchPreviousOutputWithInput{
    my $self=shift;
    my ($input,$prev)=@_;
    if (ref($input) eq 'HASH'){
	foreach (keys %{$input}){
	    if (defined $prev->{$_}){
		$self->changeConfig('input',$_,$prev->{$_});
	    }
	}
    }
}

sub saveInputFiles{
    my $self=shift;
    my $config=$self->{config};
    my ($input)=@_;

    foreach (keys %{$config->{input}}){                # save input files
	foreach my $a (@FileAttr){
	    if ($config->{input}->{$_}->{$a}){
		my $file=$config->{input}->{$_}->{$a};
		$input->{$file}=$a;
	    }
	}
    }
}

sub updateStreams{
    my $self=shift;
    my $streams=shift;
    if (ref($streams) ne 'HASH'){return;}
    my ($output)=@_;
    foreach (keys %{$streams}){                     # save streams
	if ($self->isStdout($streams->{$_})){
	    if (ref($output->{$_}) eq 'HASH'){
		if (not $output->{$_}->{'__stdout'}){
		    %{$output->{'__file'}->{$_}}=%{$output->{$_}};
		}
	    }
	    $streams->{$_}->{'__stdout'}=1;
	}
	%{$output->{$_}}=%{$streams->{$_}};
    }
}


sub updateOutputStreams{
    my $self=shift;
    my $config=$self->{config};
    if (ref($self->{config}) eq 'HASH'){
	$self->updateStreams($self->{config}->{input},@_);
	$self->updateStreams($self->{config}->{output},@_);
    }
}

sub setInputStreams{
    my $self=shift;
    my $config=$self->{config};
    my ($output)=@_;
    foreach (keys %{$config->{input}}){               # save input streams
	%{$output->{$_}}=%{$config->{input}->{$_}};
	if (defined $config->{input}->{$_}->{file}){
	    $output->{'__stdout'}->{$_}=$config->{input}->{$_}->{file};
	}
    }
}

sub changeConfig{
    my $self=shift;
    my ($cat,$subcat,$attr)=@_;
    if (ref($attr) eq 'HASH'){
	%{$self->{config}->{$cat}->{$subcat}}=%{$attr};
    }
    $self->save;
}


sub storeStreamConfig{
    my $self=shift;
    my $config=$self->{config};
    my ($input,$output)=@_;
    $self->saveInputFiles($input);
    $self->updateOutputStreams($output);
}

sub isStdout{
    my $self=shift;
    my $stream=shift;
    if (defined $stream->{'stream names'}){return 0;}
    if (defined $stream->{'stream name'}){return 0;}
    if ($stream->{format} eq 'collection'){return 0;}
    foreach (@FileAttr){
	if (defined $stream->{$_}){return 0;}
    }
    return 1;
}

sub isStdin{
    my $self=shift;
    return $self->isStdout(@_);
}

sub GetTempFileName{
    my $fh;
    my $file;
    do {$file=tmpnam();}
    until ($fh=IO::File->new($file,O_RDWR|O_CREAT|O_EXCL));
    $fh->close;
    return $file;
}

sub copyHash{
    my ($old,$new)=@_;
    my $VAR1;
    $Data::Dumper::Indent=0;
    $Data::Dumper::Terse=0;
    $Data::Dumper::Purity=1;
    my $string=Dumper($old);
    $new->{new}=eval $string;
    if (ref($new->{new}) eq 'HASH'){
	%{$new}=%{$new->{new}};
    }
}
