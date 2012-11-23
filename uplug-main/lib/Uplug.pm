#-*-perl-*-
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

require 5.005;

use strict;
use IO::File;
use POSIX qw(tmpnam);
use Uplug::Config;
use File::Basename;

use vars qw($VERSION $DEBUG);
use vars qw(@TempFiles);


$VERSION = 0.02;
$DEBUG = 0;

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


sub new{
    my $class=shift;
    my $configfile=shift;

    my $self={};
    bless $self,$class;

    $self->{CONFIGFILE} = $configfile;
    $self->{CONFIG}     = &ReadConfig($configfile,@_);

    mkdir 'data',0755 if (! -d 'data');
    mkdir 'data/runtime',0755 if (! -d 'data/runtime');

    $self->{RUNTIMEDIR} = 'data/runtime/'.$$;
    mkdir $self->{RUNTIMEDIR},0755 if (! -d $self->{RUNTIMEDIR});

    return $self;
}

##---------------------------------------------------------------------
## DESTROY: clean up! remove all temporary files and directories!

sub DESTROY{
    my $self=shift;
    if ($DEBUG){exit;}
    unlink $self->{MODULE};
    if (ref($self->{TEMPFILES}) eq 'ARRAY'){
	unlink @{$self->{TEMPFILES}};
    }
    rmdir $self->{RUNTIMEDIR};
}

##---------------------------------------------------------------------
## load module configurations
##    * create runtime config files the module and all submodules

sub load{
    my $self=shift;

    my $count=1;
    my $runtime = $self->{RUNTIMEDIR}.'/';
    $runtime .= basename($self->{CONFIGFILE});
    while (-e $runtime.$count){$count++;}
    $self->{MODULE} = $runtime.$count;
    &WriteConfig($self->{MODULE},$self->{CONFIG});
    $self->loadSubMods();
    $self->data($self->output());   # my own data is available
}


##---------------------------------------------------------------------
## create config files for all sub-modules
##    * modify input/output according to the data in the module sequence
##    * check if I can use pipes (stdout -> stdin)
##    * expand loops

sub loadSubMods{
    my $self=shift;

    my $submod=&GetParam($self->{CONFIG},'module','submodules');
    my $loop=&GetParam($self->{CONFIG},'module','loop');
    my ($loopstart,$loopend)=split(/:/,$loop);
    my $iter=&GetParam($self->{CONFIG},'module','iterations');

    if (ref($submod) eq 'ARRAY'){
	$self->{SUBMOD}=[];             # initialize sub-module array
	my $count=1;                    # iteration counter

	my $input=$self->input;         # my input will be 
	my $data=$self->data($input);   # the initial data collection

	my $stdout;            # is defined if previous module produces STDOUT
	my $i=0;               # sub-module number
	my $n=0;               # module number in the sequence
	while ($i<@$submod){
	    if ((defined $iter) and ($count>$iter)){last;}
	    my ($conf,@par)=split(/\s+/,$submod->[$i]);
	    $i++ && next unless (-e $conf);               # skip modules without config
	    $self->{SUBMOD}->[$n]=Uplug->new($conf,@par); # check also params
	    $self->{SUBMOD}->[$n]->input($data);          # change input
#	    &CheckParam($self->{CONFIG},@par);            # check params again!
#	                                                  # (highest priority!)

	    ## check if stdout in last module but no stdin now
	    ## --> if yes: broken pipe!

	    my $broken=0;
	    my $stdin=$self->{SUBMOD}->[$n]->stdin();

	    if ($stdout and (not $stdin)){
		$broken = 1;
	    }

	    ## otherwise if STDIN and STDOUT:
	    ## check if any output file is in use
	    ## if yes --> broken pipe

	    elsif ($stdin and $stdout){
		my $out=$self->{SUBMOD}->[$n]->output();
		if (ref($out) eq 'HASH'){
		    for (keys %$out){
			if ((exists $out->{file}) and
			    $self->FileInUse($out->{file})){
			    $broken=1;
			    last;
			}
		    }
		}
	    }

	    ## if pipe is broken:
	    ##   * save to temp file if no file given
	    ##   * delete 'stdout' flag from config file

	    if ($broken){
		if (not &GetParam($self->{SUBMOD}->[$n-1]->{CONFIG},
				  'output',$stdout,'file')){
		    my $tmpfile=$self->NewTempFile();
		    &SetParam($self->{SUBMOD}->[$n-1]->{CONFIG},
			      $tmpfile,'output',$stdout,'file');
		    &SetParam($data,$tmpfile,'output',$stdout,'file');
		    $self->{SUBMOD}->[$n-1]->load();
		}
		&SetParam($self->{SUBMOD}->[$n-1]->{CONFIG},
			  undef,'module','stdout');
	    }

	    ## change input data according to available data-spec
	    ## load the current module

	    $self->{SUBMOD}->[$n]->load();              # load module

	    $stdout=$self->{SUBMOD}->[$n]->stdout();
	    my $new=$self->{SUBMOD}->[$n]->data();      # get new output
	    $data=$self->data($new);                    # set new data    

	    ## jump back to the loop start
	    ## (if a loop is defiend)

	    if ((defined $loopend) and ($i==$loopend)){
		$count++;
		$i=$loopstart-1;
	    }
	    $i++;$n++;
	}

	# if there is at least one submodule:
        # my output should be the one produced by the last submodule

	if (@$submod){
	    my $output=$self->output;
	    $self->{SUBMOD}->[-1]->output($output);
	    my $data=$self->data($output);
	}
	$self->data($data);
    }
}


##---------------------------------------------------------------------
## return a temporary file name (and touch it)

