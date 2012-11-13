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



package Uplug::Config;

require 5.004;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use vars qw(%NamedIO);

use Data::Dumper;

$VERSION = 0.02;


@ISA = qw( Exporter);
@EXPORT = qw(&ReadConfig &WriteConfig &CheckParameter &GetNamedIO
	     &CheckParam &GetParam &SetParam);

## "named" IO streams are stored in %NamedIO
## read them from the files below (in ENV{UPLUGHOME}/ini)

&ReadNamed('DataStreams.ini');          # default "IO streams"
&ReadNamed('UserDataStreams.ini');      # user "IO streams"


#------------------------------------------------------------------------
# CheckParameter($config,$param,$file)
#   * config .... pointer to hash with default config
#   * param ..... command-line parameters (usually a pointer ot an ARRAY)
#   * file ...... config-file (replaces default config options)

sub CheckParameter{
    my ($config,$param,$file)=@_;

    if (ref($config) ne 'HASH'){$config={};}
    my @arg;
    if (ref($param) eq 'ARRAY'){@arg=@$param;}
    elsif($param=~/\S\s\S/){@arg=split(/\s+/,$param);}

    if (-e $file){
	my $new=&ReadConfig($file);
	$config=&MergeConfig($config,$new);
    }
    for (0..$#arg){                            # special treatment for the
	if ($arg[$_] eq '-i'){                 # -i argument --> config file
	    my $new=&ReadConfig($arg[$_+1]);
	    $config=&MergeConfig($config,$new);
	}
    }
    &CheckParam($config,@arg);

    return $config;
}


# $config = MergeConfig($config1,$config2)
#    copy all keys from $config2 to $config1 and return $config1

sub MergeConfig{
    my ($conf1,$conf2)=@_;
    if (ref($conf1) ne 'HASH'){return $conf1;}
    if (ref($conf2) ne 'HASH'){return $conf1;}
    for (keys %{$conf2}){
	$conf1->{$_}=$conf2->{$_};
    }
    return $conf1;
}


#------------------------------------------------------------------------
# read configuration files
#    - essentially this restores a Perl hash from a hash dump
#    - some variables are expanded before restoring (see ExpandVar)
#    - "named" IO streams are replaced with their expanded specifications
#    - command line arguments are expanded and set in the config hash 


sub ReadConfig{
    my $file=shift;
    my @param=@_;

    if (! -f $file){
	if (-f "$ENV{UPLUGHOME}/$file"){
	    $file = "$ENV{UPLUGHOME}/$file";
	}
	elsif (-f "$ENV{UPLUGHOME}/ini/$file"){
	    $file = "$ENV{UPLUGHOME}/ini/$file";
	}
	elsif (-f "$ENV{UPLUGHOME}/systems/$file"){
	    $file = "$ENV{UPLUGHOME}/systems/$file";
	}
	else{
	    warn "# Uplug::Config: config file '$file' not found!\n";
	}
    }

    open F,"<$file" || die "# Uplug::Config: cannot open file '$file'!\n";
    my @lines=<F>;
    my $text=join '',@lines;
    close F;
    $text=&ExpandVar($text);
    my $config=eval $text;
    &ExpandNamed($config);
    &CheckParam($config,@param);
    return $config;
}


#------------------------------------------------------------------------
# write configuration file
#    dump a perl hash into a text file (nothing else)

sub WriteConfig{
    my $file=shift;
    my $config=shift;

    open F,">$file" || die "# Config: cannot open '$file'!\n";

    $Data::Dumper::Indent=1;
    $Data::Dumper::Terse=1;
    $Data::Dumper::Purity=1;
    print F Dumper($config);
    close F;
}




#------------------------------------------------------------------------
# ExpandVar .... expand some special variables in config files
#
#  UplugHome   - Uplug home directory
#  UplugLang   - default directory for language specific data
#  UplugSystem - default directory for module configuration files
#  UplugData   - default directory for data files (= ./data)
#  UplugIni    - default directory for inital config files (DataStreams.ini)
#  UplugBin    - default directory for Uplug scripts (called by modules)


sub ExpandVar{
    my $configtext=shift;
    $configtext=~s/\$UplugHome/$ENV{UPLUGHOME}/gs;
    $configtext=~s/\$UplugLang/$ENV{UPLUGHOME}\/lang/gs;
    if (defined $ENV{UPLUGCONFIG}){
	$configtext=~s/\$UplugSystem/$ENV{UPLUGCONFIG}/gs;
    }
    else{
	$configtext=~s/\$UplugSystem/$ENV{UPLUGHOME}\/systems/gs;
    }
    $configtext=~s/\$UplugData/data/gs;
    $configtext=~s/\$UplugIni/$ENV{UPLUGHOME}\/ini/gs;
    $configtext=~s/\$UplugBin/$ENV{UPLUGHOME}\/bin/gs;
    return $configtext;
}


#------------------------------------------------------------------------
# ExpandNamed .... expand "named" IO streams
#
#   some input/output specifications are stored in ini/DataStreams.ini
#   this provides a shorthand for some standard I/O
#   (use attribute 'stream name' to point to one of the defined IO streams)
#
# ExpandNamed substitutes these shorthands in "input" and "output" in a 
# module configuration hash with the actual specifications
#