sub NewTempFile{
    my $self=shift;
    my $count=0;
    my $temp = $self->{RUNTIMEDIR}.'/.temp';
    while (-e $temp.$count){
	$count++;
    }
    $temp.=$count;
    open F,">$temp";close F;
    push (@{$self->{TEMPFILES}},$temp);
    return $temp;
}



##---------------------------------------------------------------------
## return the system command to be called for this Uplug module
##   (including all sub-modules, pipes, ...)

sub command{
    my $self=shift;
    my $stdout=shift;

    if (ref($self->{SUBMOD}) eq 'ARRAY'){
	my $cmd;

	my $loop=&GetParam($self->{CONFIG},'module','loop');
	my ($loopstart,$loopend)=split(/:/,$loop);
	my $iter=&GetParam($self->{CONFIG},'module','iterations');
	my $count=0;

	for my $s (@{$self->{SUBMOD}}){
	    my $c=$s->command($cmd,$stdout);
	    my $stdin=$s->stdin();
	    if ($stdout and $stdin){
		$cmd.=' | '.$c;
	    }
	    elsif ($cmd){$cmd.=';'.$c;}
	    else{$cmd=$c;}
	    $stdout=$s->stdout;
	}
	return $cmd;
    }
    my $bin=&GetParam($self->{CONFIG},'module','location');
    my $cmd=&GetParam($self->{CONFIG},'module','program');
    if (-d $bin){$cmd=$bin.'/'.$cmd;}
    $cmd.=' -i '.$self->{MODULE};

    if ($DEBUG){
	$cmd='perl -d:DProf '.$cmd;
    }

    return $cmd;
}



##---------------------------------------------------------------------
## run the Uplug module (and all its submodules)
##    * get the system command
##    * split it up into separate system calls
##    * run the system calls and print elapsed time/call

sub run{
    my $self=shift;
    my $cmd=$self->command();
    my @seq=split(/;/,$cmd);     # split command sequence
    my $start=time();
    for (@seq){
        my $time=time();
        print STDERR "$_\n---------------------------------------------\n";
	if (my $sig=system ($_)){
            print STDERR "# Uplug.pm: Got signal $? from child process:\n";
            print STDERR "# $_\n";
            return 0;
        }
        $time=time()-$time;
        my ($sec,$min,$hour,$mday,$mon,$year)=gmtime($time);
        printf STDERR
            "      processing time: %2d:%2d:%2d:%2d:%2d:%2d\n",
            $year-70,$mon,$mday-1,$hour,$min,$sec;
    }
    $start=time()-$start;
    my ($sec,$min,$hour,$mday,$mon,$year)=gmtime($start);
    printf STDERR
	"      total processing time: %2d:%2d:%2d:%2d:%2d:%2d\n",
	$year-70,$mon,$mday-1,$hour,$min,$sec;
}


##---------------------------------------------------------------------
## change input settings in the module configuraton
##    (only for the ones that exist already)
## and write changes to the physical config file

sub input{
    my $self=shift;
    my ($input)=@_;
    if (ref($input) eq 'HASH'){
	foreach (keys %$input){
	    if (&GetParam($self->{CONFIG},'input',$_)){
		&SetParam($self->{CONFIG},$input->{$_},'input',$_);
	    }
	    $self->{DATA}->{$_}=$input->{$_};
	}
	&WriteConfig($self->{MODULE},$self->{CONFIG});
    }
    return &GetParam($self->{CONFIG},'input');
}

##---------------------------------------------------------------------
## change output settings in the module configuraton
##    (only for the ones that exist already)
## and write changes to the physical config file

sub output{
    my $self=shift;

    my ($output)=@_;
    if (ref($output) eq 'HASH'){
	foreach (keys %$output){
	    if (&GetParam($self->{CONFIG},'output',$_)){
		&SetParam($self->{CONFIG},$output->{$_},'output',$_);
	    }
	    $self->{DATA}->{$_}=$output->{$_};
	}
	&WriteConfig($self->{MODULE},$self->{CONFIG});
    }
    return &GetParam($self->{CONFIG},'output');
}


##---------------------------------------------------------------------
## set/return available data
##   (here we store al kinds of data available in the module sequence)

sub data{
    my $self=shift;
    my ($data)=@_;
    if (ref($data) eq 'HASH'){
	foreach (keys %$data){
	    $self->{DATA}->{$_}=$data->{$_};
	}
    }
    if (ref($self->{DATA}) eq 'HASH'){              # save open files
	for my $d (keys %{$self->{DATA}}){          # (to check pipe-conflicts)
	    if (exists $self->{DATA}->{$d}->{file}){
		$self->{FILES}->{$self->{DATA}->{$d}->{file}}=1;
	    }
	}
    }
    return $self->{DATA};
}

sub FileInUse{
    my $self=shift;
    return $self->{FILES}->{$_[0]};
}


##---------------------------------------------------------------------
# stdin: returns input name if there is one that reads from stdin
#        (looks at {module => {stdin => '...'}}
#         and the definition of the input stream (check 'file' attr))
#        returns undef if no input defined that reads from STDIN

sub stdin{
    my $self=shift;
    my $in=&GetParam($self->{CONFIG},'module','stdin');
    if (&GetParam($self->{CONFIG},'input',$in)){
	if (not &GetParam($self->{CONFIG},'input',$in,'file')){
	    return $in;
	}
    }
    return undef;
}

##---------------------------------------------------------------------
# stdout: same as stdin but for STDOUT

sub stdout{
    my $self=shift;
    my $out=&GetParam($self->{CONFIG},'module','stdout');
    if (&GetParam($self->{CONFIG},'output',$out)){
	if (not &GetParam($self->{CONFIG},'output',$out,'file')){
	    return $out;
	}
    }
    return undef;
}



1;