sub ExpandNamed{
    my $config=shift;
    my $input=GetParam($config,'input');
    if (ref($input) eq 'HASH'){
	for my $i (keys %$input){
	    if (ref($input->{$i}) eq 'HASH'){
		if (exists $input->{$i}->{'stream name'}){
		    $input->{$i}=&GetNamedIO($input->{$i});
		}
	    }
	}
    }
    my $output=GetParam($config,'output');
    if (ref($output) eq 'HASH'){
	for my $i (keys %$output){
	    if (ref($output->{$i}) eq 'HASH'){
		if (exists $output->{$i}->{'stream name'}){
		    $output->{$i}=&GetNamedIO($output->{$i});
		}
	    }
	}
    }
    return $config;
}

#------------------------------------------------------------------------
# GetNamedIO ... return specifications of a "named" IO stream

sub GetNamedIO{
    my $name=shift;
    my $spec={};
    if (ref($name) eq 'HASH'){
	$spec=$name;
	$name=$name->{'stream name'};
    }
    if (exists $NamedIO{$name}){
	my $conf=eval $NamedIO{$name};
	if (ref($conf) eq 'HASH'){
	    for (keys %$conf){
		if (exists $spec->{$_}){next;}
		$spec->{$_}=$conf->{$_};
	    }
	    delete $spec->{'stream name'};
	}
    }
    return $spec;
}


#------------------------------------------------------------------------
# CheckParam ... check command line parameters and modify the config hash
#                according to the given parameters
# possible command line arguments are specified in the config hash, either
# in { arguments => { shortcuts => { ... } } } or
# in { arguments => { optons => { ... } } }    or
# in { options => { ... } }
#
# example: define an option '-in file-name' for setting the file-name (=file)
#          of the input stream called 'text' with the following code:
#
#  { 'arguments' => {
#       'shortcuts' => {
#          'in' => 'input:text:file'
#       }
#  }
#
# if you use the flag '-in' its argument (e.g. 'my-file.txt') will be moved to
#    { input => { text => { file => my-file.txt } } }
# in the config hash
#


sub CheckParam{
    my $config=shift;

    if ((@_ == 1) && ($_[0]=~/\S\s\S/)){    # if next argument is a string with
	my @params=split(/\s+/,$_[0]);      # spaces: split it into an array
	return CheckParam($config,@params); #         and try again
    }

    my $flags=GetParam($config,'arguments','shortcuts');
    if (ref($flags) ne 'HASH'){
	$flags=GetParam($config,'arguments','options');
    }
    if (ref($flags) ne 'HASH'){
	$flags=GetParam($config,'options');
    }
#    return if (ref($flags) ne 'HASH');
    while (@_){
	my $f=shift;                        # flag name
	my @attr=();
	if ($f=~/^\-/){                     # if it is a short-cut flag:
	    $f=~s/^\-//;                    # delete leading '-'
	    if (exists $flags->{$f}){
		@attr=split(/:/,$flags->{$f});
	    }
	}
	else{                               # otherwise: long paramter type
	    @attr=split(/:/,$f);
	}
	my $val=1;                          # value = 1
	if ((@_) and ($_[0]!~/^\-/)){       # ... or next argument if it exists
	    $val=shift;
	}
	SetParam($config,$val,@attr);       # finally set the parameter!
    }
    return $config;
}    

#------------------------------------------------------------------------
# SetParam($config,@attr,$value) ... set a parameter in a config hash
#
#  $config is a pointer to hash
#  @attr   is a sequence of attribute names (refer to nested hash structures)
#  $value  is the value to be set

sub SetParam{
    my $config=shift;
    my $value=shift;    # value
    my $attr=pop(@_);   # attribute name

    if (ref($config) ne 'HASH'){$config={};}
    foreach (@_){
	if (ref($config->{$_}) ne 'HASH'){
	    $config->{$_}={};
	}
	$config=$config->{$_};
    }
    $config->{$attr}=$value;
}

#------------------------------------------------------------------------
# GetParam(config,@attr) ... get the value of a (nested attribute)

sub GetParam{
    my $config=shift;
    my $attr=pop(@_);
    foreach (@_){
	if (ref($config) eq 'HASH'){
	    $config=$config->{$_};
	}
	else{return undef;}
    }
    return $config->{$attr};
}


#------------------------------------------------------------------------
# ReadNamed .... read pre-defined IO streams from a file and store
#                the specifications in the global NamedIO hash

sub ReadNamed{
    my $file=shift;
    if (! -f $file){
	$file='ini/'.$file if (-f 'ini/'.$file);
	$file=$ENV{UPLUGHOME}.'/'.$file if (-f $ENV{UPLUGHOME}.'/'.$file);
	$file=$ENV{UPLUGHOME}.'/ini/'.$file 
	    if (-f $ENV{UPLUGHOME}.'/ini/'.$file);
    }
    if (! -f $file){return 0;}
    my $config=&ReadConfig($file);
    if (ref($config) eq 'HASH'){
	$Data::Dumper::Indent=1;
	$Data::Dumper::Terse=1;
	$Data::Dumper::Purity=1;
	for (keys %$config){
	    $NamedIO{$_}=Dumper($config->{$_});
	}
    }
    return 1;
}


## return a true value

1;
