#!/usr/bin/perl
#
# usage:
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
# $Id$
#

require 5.002;

# use lib '/local/lib/perl5.OLD/site_perl/';

use English;
use Tk;
use strict;

my $___Perl2Exe=0;
if ($___Perl2Exe){&LoadLibFiles;}

use FindBin qw($Bin);
use lib "$Bin/..";
use Uplug::Data;
use Uplug::IO::Any;
use Uplug;
use Uplug::Config;

use Tk::Dialog;
use Tk::ErrorDialog;
# use Tk::FileDialog;

my $__UPLUG="$Bin/../uplug";


# require ('UplugLib.pl');
# require ('lib/UplugLib.pl');
# require('lib/GUILib.pl');                # Tk fcts (file handling ...)
# require('GUILib.pl');                    # Tk fcts (file handling ...)

#------------------------------------------------------------------------
# some settings for this uplug version ...
#------------------------------------------------------------------------

my $UPlugVersion='$RCSfile$ $Revision$ ';
my $UPlugDate='$Date$ ';

my $WindowTitle=$UPlugVersion;
my $__ALLOWTOADDPARAMETER=0;
my $__ALLOWTODELETEPARAMETER=0;
my $__ALLOWNEWSTREAM=0;
my $__EDITINIFILE=0;
my $__READCONFIGURATION=0;
my $__EDITCONFIGURATION=0;
my $__CHANGEINIDIRALLOWED=0;
my $__EDITSTREAMCONFIG=0;
my $CHANGEFONTALLOWED=0;
my $BoldFont='-*-Helvetica-Bold-R-Normal--*-180-*-*-*-*-*-*/';

my $SHOW_ALL_RELATED=1;
my $SHOWMAXDATA=30;                     # show maximal ... data records
my $MAXWIDTH=100;                        # maximal width for show stream data
 

my $__PLUGBINDIR="$Bin";                        # location of PLUG binaries
my $__PLUGHOME=$ENV{'UPLUGHOME'};               # PLUG home directory
my $__PLUGLIBDIR="$ENV{'PLUGHOME'}lib";        # location of PLUG libraries
my $__PLUGINIDIR="$ENV{'PLUGHOME'}ini";        # location of PLUG inifiles
my $__PLUGDATADIR="$ENV{'PLUGHOME'}data";      # location of PLUG data
my $__PLUGSYSTEMDIR="$ENV{'PLUGHOME'}systems"; # location of PLUG systems
my $__PLUGMODULEDIR="$ENV{'PLUGHOME'}modules"; # location of PLUG modules

#---------------------------------------------------------------------
# check arguments
#

my %GuiIni=&GetDefaultIni;
&CheckParameter(\%GuiIni,\@ARGV,"$__PLUGINIDIR/UplugGUI.ini");
my %UplugIni=();
#&CheckParameter(\%UplugIni,\@ARGV,"$__PLUGINIDIR/Uplug.ini");
&CheckParameter(\%UplugIni,\@ARGV,"$__PLUGSYSTEMDIR/main");


if ($GuiIni{'-load_defaults'}){        # reload default configuration
    &ReloadDefaults;                   # NOTE!! overwrites old config files!!!
}
else{&InitLocalUplugConfig;}
&CheckParameter(\%GuiIni,\@ARGV,"$__PLUGINIDIR/UplugGUI.ini");
&CheckParameter(\%UplugIni,\@ARGV,"$__PLUGINIDIR/Uplug.ini");
&ExpandHash(\%GuiIni);
&ExpandHash(\%UplugIni);


my $__UPLUGScript=$__UPLUG;
$__UPLUGScript=~s/(.*\s)(\S*)$/$2/;
my $__UPLUGPrefix=$1;

if (not -e $__UPLUGScript){                        # if Uplug program not
    $__UPLUGScript=~s/^.*([\/\\][^\/\\]*)$/$1/;    # found --> look in
    $__UPLUGScript="$__PLUGBINDIR/$__UPLUGScript"; # Uplug bin directory!
    $__UPLUG=$__UPLUGPrefix.$__UPLUGScript;
}
$__UPLUG.=" -i $__PLUGINIDIR/Uplug.ini";

my $PlugShell=$GuiIni{tools}{shell};     # name of shell to start Plug.pl in

my %XPlugSystem;                         # hash of systems
my @PlugSystem;                          # list of PlugSystems to be shown
                                         #     in the menu-bar
my %XTools;                              # hash of tools (Tk functions)
my %Tools;                               # hash of tools (scripts ...)
my $OpenedSystem;                        # name of currently opened system
my @ParentSystems;
my %ToolButton;
my %SkipModule;                          # array of modules to be skipped
my %ParameterWidget,
my %ParameterWidgetLabel;
my %ParameterWidgetFrame;

&SetGuiParameter;


if (ref($UplugIni{modules}) eq 'HASH'){
    @PlugSystem=sort keys %{$UplugIni{modules}};
}
my %ModuleConfig=();

###############################################################
#   create new main window
###############################################################

my $MW = MainWindow->new;               # create main window
$MW->title($WindowTitle);               # with this title
$MW->resizable(0,0);                    # don't allow to change window size

# &SetMainWindowHandle(\$MW);             # set window handle in XPlugLib.pl

###############################################################
# create menu bar
###############################################################

my $menuBar = $MW->Frame(-relief => 'raised', -borderwidth => 2);
$menuBar->pack(-side => 'top', -fill => 'x');

###############################################################
# 'file' menu
###############################################################

my $menuBar_file = $menuBar->Menubutton(
    -text      => 'file',
    -underline => 0,
);


$menuBar_file->command(                        # view an ASCII file
    -label     => 'view',                      # with command buttons for
    -underline => 0,                           # every 'Tool' (specified in
    -command   => [\&GetFileAndEdit,\$MW]      # 'XPlug.ini')
);
$menuBar_file->separator;
$menuBar_file->command(                        # leave the program
    -label     => 'quit',                      # but save some configuration
    -underline => 0,                           # data first
    -command   => \&UplugQuit,
		      );

$menuBar_file->pack(-side => 'left');


###############################################################
# 'stream' menu
###############################################################

my $menuBar_stream = $menuBar->Menubutton(
    -text      => 'stream',
    -underline => 2,
);

$menuBar_stream->command(
    -label     => 'show stream data',          # open a stream
    -underline => 0,                           # from the list of stream-defs
    -state     => 'disabled',
    -command   => sub{                         # in PlugIO.ini and read
	my %stream;                            # data from it
	if (&OpenNewStream(\$MW,\%stream)){
	    &ShowStreamData(\$MW,\%stream,1);  # (XPlugLib.pl function)
	}
    }
);

my %OpenedStream;
$menuBar_stream->command(
    -label     => 'open stream',               # open a stream
    -underline => 0,                           # from the list of stream-defs
    -state     => 'disabled',
    -command   => sub{                         # in PlugIO.ini but don't read
	%OpenedStream=();                      # from stream
	if (&OpenNewStream(\$MW,\%OpenedStream)){
	    &ShowStreamData(\$MW,\%OpenedStream);
	}
    }
);
$menuBar_stream->separator;
$menuBar_stream->command(
    -label     => 'add stream specification',
    -underline => 0,
    -state     => 'disabled',
    -command   => [\&AddStream]
);

$menuBar_stream->pack(-side => 'left');


###############################################################
# 'systems' menu
###############################################################

my $menuBar_system = $menuBar->Menubutton(-text => 'systems', -underline => 0);
$menuBar_system->cascade(
    -label     => 'open system',
    -underline => 0,
			 );
my $menuBarHandle = $menuBar_system->cget(-menu);     # handle to menu bar
my $menu_allSystems = $menuBarHandle->Menu;
$menuBar_system->entryconfigure('open system',
				-menu => $menu_allSystems);
my $system;

foreach $system (@PlugSystem){                        # create menu entry for

#    if (not &IsHidden($IniData{'systems'},$system)){
    $menu_allSystems->command(                    # each Plug system
	      -label     => $system,                  # from Plug.ini
	      -underline => 0,
	      -command   => sub{
		  @ParentSystems=();
		  &OpenSystem($system);
	      },
			      );
#    }
}

$menuBar_system->command(
    -label     => 'close system',                     # close opened system
    -underline => 0,
    -command   => [\&CloseSystem],
			 );
$menuBar_system->pack(-side => 'left');

$menuBar_system->separator;

$menuBar_system->command(
    -label     => 'create system',
    -underline => 1,
    -state     => 'disabled',
    -command   => [\&CreateSystem]
			 );

$menuBar_system->command(
    -label     => 'add module',
    -underline => 0,
    -state     => 'disabled',
    -command   => [\&AddModule]
			 );
$menuBar_system->pack(-side => 'left');


###############################################################
# 'tools' menu
###############################################################

my $toolsMenu = $menuBar->Menubutton(-text => 'tools', 
				     -underline => 0);
my $tool;
foreach $tool (sort keys %XTools){                         # create menu entry
    require ($XTools{$tool}{'filename'});             # for every Tk tool
    $toolsMenu->command(                              # (XLexEx modules ...)
	    -label       => $XTools{$tool}{'label'},
	    -command     => sub{
		my $command= '&'.$XTools{$tool}{'command'}.'(\$MW';
		if (defined $XTools{$tool}{'parameter'}){
		    $command.=','.$XTools{$tool}{'parameter'};
		}
		$command.=')';
#		print "$command\n";
		eval $command;
	    },
#            -state     => 'disabled',
#	    -underline   => 0,
			);
}
$toolsMenu->pack(-side=>'left');

###############################################################
# 'configurations' menu
###############################################################

my $menuBar_confi = $menuBar->Menubutton(
    -text      => 'configurations',
    -underline => 0,
);
&AddGuiParamMenu($menuBar_confi,'module frame');
&AddGuiParamMenu($menuBar_confi,'submodule frame');

#$menuBar_confi->cascade(
#    -label     => 'module frame',
#    -underline => 0,
#			 );
#my $menuBarHandle = $menuBar_confi->cget(-menu);     # handle to menu bar
#my $menu_confi_module = $menuBarHandle->Menu;
#$menuBar_confi->entryconfigure('module frame',
#				-menu => $menu_confi_module);
#&AddGuiParamMenu($menu_confi_module,$GuiIni{'module frame'});
#$menuBar_confi->cascade(
#    -label     => 'submodule frame',
#    -underline => 0,
#			 );
#my $menu_confi_sub = $menuBarHandle->Menu;
#$menuBar_confi->entryconfigure('submodule frame',
#				-menu => $menu_confi_sub);
#&AddGuiParamMenu($menu_confi_sub,$GuiIni{'submodule frame'});

#------------------------------------------------------------------------
# add external tools
#------------------------------------------------------------------------

$menuBar_confi->command(
    -label     => 'add tool',
    -state     => 'disabled',
    -underline => 4,
    -command   => sub{
	&AddXTool(\$MW,\$toolsMenu);
    },
			);
$menuBar_confi->command(
    -state     => 'disabled',
    -label     => 'add file tool',
    -underline => 4,
    -command   => sub{
	&AddTool(\$MW);
    },
			);

$menuBar_confi->pack(-side => 'left');


###############################################################
# 'help' menu
###############################################################

my $menuBar_help = $menuBar->Menubutton(
    -text      => 'help',
    -underline => 0,
);

$menuBar_help->command(
    -label     => 'about Uplug',
    -underline => 0,
    -command   => [\&AboutDialog,\$MW],
		       );
$menuBar_help->pack(-side => 'right');





###############################################################
#
# System Frame
#
#
###############################################################

my $SystemFrame;                           # the main frame
my %SystemConfig;                          # button for calling module config
my ($SystemStart,$SystemClose);            # command button 'start' & 'close'
my %ModuleWidget;                          # module-config-widgets
my %SystemModuleFrame;                     # frames for every module
my %SystemShowStream;                      # 'show stream data' buttons
my %ModuleIniData;                         # configuration for every module
                                           # in every system

my $CurrentLoop;                        # current loop iteration
my $CurrentLoopScale;                   # scale widget for $CurrentLoop
my $LoopIniExt;                         # extender for ini-files in loops
my $LoopFrame;                          # handle for loop-frame
my $LoopIterationScale;                 # scale widget for loop iterations


# open last referenced system if specified in UplugGUI.ini

$SystemFrame = $MW->Frame;
$SystemFrame->pack;
if (defined $GuiIni{'sessions'}{'last session'}{'system'}){
    &OpenSystem($GuiIni{'sessions'}{'last session'}{'system'},
		$GuiIni{'sessions'}{'systems'}{'show input stream buttons'},
		$GuiIni{'sessions'}{'systems'}{'show output stream buttons'});
}
else{
    if (defined $GuiIni{'logotypes'}{'general'}{'logo'}){
	my $pic=$GuiIni{'logotypes'}{'general'}{'logo'};
	if (-s $pic){
	    my $SystemLogoFrame=$SystemFrame->Frame;
	    $SystemLogoFrame->pack(-side => 'left');
	    my $SystemLogo=$SystemLogoFrame->Photo(-file => $pic);
	    $SystemLogoFrame->Label(-image => $SystemLogo)
		->pack(qw(-side left));
	}
    }

    foreach $system (@PlugSystem){
#	if (not &IsHidden($IniData{'systems'},$system)){
	    my $SystemButton = $SystemFrame->Button(
	       -width => 25,
               -text    => $system,
	       -command => [\&OpenSystem,$system]
               );
	    $SystemButton->pack(qw(-side top -expand 1));
#	}
    }
}



###############################################################
# Main Loop
###############################################################

&MainLoop;


###############################################################
# create a new system
###############################################################

sub CreateSystem{
}


###############################################################
# add a new stream specification to UplugIO.ini (UserStrm.ini)
###############################################################

sub AddStream{
    my $name;
    my $IOiniFile=$__PLUGINIDIR.'/UplugIO.ini';
    my %IOiniData;
    &LoadIniData(\%IOiniData,$IOiniFile);
    if ($name=&GetStringDialog(\$MW,'stream name')){
	if (defined $IOiniData{'stream specifications'}{$name}){
	    &message(\$MW,"stream $name exists already!");
	    return 0;
	}
	my %NewStream=('format' => 'unknown',
		       'stream name' => 'new',
		       'hide' => '(hide,stream name,id)');
	if (&SpecifyStreamDialog(\$MW,\%NewStream,'specify stream')){
	    my $UserIniFile=$__PLUGINIDIR.'/UserStrm.ini';
	    my %NewIni;
	    $NewIni{'stream specifications'}{$name}=\%NewStream;
	    &WriteAll2IniFile($UserIniFile,\%NewIni);
	    &InitializeUplugIO;
#	    if (not &IsHidden(%NewStream)){
		my $UserIniFile=$__PLUGINIDIR.'/UserLib.ini';
		&Write2IniFile($UserIniFile,
			       'attribute options',
			       'general',
			       'stream name',
			       $name);
		&ReadUplugLibIni;
#	    }
	}
    }
}



###############################################################
# add a module
###############################################################

sub AddModule{
}

sub GetAllModules{
}

###############################################################
# add a script (specifications will be stored in XPlug.ini)
###############################################################

sub AddTool{
}

###############################################################
# add Tk function (specifications will be stored in XPlug.ini)
###############################################################

sub AddXTool{
}


#-----------------------------------------------------------------------
#
# initialize a UPlug system
#
#-----------------------------------------------------------------------

sub InitializeSystem{

    my $system=shift;                          # set the
    my ($IniData,$ModuleData)=@_;              # stream specifications
    my %DataStreams=();                        # for the sequence of
                                               # modules in the system
#-----------------------------------------------------------------------
# 1) save 'skip module' array in %SkipModule
#-----------------------------------------------------------------------

    foreach (keys %SkipModule){
	$SkipModule{$_}=0;
    }
    foreach (@{$$IniData{'systems'}{$system}{'skip modules'}}){
	$SkipModule{$_}=1;
    }

#-----------------------------------------------------------------------
# 2) read module configurations
#-----------------------------------------------------------------------

    my $module;
    my $IniFile;
    foreach $module (@{$XPlugSystem{$OpenedSystem}}){

	$IniFile=
	    "$$IniData{'systems'}{$system}{'configdir'}\/".
		$$IniData{'modules'}{$module}{'configuration'};
	if (not (-s $IniFile)){
	    $IniFile=
		"$__PLUGINIDIR\/".
		$$IniData{'modules'}{$module}{'configuration'};
	}

	%{$$ModuleData{$system}{$module}}=
	    &ReadIniFile($IniFile);

	if ($SkipModule{$module}){next;}

#-----------------------------------------------------------------------
# 3) set input stream specifications
#-----------------------------------------------------------------------

	my $changed=0;
	foreach (keys %{$$ModuleData{$system}{$module}{'input'}}){
	    if (exists $DataStreams{$_}){
		%{$$ModuleData{$system}{$module}{'input'}{$_}}=
		    %{$DataStreams{$_}};
		$changed=1;
#		print "changed $_ in $module\n";
	    }
	}
	foreach (keys %{$$ModuleData{$system}{$module}{'input'}}){
	    %{$DataStreams{$_}}=
		%{$$ModuleData{$system}{$module}{'input'}{$_}};
	}

#-----------------------------------------------------------------------
# 4) set output stream specifications
#-----------------------------------------------------------------------

	foreach (keys %{$$ModuleData{$system}{$module}{'output'}}){
	    %{$DataStreams{$_}}=
	    %{$$ModuleData{$system}{$module}{'output'}{$_}};

	}

#-----------------------------------------------------------------------
# write module configuration if any changes were made
#-----------------------------------------------------------------------

	if ($changed){
		&WriteAll2IniFile($IniFile,
				  \%{$$ModuleData{$system}{$module}});
	}
    }
}


########################################################################

#-----------------------------------------------------------------------
#
# start a plug system
#
#-----------------------------------------------------------------------

sub GetSubModules{
    my ($data)=@_;
    if (ref($data->{module}) eq 'HASH'){
	if (ref($data->{module}->{submodules}) eq 'ARRAY'){
	    return @{$data->{module}->{submodules}};
	}
    }
    return ();
}
sub GetSkipModules{
    my ($data)=@_;
    if (ref($data->{module}) eq 'HASH'){
	if (ref($data->{module}->{skip}) eq 'ARRAY'){
	    return @{$data->{module}->{skip}};
	}
    }
    return ();
}

sub SaveSkipModules{
    my ($System,$IniData,$SkipModules)=@_;

    my @modules=&GetSubModules($IniData->{$System});
    my @skip=();
    foreach (0..$#modules){
	if ($SkipModules->{$modules[$_]}){
	    push(@skip,$_);
	}
    }
    if (ref($IniData->{$System}) eq 'HASH'){
	if (ref($IniData->{$System}->{module}) eq 'HASH'){
	    $IniData->{$System}->{module}->{skip}=[];
	    @{$IniData->{$System}->{module}->{skip}}=@skip;
	    print STDERR "$System: ";
	    print STDERR join ":",@skip;
	    print STDERR "\n";
#	    &SaveModuleConfig($System,$IniData,$UplugIni);
	}
    }
}

sub StartPlugSystem{
    my ($System,$IniData,$SkipModules,$StopAtModule)=@_;
    my $IniFile=$System;

    &SaveModuleConfig($System,$IniData,\%UplugIni,$SkipModules);

    my $LogFile;
    if ($$IniData{'systems'}{$System}{'write logfile'}){
	if ($$IniData{'systems'}{$System}{'logfile'}){
	    $LogFile.=$$IniData{'systems'}{$System}{'logfile'};
	}
    }

    my $command="$PlugShell $__UPLUG ";
    if (($PlugShell=~/\S/) and ($PlugShell!~/xterm/)){
	$command="$PlugShell '$__UPLUG ";
    }
    if (defined $StopAtModule){
	$command.=" -l $StopAtModule";
    }
    $command.=" '".$System."'";
    if ($LogFile=~/\S/){$command.=" 2>$LogFile &";}
    else{$command.=" &";}
    if (($PlugShell=~/\S/) and ($PlugShell!~/xterm/)){
	$command.="'";
    }
    print STDERR "$command\n\n";
    system $command;
}


#-----------------------------------------------------------------------
# view the log file for the current system
#-----------------------------------------------------------------------

sub ViewLogFile{
    my ($System,$IniData,$WH)=@_;
    my $LogFile;
    if (not defined ($LogFile=$$IniData{'systems'}{$System}{'logfiledir'})){
	$LogFile=$$IniData{'systems'}{$System}{'configdir'};
    }
    $LogFile.='/';
    $LogFile.=$$IniData{'systems'}{$System}{'logfile'};
    if (-e $LogFile){
	&ShowFile(\$WH,$LogFile);
    }
}





########################################################################

sub InitSkipModules{
    my ($config,$skip)=@_;
    my @modules=&GetSubModules($config);
    my @skip=&GetSkipModules($config);
    foreach (@skip){
	$skip->{$modules[$_]}=1;
    }
}


#-----------------------------------------------------------------------
#
# open a UPlug system and create the 'system frame'
#
# usage: &OpenSystem($module)
#             $module ...... module name OR module config file
#
#-----------------------------------------------------------------------

sub OpenSystem{

#-----------------------------------------------------------------------
# close currently opened system (if there is any)
#-----------------------------------------------------------------------

    if ($OpenedSystem){
	push (@ParentSystems,$OpenedSystem);
	&SaveModuleConfig($OpenedSystem,\%ModuleConfig,
			  \%UplugIni,\%SkipModule);
	my $module;
	foreach $module (@{$XPlugSystem{$OpenedSystem}}){
	    if (exists $SystemConfig{$module}){
		$SystemConfig{$module}->destroy;    # destroy all module frames
	    }
	    if (exists $SystemModuleFrame{$module}){
		$SystemModuleFrame{$module}->destroy;
	    }
	}
    }
    foreach (keys %SkipModule){
	$SkipModule{$_}=0;
    }
    $OpenedSystem=shift;                            # set new system

#-----------------------------------------------------------------------
# create new system frame
#-----------------------------------------------------------------------

    $SystemFrame->destroy;                          # destroy old system frame
    $SystemFrame = $MW->Frame;
    $SystemFrame->pack(qw(-side bottom -fill x -expand 1));

#-----------------------------------------------------------------------
# system label and checkbox for writing a logfile
#-----------------------------------------------------------------------

    my $SystemNameFrame = $SystemFrame->Frame;
    $SystemNameFrame->pack(qw(-side top -fill x));
    my $SystemNameLabel = $SystemNameFrame->Label(-font => $BoldFont,
					       -text => $OpenedSystem);

    if (defined $GuiIni{'logotypes'}{'systems'}{$OpenedSystem}){
	my $pic=$GuiIni{'logotypes'}{'systems'}{$OpenedSystem};
	my $SystemLogo=$SystemNameFrame->Photo(-file => $pic);
	$SystemNameFrame->Label(-image => $SystemLogo)
	    ->pack(qw(-side left));
    }

    $SystemNameLabel->pack(-side => 'top',
			   -expand => '1');

    &LoadModuleConfig($OpenedSystem,\%ModuleConfig,\%UplugIni);
    &InitSkipModules($ModuleConfig{$OpenedSystem},\%SkipModule);
    my $config=$ModuleConfig{$OpenedSystem};

#-----------------------------------------------------------------------
# initialize the system
#-----------------------------------------------------------------------

    my $module=$OpenedSystem;
    my $modName=$module;
    if (defined $$config{module}{name}){
	$modName=$$config{module}{name};
    }

    $ModuleWidget{$module}{'frame'}=
	$SystemFrame->Frame(
			    -relief => 'sunken',
			    -bd => 2);
    $ModuleWidget{$module}{'frame'}->pack(-side => 'top',-fill => 'x');

    if ($GuiIni{'module frame'}{'show input'}){
	if (ref($$config{input}) eq 'HASH'){
	    $ModuleWidget{$module}{'inputframe'}=
		$ModuleWidget{$module}{'frame'}->Frame;
	    $ModuleWidget{$module}{'inputframe'}->pack(
						       -fill => 'x',
						       -expand => 1,
						       -side => 'top');
	    $ModuleWidget{$module}{'inlabel'}=
		$ModuleWidget{$module}{'inputframe'}->Label(
		-text => 'input',
		-width => 10);
	    $ModuleWidget{$module}{'inlabel'}->pack(-side => 'left');

	    &ViewStreamButtons($ModuleWidget{$module}{'inputframe'},
			       $$config{input},
			       'left',
			       \&ShowStream,\$MW);
	}
    }


#-----------------------------------------------------------------------

    if ($GuiIni{'module frame'}{'show parameter'}){
	if (ref($config->{widgets}) eq 'HASH'){
	    my $SubFrame=$SystemFrame->Frame;
	    $SubFrame->pack(-side => 'top',-fill => 'x',);
	    my $SubLabel=$SubFrame->Label(
		-text => 'parameter',
		-width => 10);
	    $SubLabel->pack(-side => 'left');
	    my $SubModFrame=$SubFrame->Frame;
	    $SubModFrame->pack(-side => 'left');
	    &ParameterWidgets($SubModFrame,
			      $config->{widgets},$config,'top');
	}
    }

#-----------------------------------------------------------------------

    if ($GuiIni{'module frame'}{'show submodules'}){
	if (ref($config->{module}->{submodules}) eq 'ARRAY'){
	    my $SubFrame=$SystemFrame->Frame;
	    $SubFrame->pack(-side => 'top');
	    my $SubLabel=$SubFrame->Label(
		-text => 'sub',
		-width => 10);
	    $SubLabel->pack(-side => 'left');
	    my $SubModFrame=$SubFrame->Frame;
	    $SubModFrame->pack(-side => 'left');
	    &CreateSubModuleFrames($SubModFrame,$config);
	}
    }

#-----------------------------------------------------------------------
# cerate module frame with a label and output stream buttons
#-----------------------------------------------------------------------

    $module=$OpenedSystem;
    my $modName=$module;
    if (defined $$config{module}{name}){
	$modName=$$config{module}{name};
    }

    $ModuleWidget{$module}{'frame'}=
	$SystemFrame->Frame(
			    -relief => 'sunken',
			    -bd => 2);
    $ModuleWidget{$module}{'frame'}->pack(-side => 'top',-fill => 'x');

    if ($GuiIni{'module frame'}{'show output'}){
	if (ref($$config{output}) eq 'HASH'){
	    $ModuleWidget{$module}{'outputframe'}=
		$ModuleWidget{$module}{'frame'}->Frame;
	    $ModuleWidget{$module}{'outputframe'}->pack(
						       -fill => 'x',
						       -expand => 1,
						       -side => 'top');
	    $ModuleWidget{$module}{'outlabel'}=
		$ModuleWidget{$module}{'outputframe'}->Label(
		-text => 'output',
		-width => 10);
	    $ModuleWidget{$module}{'outlabel'}->pack(-side => 'left');

	    &ViewStreamButtons($ModuleWidget{$module}{'outputframe'},
			       $$config{output},
			       'left',
			       \&ShowStream,\$MW);
	}
    }


#-----------------------------------------------------------------------
# write log-file button
#-----------------------------------------------------------------------

    my $LogFileFrame = $SystemFrame->Frame;
    $LogFileFrame->pack(qw(-side top));

    my $WriteLogFileButton=
	$LogFileFrame->Checkbutton(
            -text     => 'write log file',
	    -variable => \$ModuleConfig{$OpenedSystem}{module}{'write logfile'},
	    -relief   => 'flat');
    $WriteLogFileButton->pack(-side => 'top');

#-----------------------------------------------------------------------

    my $ConfigButton=$SystemFrame->Button(
                       -text    => 'settings',
#                       -state   => 'disabled',
                       -command => [\&ChangeSettings,
				    \$MW,$config,$OpenedSystem,
				    \%UplugIni],
                   );
    if (not &ParameterExist($config)){
	$ConfigButton->configure(qw(-relief flat -state disabled));
    }
    $ConfigButton->pack(qw(-side left -expand 1));
	

#-----------------------------------------------------------------------
# create button for starting the system
#-----------------------------------------------------------------------

    my $SystemButtons = $SystemFrame->Frame;
    $SystemButtons->pack(qw(-side bottom -fill x -pady 2m));
    $SystemStart = $SystemButtons->Button(
        -text    => 'start system',
        -command => [\&StartPlugSystem,
		     $OpenedSystem,
		     \%ModuleConfig,
		     \%SkipModule],
    );
    $SystemStart->pack(qw(-side left -expand 1));

#-----------------------------------------------------------------------
# create a button for viewing the logfile
#-----------------------------------------------------------------------

    my $ViewLog;
    if ($ModuleConfig{$OpenedSystem}{module}{'logfile'}){
	$ViewLog = $SystemButtons->Button(
            -text    => 'view logfile',
            -command => [\&ViewLogFile,
			 $OpenedSystem,
			 \%UplugIni,
			 $MW],
	);
	$ViewLog->pack(qw(-side left -expand 1));
    }

#-----------------------------------------------------------------------
# button for closing the system
#-----------------------------------------------------------------------

    $SystemClose = $SystemButtons->Button(
        -text    => 'close system',
        -command => [\&CloseSystem],
    );
    $SystemClose->pack(qw(-side left -expand 1));
}





sub CreateSubModuleFrames{
    my ($ParentFrame,$config)=@_;

    if (ref($config->{module}->{submodules}) eq 'ARRAY'){

	#---------------------------------------------------------------
        # if there's a loop definition: save start and end module
        #---------------------------------------------------------------

	my ($LoopStart,$LoopEnd);
	my %IsInLoop=();
	my $SystemFrame=$ParentFrame;
	if (defined $config->{module}->{loop}){
	    ($LoopStart,$LoopEnd)=split(/:/,$config->{module}->{loop});
	}
	my $mod_nr=0;

	foreach my $module (@{$config->{module}->{submodules}}){

	    &LoadModuleConfig($module,\%ModuleConfig,\%UplugIni);
	    my $IniFile=$module;
	    my $modName=$module;
	    if (defined $ModuleConfig{$module}{module}{name}){
		$modName=$ModuleConfig{$module}{module}{name};
	    }

#-----------------------------------------------------------------------
# create loop frames and iteration scales
#-----------------------------------------------------------------------

	    if (defined $LoopStart){
		if ($mod_nr == $LoopStart){
		    $ParentFrame=$SystemFrame;
		    $SystemFrame=&CreateLoopFrame($SystemFrame,\%ModuleConfig);
		}
	    }
#-----------------------------------------------------------------------
# cerate module frame with a label
#-----------------------------------------------------------------------

	    &CreateModuleFrame($SystemFrame,$module,$mod_nr,$OpenedSystem);
	    if (defined $LoopEnd){
		if ($mod_nr == $LoopEnd){
		    $SystemFrame=$ParentFrame;
		}
	    }
	    $mod_nr++;
	}
    }
}


sub CreateModuleFrame{
    my ($ParentFrame,$module,$mod_nr,$system)=@_;

    &LoadModuleConfig($module,\%ModuleConfig,\%UplugIni);
    my $IniFile=$module;
    my $modName=$module;
    if (defined $ModuleConfig{$module}{module}{name}){
	$modName=$ModuleConfig{$module}{module}{name};
    }
    my $showinput=$GuiIni{'submodule frame'}{'show input'};
    my $showoutput=$GuiIni{'submodule frame'}{'show output'};

    my $ModFrame=$ParentFrame->Frame(
				     -relief => 'sunken',
				     -bd => 2);
    $ModFrame->pack(-side => 'top',-fill => 'x');

    my $ModLabel=$ModFrame->Button(
                       -text    => $modName,
  		       -width => 30,
                       -borderwidth    => 0,
                       -relief   => 'groove',
                       -command => [\&OpenSystem,$module],
                   );
    $ModLabel->pack(qw(-side left -fill x));

#	    $ModLabel=
#		$ModFrame->Label(-text => $modName,
#						       -width => 30);
#	    $ModLabel->pack(-side => 'left');

#-----------------------------------------------------------------------
# create checkboxes for skipping the current module
#-----------------------------------------------------------------------

    my $ModSkipButton = $ModFrame->Checkbutton(
                          -text     => 'skip',
	                  -variable => \$SkipModule{$module},
	                  -relief   => 'flat');
    $ModSkipButton->pack(-side => 'left');

#-----------------------------------------------------------------------
# create 'generate' buttons to run the system and stop at this module
#-----------------------------------------------------------------------

    my $ModStartButton=$ModFrame->Button(
                -text    => 'generate',
#                -state   => 'disabled',
                -command => [\&StartPlugSystem,
			     $system,
			     \%ModuleConfig,
			     \%SkipModule,
			     $mod_nr],
             );
    $ModStartButton->pack(qw(-side left));

#-----------------------------------------------------------------------
# create buttons to set module parameters 
# (only if the location of the inifile is defined in Plug.ini
#  and the file really exists)
#-----------------------------------------------------------------------

    my $ModConfigButton=$ModFrame->Button(
                       -text    => 'settings',
#                       -state   => 'disabled',
                       -command => [\&ChangeSettings,
				    \$MW,$ModuleConfig{$module},$module,
				    \%UplugIni],
                   );
    if (not &ParameterExist($ModuleConfig{$module})){
	$ModConfigButton->configure(qw(-relief flat -state disabled));
    }
    $ModConfigButton->pack(qw(-side left));

#-----------------------------------------------------------------------
# create buttons for viewing input stream data
#-----------------------------------------------------------------------

    my $ModInFrame=$ModFrame->Frame;
    $ModInFrame->pack(-side => 'left');
    if ($showinput){
	if (ref($ModuleConfig{$module}{input}) eq 'HASH'){
	    &ViewStreamButtons($ModInFrame,
			       $ModuleConfig{$module}{input},
			       'top',
			       \&ShowStream,\$MW);
	}
    }

#-----------------------------------------------------------------------
# create buttons for viewing output stream data
#-----------------------------------------------------------------------

    my $ModOutFrame=$ModFrame->Frame;
    $ModOutFrame->pack(-side => 'left');
    if ($showoutput){
	if (ref($ModuleConfig{$module}{output}) eq 'HASH'){
	    &ViewStreamButtons($ModOutFrame,
			       $ModuleConfig{$module}{output},
			       'top',
			       \&ShowStream,\$MW);
	}
    }
}

sub CreateLoopFrame{
    my ($ParentFrame,$ModConfig)=@_;

    $LoopFrame = $ParentFrame->Frame;
    $LoopFrame->pack(qw(-side top -fill x -pady 2m));

#-----------------------------------------------------------------------
    my $LoopSystemFrame=$LoopFrame->Frame;
    $LoopSystemFrame->pack(qw(-side left));
#-----------------------------------------------------------------------

    my $IterationScaleFrame=$LoopFrame->Frame;
    $IterationScaleFrame->pack(qw(-side right));
    $LoopIterationScale=$IterationScaleFrame->Scale(
                   -orient => 'vertical',
                   -from => 0,
                   -to => 20,
                   -resolution => 1,
                   -bigincrement => 1,
#                   -label => 'nr',
	           -variable => \$ModuleConfig{$OpenedSystem}
					      {module}
					      {iterations},
		    );
		    $LoopIterationScale->pack(qw(-side right));

    return $LoopSystemFrame;
}

#-----------------------------------------------------------------------
# create buttons for viewing input stream data
#-----------------------------------------------------------------------

sub ViewStreamButtons{
    my $frame=shift;
    my $config=shift;
    my $side=shift;
    my @c=@_;

    my $mod=Uplug->new;

    if (ref($config) eq 'HASH'){
	foreach my $s (keys %{$config}){
	    if ($mod->isStdin($config->{$s})){
		next;
	    }
	    my $widget=$frame->Button(
		     -width => 20,
                     -borderwidth    => 0,
                     -relief   => 'groove',
                     -text    => $s,
#                     -command => [$c[0],$c[1],$c[2],$c[3],$s],
                     -command => [@c,$config->{$s}],
	    );
	    $widget->pack(-side => $side);
	}
    }
}


########################################################################

########################################################################

#-----------------------------------------------------------------------
#
# close the current system
#
#-----------------------------------------------------------------------


sub CloseSystem{
    if (not $OpenedSystem){return 0;}
    &SaveModuleConfig($OpenedSystem,\%ModuleConfig,\%UplugIni,\%SkipModule);

    $SystemStart->destroy;                     # destroy the system frame
    $SystemFrame->destroy;
    $OpenedSystem=undef;

    $SystemFrame = $MW->Frame;
    $SystemFrame->pack;

    if (defined $GuiIni{'logotypes'}{'general'}{'logo'}){
	my $pic=$GuiIni{'logotypes'}{'general'}{'logo'};
	if (-s $pic){
	    my $SystemLogoFrame=$SystemFrame->Frame;
	    $SystemLogoFrame->pack(-side => 'left');
	    my $SystemLogo=$SystemLogoFrame->Photo(-file => $pic);
	    $SystemLogoFrame->Label(-image => $SystemLogo)
		->pack(qw(-side left -expand 1));
	}
    }
    if (@ParentSystems){
	my $system=pop(@ParentSystems);
	&OpenSystem($system);
    }
    else{
	foreach $system (@PlugSystem){
#	if (not &IsHidden($IniData{'systems'},$system)){
	    my $SystemButton = $SystemFrame->Button(
		  -width => 25,
                  -text    => $system,
	          -command => [\&OpenSystem,$system]
              );
	    $SystemButton->pack(qw(-side top -expand 1));
#	}
	}
    }
}





#-----------------------------------------------------------------------

#sub GetParameterCategories{
#    my ($IniData)=@_;
#    my %cat;
#    if (defined $$IniData{'parameter'}){
#	foreach (keys %{$$IniData{'parameter'}}){
#	    if (not &IsHidden($$IniData{'parameter'}{$_})){
#		$cat{$_}=1;
#	    }
#	}
#    }
#    if (defined $$IniData{'widgets'}){
#	foreach (keys %{$$IniData{'widgets'}}){
#	    if (not &IsHidden($$IniData{'parameter'}{$_})){
#		$cat{$_}=1;
#	    }
#	}
#    }
#    return sort keys %cat;
#}

sub GetConfigurationSubCategories{
    my ($IniData,$category)=@_;
    my %cat;
    if (defined $$IniData{$category}){
	foreach (keys %{$$IniData{$category}}){
#	    if (not &IsHidden($$IniData{$category}{$_})){
		$cat{$_}=1;
#	    }
	}
    }
    if ($category eq 'parameter'){
	if (defined $$IniData{'widgets'}){
	    foreach (keys %{$$IniData{'widgets'}}){
#		if (not &IsHidden($$IniData{$category}{$_})){
		    $cat{$_}=1;
#		}
	    }
	}
    }
    return sort keys %cat;
}


sub ParameterExist{
    my ($config)=@_;
    if (ref($config->{widgets}) ne 'HASH'){return 0;}
    if (not %{$config->{widgets}}){return 0;}
    return 1;
}


#sub ParameterExist{
#    my $inifile=shift;
#    my %IniData=();
#    &LoadIniData(\%IniData,$inifile);
#    my @par=&GetConfigurationSubCategories(\%IniData,'input');
#    push (@par,&GetConfigurationSubCategories(\%IniData,'output'));
#    push (@par,&GetConfigurationSubCategories(\%IniData,'parameter'));
#    return @par;
#}


sub ChangeSettings{
    my $MW=shift;
    my ($config,$module,$ini)=@_;;
    if (ref($config) ne 'HASH'){
	&message(\$MW,'No configuration found!');
    }
   my $ok='ok';
    my $cancel='cancel';

    my $w=$$MW->Dialog(
	    -title          => "set module parameter",
            -wraplength     => '4i',
	    -justify    => 'center',
            -default_button => $ok,
            -buttons        => [$ok,$cancel],
        );

    my $ParamFrame=$w->Frame;
    $ParamFrame->pack(-side => 'top');
    my $title=$ParamFrame->Label(-text => $module.': configuration');
    $title->pack(-side => 'top');
    my %SubFrames=();
    my %ParamLabels=();

    if (ref($config->{widgets}) eq 'HASH'){
	foreach my $c (keys %{$config->{widgets}}){
	    $SubFrames{$c}=$ParamFrame->Frame(-relief => 'raised',
					      -borderwidth => 2);
	    $ParamLabels{$c}=$SubFrames{$c}->Label(-text => $c);
	    $ParamLabels{$c}->pack(-side => 'top');
	    &ParameterWidgets($SubFrames{$c},
			      $config->{widgets}->{$c},$config->{$c},'top');
	    $SubFrames{$c}->pack(-side => 'top',-fill => 'x');
	}
    }

    my $button = $w->Show;
    if ($button eq 'ok'){  
	&SaveModuleConfig($module,$config,$ini,\%SkipModule);
	my $system=$OpenedSystem;
	$OpenedSystem=pop @ParentSystems;
	&OpenSystem($system);
    }
}

sub ParameterWidgets{
    my ($frame,$config,$data,$side)=@_;
    if ($side='top'){$side='left';}
    if ($side='left'){$side='top';}
    if (ref($config) eq 'HASH'){
	if (ref($data) ne 'HASH'){return;}
	foreach my $c (keys %{$config}){
	    if (not defined $config->{$c}){next;}
#	    my $subframe=$frame->Frame(-relief => 'raised',-borderwidth => 2);
	    my $subframe=$frame->Frame;
	    my $label=$subframe->Label(-text => "$c: ");
	    $label->pack(-side => 'left', -fill => 'x');
#	    if (ref($config->{$c}) eq 'HASH'){
	    if (ref($config->{$c})){
		&ParameterWidgets($subframe,$config->{$c},$data->{$c});
	    }
	    else{
		&AddParamWidget($subframe,$config->{$c},\$data->{$c});
	    }
	    $subframe->pack(-side => 'top',-fill => 'x');
	}
    }
    if (ref($config) eq 'ARRAY'){
	if (ref($data) ne 'ARRAY'){return;}
	foreach my $c (0..$#{$config}){
	    if (not defined $config->[$c]){next;}
#	    my $subframe=$frame->Frame(-relief => 'raised',-borderwidth => 2);
	    my $subframe=$frame->Frame;
	    my $label=$subframe->Label(-text => "$c: ");
	    $label->pack(-side => 'left', -fill => 'x');
	    if (ref($config->[$c])){
		&ParameterWidgets($subframe,$config->[$c],$data->[$c]);
	    }
	    else{
		&AddParamWidget($subframe,$config->[$c],\$data->[$c]);
	    }
	    $subframe->pack(-side => 'top',-fill => 'x');
	}
    }
}

sub AddParamWidget{
    my ($frame,$widget,$var)=@_;
    if ($widget=~/^optionmenu\s\((.*)\)\s*$/){
	my @options=split(/\,/,$1);
	my $menu = $frame->Optionmenu(
			    -textvariable => $var,
			    -relief =>'raised',
 			    -options => [@options],
				      );
	$menu->pack(qw(-side top -fill x));
    }
    elsif($widget=~/^scale\s\((.*)\)\s*$/){
	my @val=split(/\,/,$1);
	my ($from,$till,$resolution,$biginc)=@val;
	$from=shift(@val);
	if (@val){$till=shift @val;}
	else{
	    $till=$from;
	    $from=0;
	}
	if (@val){$resolution=shift @val;}
	else{$resolution=1;}
	if (@val){$biginc=shift @val;}
	else{$biginc=1;}
	my $scale=$frame->Scale(
                      -orient => 'horizontal',
                      -length => '200',
                      -from => $from,
                      -to => $till,
                      -resolution => $resolution,
                      -bigincrement => $biginc,
#                      -label => $_,
	              -variable => $var,
		    );
	$scale->pack(qw(-side top -fill x));
    }
    elsif ($widget=~/checkbox/){
	my $check=$frame->Checkbutton(
#                          -text     => $_,
	                  -variable => $var,
	                  -relief   => 'flat');
	$check->pack(-side => 'top');
    }
    if ($widget=~/entry/){
	my $entry=$frame->Entry(
                       -relief => 'sunken',
		       -textvariable => $var);
	$entry->pack(-side => 'top', -fill => 'x');
    }
}


sub CreateCategoryFrame{                         # create frame for a parameter
    my ($Frame,$IniData,$cat,$ParentFrame)=@_;                # category

    my %para;
    foreach (keys %{$$IniData{'parameter'}{$cat}}){
	$para{$_}=1;
    }
    foreach (keys %{$$IniData{'widgets'}{$cat}}){
	$para{$_}=1;
    }
    my @cat=sort keys %para;
#    my @cat=grep((not &IsHidden($$IniData{'parameter'},$_,$cat)),@cat);
    &CreateEditHashFrame($Frame,
			 $$IniData{'parameter'}{$cat},
			 $cat,
			 $__ALLOWTOADDPARAMETER,
			 $__ALLOWTODELETEPARAMETER,
			 $$IniData{'widgets'});
}


sub ViewStream{                                 # select a stream and
    my $WH=shift;                               # view its data

    my $ok='ok';
    my $cancel='cancel';

    my $w=$$WH->Dialog(
	    -title          => "show stream data",
            -wraplength     => '4i',
#	    -justify    => 'bottom',
            -default_button => $ok,
            -buttons        => [$ok,$cancel],
        );

    $w->title('show stream data');

    my %stream;
    my $StreamViewLabel=$w->Label(-text => 'select one data stream');
    $StreamViewLabel->pack(-side => 'top');

    my $StreamFrame=$w->Frame(-bd => '2',-relief => 'raised');
    $StreamFrame->pack(-side => 'top');

    &StreamSpecificationForm(\$StreamFrame,\%stream);

    my $button=$w->Show;

    if ($button eq 'ok'){
	&ShowStreamData(\$MW,\%stream,1);
	return 1;
    }
    return 0;
}

sub OpenNewStream{                                 # select a stream and
    my $WH=shift;                               # open it
    my ($stream)=@_;

    my %newstream;

    if (&SpecifyStreamDialog($WH,\%newstream,'show stream data')){
	if (not &OpenStream(\%newstream,'read')){
	    &message($WH,'Could not open specified stream!');
	    return &OpenNewStream($WH,$stream);
	}
	&CloseStream(\%newstream);
	%{$stream}=%newstream;
	return 1;
    }
    return 0;
}


sub SpecifyStreamDialog{
    my $WH=shift;
    my ($stream,$title)=@_;

    my $ok='ok';
    my $cancel='cancel';

    my $w=$$WH->Dialog(
	    -title          => $title,
            -wraplength     => '4i',
#	    -justify    => 'bottom',
            -default_button => $ok,
            -buttons        => [$ok,$cancel],
        );


    my %newstream=%{$stream};
    my $StreamViewLabel=$w->Label(-text => 'select one data stream');
    $StreamViewLabel->pack(-side => 'top');

    my $StreamFrame=$w->Frame(-bd => '2',-relief => 'raised');
    $StreamFrame->pack(-side => 'top');

    &StreamSpecificationForm(\$StreamFrame,\%newstream);

    my $button=$w->Show;

    if ($button eq 'ok'){
	&CloseStream($stream);
	%{$stream}=();
	for (keys %newstream){
	    &CheckIniValues(\$newstream{$_});
	}
	%{$stream}=%newstream;
	return 1;
    }
    return 0;
}

###############################################################


sub GetFileAndEdit{
    my ($MW)=@_;
    my $filename;
    if ($filename=
	&SelectFile($MW,1,
		    \$UplugIni{'directories'}{'data'}{'plug'},
		    '*.*')){
	&ShowFile($MW,$filename,\%Tools);
    }
#	&ViewFile(\$MW,$IniData{'directories'}{'data'}{'plug'},\%Tools);
}



sub see_code{                                  # the old subfunction for
    my ($filename)=@_;                         # viewing ASCII files
    &ShowFile(\$MW,$filename,\%Tools);         # --> call the new one here
}

sub ChooseFile{                                # the old file dialog
    my ($create,$path,$filter)=@_;
    return &SelectFile(\$MW,$create,$path,$filter);
}

sub GetMWhandle{
    return \$MW;
}


sub GetPlugIniData{
    my ($cat,$subcat)=@_;
    if (defined $cat){
	if (defined $subcat){
	    return $UplugIni{$cat}{$subcat};
	}
	return $UplugIni{$cat};
    }
    return \%UplugIni;
}

sub GetIniFileName{
    my ($system,$module)=@_;
    my $IniFile="$UplugIni{'systems'}{$system}{'configdir'}\/".
	$UplugIni{'modules'}{$module}{'configuration'};
    return $IniFile;
}


sub AboutDialog {

    my $WH=shift;                                # window handle
    my $ok = 'OK';

    my $DialogText=$UPlugVersion."\n";
    $DialogText.='Jörg Tiedemann'."\n";
    $DialogText.=$UPlugDate."\n";


    my $DIALOG = $$WH->Toplevel;
    $DIALOG->title('about');
    $DIALOG->resizable(0,0);
    if (defined $GuiIni{'logotypes'}{'uplug'}{'logo'}){
	my $UplugLogo=$GuiIni{'logotypes'}{'uplug'}{'logo'};
	my $DialogPic=$DIALOG->Photo(-file => $UplugLogo);
	$DIALOG->Label(-image => $DialogPic)->pack(qw(-side top));
    }
    $DIALOG->Label(-text => $UPlugVersion)->pack(qw(-side top));
    $DIALOG->Label(-text => 'Jörg Tiedemann')->pack(qw(-side top));
    $DIALOG->Label(-text => $UPlugDate)->pack(qw(-side top));
    
    $DIALOG->Button(-text => 'ok',
		    -command => sub{$DIALOG->destroy;}
		    )->pack(qw(-side top));
}



















sub LoadLibFiles{

#perl2exe_include SDBM_File
#perl2exe_include GDBM_File
#perl2exe_include NDBM_File
#perl2exe_include DB_File
#perl2exe_include AnyDBM_File
#perl2exe_include Tk/Menubutton
#perl2exe_include Tk/Photo
#perl2exe_include Tk/Text
#perl2exe_include Tk/Button
#perl2exe_include Tk/Scale
#perl2exe_include Tk/Checkbutton
#perl2exe_include Tk/Clipboard
#perl2exe_include Tk/ErrorDialog
#perl2exe_include Tk/FileDialog
#perl2exe_include Tk/FileSelect
#perl2exe_include Tk/Message
#perl2exe_include Tk/Optionmenu


    use lib '../lib';
    use lib "$ENV{'PLUGHOME'}/lib";
    use lib "$ENV{'PLUGLIBDIR'}/";

#perl2exe_include UplError.pl
#perl2exe_include UplugLib.pl
#perl2exe_include UplugIO.pl
#perl2exe_include UplLib.pl

#-----------------------------------------

    require('UplError.pl');
    require('UplugLib.pl');
    require('UplLib.pl');
    require('UplugIO.pl');

    use lib '../Modules';
    use lib "$ENV{'PLUGHOME'}/Modules";
    use lib "$ENV{'PLUGMODULEDIR'}/";

}

sub GetDefaultIni{

    my $DefaultIni = eval 
"{
}";
    return %{$DefaultIni};
}

sub LoadModuleConfig{
    my ($module,$ModuleConfig,$UplugIni)=@_;
    if (not defined $ModuleConfig{$module}){
	my $ConfigFile=$module;
	if (defined $UplugIni{modules}{$module}){
	    $ConfigFile=$UplugIni{modules}{$module};
	}
	$ModuleConfig{$module}={};
	&LoadConfiguration($ModuleConfig{$module},$ConfigFile);
    }
}

sub SaveModuleConfig{
    my ($module,$ModuleConfig,$UplugIni,$SkipModule)=@_;
    my $ConfigFile=$module;
    if (defined $UplugIni{modules}{$module}){
	$ConfigFile=$UplugIni{modules}{$module};
    }
    print STDERR "save $ConfigFile\n";
    &SaveSkipModules($module,$ModuleConfig,$SkipModule);
    &SaveConfiguration($ModuleConfig{$module},$ConfigFile);
}



sub ShowStream{
    my ($MW,$config)=@_;
    &ShowStreamData($MW,$config,1);
}







#----------------------------------------------------------------------
#
# show stream data in Tk windows
#
#----------------------------------------------------------------------

sub ShowStreamData{

    print STDERR `pwd`;
    my $MW=shift;                          # main window handle
    my $config=shift;                      # stream specifications
    my ($showData)=@_;                     # 1 -> read data from stream

    my $StreamDataFrame;
    my %StreamDataList;
    my %ColumnHeader;
    my $StreamDataScrollX;
    my $StreamDataScrollY;
    my %SearchEntry;
    my %SearchData;
    my $RelDataMsg;
    my $nextButton;

    %StreamDataList=();

    my $stream=Uplug::IO::Any->new($config);
    print join "\n",%{$stream};

    if (not $stream->open('read',$config)){
	my $name=$stream->name;
	&message($MW,"Couldn't open data stream $name!");
	return 0;
    }

    $stream->open('read',$config);
    my @keys=$stream->attributeNames;
    my @hidden=$stream->hiddenAttributes;
    my $title=$stream->name;

    my $w = $$MW->Toplevel(-title => $title);
    $w->geometry('+200+200');

    my $FunctionResult=$w->Message(-width => 400);
    $FunctionResult->pack(-side => 'top',-expand => 1);

    my %width;
    my $total;
    my $key;

    my $HeaderFrame=$w->Frame;
    $HeaderFrame->pack(-side => 'top');
    foreach $key (sort @keys){
	if (grep ($key eq $_,@hidden)){next;}
	$ColumnHeader{$key} = $HeaderFrame->Label(
		        -justify    => 'center',
		        -text       => $key,
                        -width      => length($key),
		      );
	$ColumnHeader{$key}->pack(-side => 'left');
    }

    my $buttons = $w->Frame;
    $buttons->pack(qw(-side bottom -fill x -pady 2m));

    my $relbuttons=$w->Frame;
    $relbuttons->pack(qw(-side bottom -fill x -pady 2m));

    my $RelationDataFrame = $w->Frame;
    $RelationDataFrame->pack;

    $StreamDataFrame = $w->Frame(-bd => 2,-relief => 'sunken');
    $StreamDataFrame->pack;

    $StreamDataScrollX=$StreamDataFrame->Scrollbar(-orient => 'horizontal');
    $StreamDataScrollY=$StreamDataFrame->Scrollbar;

#----------------------------------------------------------------------
# create data lists for each data-field
#----------------------------------------------------------------------

    foreach $key (sort @keys){
	if (grep ($key eq $_,@hidden)){next;}
	if ($width{$key}<1){$width{$key}=1};
	$StreamDataList{$key} = $StreamDataFrame->Listbox(
	-yscrollcommand => [$StreamDataScrollY => 'set'],
        -xscrollcommand => [$StreamDataScrollX => 'set'],
        -setgrid        => 1,
        -width          => length($key),
        -height         => 20,
					 );

	$StreamDataList{$key}->bind('<Button-1>' => 
	    [sub  {
		$SearchEntry{$key}->delete(0,'end');
		my $newstr=$_[0]->get($_[0]->curselection);
		$newstr=quotemeta $newstr;
		$SearchEntry{$key}->insert(0,$newstr);
	    },],
        );
    }

#----------------------------------------------------------------------
# create frame for searching the stream
#----------------------------------------------------------------------

    my $SearchFrame=$w->Frame;
    $SearchFrame->pack(-side => 'top');

    foreach $key (sort @keys){
	if (grep ($key eq $_,@hidden)){next;}
	$SearchEntry{$key}=$SearchFrame->Entry(
				 -relief => 'sunken', 
				 -textvariable => \$SearchData{$key},
                                 -width          => length($key),
					       );
	$SearchEntry{$key}->pack(-side => 'left');
    }

#----------------------------------------------------------------------
# create search & read button
#----------------------------------------------------------------------

    my $searchButton = $buttons->Button(
        -text    => 'search',
        -state   => 'disabled',
        -command   => sub{
	    my @requ_fields=keys %SearchData;
	    my %sth;
	    my %SelData=%SearchData;
	    &SelectStreamData($stream,\%sth,\@requ_fields,\%SelData);
	    &ShowStreamData($MW,\%sth,1);
	},
    );
    $searchButton->pack(qw(-side left));
    my $readButton = $buttons->Button(
        -text    => 'read',
        -command   => sub{
	    $stream->close;
	    $stream->open('read');
	    &ReadStreamData($stream,\$nextButton);
	},
    );
    $readButton->pack(qw(-side left));


#----------------------------------------------------------------------
# edit stream hash
#----------------------------------------------------------------------

    if ($__EDITSTREAMCONFIG){
	my $EditStreamButton = $buttons->Button(
          -text    => 'edit stream config',
          -command   => sub{
	    if (&EditIniData(\$w,$stream,'stream specifications')){
		$stream->close;
		$stream->open('read');
	    }
	},
        );
	$EditStreamButton->pack(qw(-side left -expand 1));
    }

#----------------------------------------------------------------------
# big font ...
#----------------------------------------------------------------------

    if ($CHANGEFONTALLOWED){
	my $BoldFont='-*-Helvetica-Bold-R-Normal--*-180-*-*-*-*-*-*/';
	my $CurrentFont='big font';
	my $ChangeFontButton = $buttons->Checkbutton(
        -offvalue    => 'big font',
        -onvalue    => 'small font',
        -indicatoron    => 0,
        -variable    => \$CurrentFont,
        -textvariable    => \$CurrentFont,
        -command   => [sub{
	    my $ListItems=shift;
	    foreach (keys %{$ListItems}){
		if ($CurrentFont eq 'big font'){
		    $$ListItems{$_}->configure('-font','default');
		}
		else{
		    $$ListItems{$_}->configure('-font',$BoldFont);
		}
	    }
	},\%StreamDataList]
        );
	$ChangeFontButton->pack(qw(-side left -expand 1));
    }

#----------------------------------------------------------------------
# save data in new data stream
#----------------------------------------------------------------------

    my $SaveStreamAsButton = $buttons->Button(
        -text    => 'save as',
        -state => 'disabled',
        -command   => sub{
	    if (&SaveStreamAs(\$w,$stream)){
		$stream->close;
		if (not $stream->open('read')){
		    &message(\$w,&ErrMsg);
		    return 0;
		}
	    }
	},
    );
    $SaveStreamAsButton->pack(qw(-side left -expand 1));

#----------------------------------------------------------------------
# close the Tk window
#----------------------------------------------------------------------

    my $closeButton = $buttons->Button(
        -text    => 'close',
        -command   => sub{
	    $stream->close;
	    $w->destroy;
	},
    );
    $closeButton->pack(qw(-side left -expand 1));

#----------------------------------------------------------------------


    my $clearButton = $SearchFrame->Button(
        -text    => 'clear',
        -command   => sub{
	    foreach (keys %SearchData){
		if (defined $SearchData{$_}){
		    $SearchData{$_}=undef;
		}
	    }
	},
    );
    $clearButton->pack(qw(-side left));

#----------------------------------------------------------------------
# create scroll bars for data lists
#----------------------------------------------------------------------

    $StreamDataScrollY->configure(-command => sub{
	foreach $key (keys %StreamDataList){
	    $StreamDataList{$key}->yview(@_);
	}
    }
			   );
    $StreamDataScrollX->configure(-command => sub{
	foreach $key (keys %StreamDataList){
	    $StreamDataList{$key}->xview(@_);
	}
    }
			   );
    $StreamDataScrollY->pack(-side => 'right', -fill => 'y');
    $StreamDataScrollX->pack(-side => 'bottom', -fill => 'x');

    foreach $key (sort @keys){
	if (defined $StreamDataList{$key}){
	    $StreamDataList{$key}->pack(-side => 'left', 
					-expand => 'yes', 
					-fill => 'both');
	}
    }

#----------------------------------------------------------------------
# set frame handles in stream hash
#----------------------------------------------------------------------

    my %datalength;
    my $count;

    %{$$stream{'Tk window'}{'column header'}}=%ColumnHeader;
    %{$$stream{'Tk window'}{'data lists'}}=%StreamDataList;
    %{$$stream{'Tk window'}{'search entries'}}=%SearchEntry;
    $$stream{'Tk window'}{'buttons'}=$buttons;

#----------------------------------------------------------------------
# read data from stream and show them in the form
#----------------------------------------------------------------------

    if ($showData){
	&ReadStreamData($stream,\$nextButton);
    }
    else{
	&SetColumnWidth($$stream{'Tk window'}{'column header'},
			$$stream{'Tk window'}{'data lists'},
			$$stream{'Tk window'}{'search entries'},
			$$stream{'Tk window'}{'datalength'});
    }

#    $w->bind('<Return>', [$closeButton, 'invoke']);
}


#----------------------------------------------------------------------
# read stream data and add them to the Tk window
#----------------------------------------------------------------------

sub ReadStreamData{

    my ($stream,$nextButton)=@_;
    my $data=Uplug::Data->new;
    my $count;

    my $Lists=$$stream{'Tk window'}{'data lists'};
    foreach (keys %{$Lists}){
	$$Lists{$_}->delete(0,'end');
    }
    my @hidden=$stream->hiddenAttributes;

    while ($stream->read($data)){
	my %DataHash=$data->rootAttributes;
	foreach my $key (keys %DataHash){
	    if (grep ($key eq $_,@hidden)){next;}
	    if (length($DataHash{$key})>$$stream{'Tk window'}{'datalength'}{$key}){
		$$stream{'Tk window'}{'datalength'}{$key}=length($DataHash{$key});
	    }
	}

	&ShowData(\%DataHash,$$stream{'Tk window'}{'data lists'});
	$count++;
	if ($count>$SHOWMAXDATA){
	    if (not defined $$nextButton){
		$$nextButton = $$stream{'Tk window'}{'buttons'}->Button(
			    -text    => 'next',
                            -command   => [\&ReadNextStreamData,
					   $stream,$nextButton],

		              );
		$$nextButton->pack(qw(-side left -expand 1));
	    }
	    $$nextButton->configure(-state => 'normal');
	    last;
	}
    }
    &SetColumnWidth($$stream{'Tk window'}{'column header'},
		    $$stream{'Tk window'}{'data lists'},
		    $$stream{'Tk window'}{'search entries'},
		    $$stream{'Tk window'}{'datalength'});
}

#----------------------------------------------------------------------
# read stream data if 'next' button is pressed
#----------------------------------------------------------------------

sub ReadNextStreamData{
    my ($stream,$nextButton)=@_;

    my $Lists=$$stream{'Tk window'}{'data lists'};
    my $len=$$stream{'Tk window'}{'datalength'};
    my $Head=$$stream{'Tk window'}{'column header'};
    my $Search=$$stream{'Tk window'}{'search entries'};
    foreach (keys %{$Lists}){
	$$Lists{$_}->delete(0,'end');
    }
    my @hidden=$stream->hiddenAttributes;
    my $data=Uplug::Data->new;
    my $c;

    while ($stream->read($data)){
	my %DataHash=$data->rootAttributes;
	my $key;
	foreach $key (keys %DataHash){
	    if (grep ($key eq $_,@hidden)){
		next;
	    }
	    if (length($DataHash{$key})>$$len{$key}){
		$$len{$key}=length($DataHash{$key});
	    }
	}
	&ShowData(\%DataHash,$Lists);
	$c++;
	if ($c>$SHOWMAXDATA){last;}
    }
    &SetColumnWidth($Head,
		    $Lists,
		    $Search,
		    $len);
    if ($c<$SHOWMAXDATA){
	$$nextButton->configure(-state => 'disabled');
    }
}

#----------------------------------------------------------------------
# add a data record to data lists
#----------------------------------------------------------------------    

sub ShowData{                       # fill 'show-data-window' with data

    my $data=shift;
    my $StreamDataList=shift;
    my $key;
    foreach $key (sort keys %{$data}){
	if (exists $$StreamDataList{$key}){
	    my $str=$$data{$key};
	    if ($str=~/ARRAY/){
		$str=join(' ',@{$$data{$key}});
	    }
	    $$StreamDataList{$key}->insert('end',$str);
	}
    }
}

#----------------------------------------------------------------------
# save stream data in a new file
#----------------------------------------------------------------------

sub SaveStreamAs{                   # save data in new stream

    my $WH=shift;
    my $instream=shift;

    my $ok='ok';
    my $cancel='cancel';

    my $w=$$WH->Dialog(
	    -title          => "show stream data",
            -wraplength     => '4i',
	    -justify    => 'center',
            -default_button => $ok,
            -buttons        => [$ok,$cancel],
        );

    $w->title('show stream data');

    my %stream;
    my $StreamViewLabel=$w->Label(-text => 'select one data stream');
    $StreamViewLabel->pack(-side => 'top');

    my $StreamFrame=$w->Frame(-bd => '2',-relief => 'raised');
    $StreamFrame->pack;

    &StreamSpecificationForm(\$StreamFrame,\%stream);

    my $button=$w->Show;

    if ($button eq 'ok'){
	&CloseStream($instream);
	if (&OpenStream($instream,'read')){
	    if (&OpenStream(\%stream,'write')){
		my %data;
		while (&ReadFromStream($instream,\%data)){
		    if (not &WriteToStream(\%stream,\%data)){
#			print "problems to write to $stream{'stream name'}!\n";
#			print "data :";
#			print %data,"\n";
#			return 0;
		    }
		}
	    }
	    else{
		print "problems to open output stream $stream{'stream name'}!\n";
		return 0;
	    }
	}
	else{
	    print "problems to open stream $stream{'stream name'}!\n";
	    return 0;
	}
	&CloseStream(\%stream);
	&CloseStream($instream);
	%{$instream}=%stream;
	return 1;
    }
    return 0;
}



#############################################################################
#  show stream data in a nice Tk window
#############################################################################

sub SetColumnWidth{
    my ($Header,$List,$Entry,$MaxLength)=@_;

    my $total;
    my %width;
    my $MinWidth=$GuiIni{'Tk forms'}{'list elements'}{'minimal width'};
    my $MaxWidth=$GuiIni{'Tk forms'}{'window size'}{'maximal width'};

    foreach (values %{$MaxLength}){
	$total+=$_;
    }
    if ($total<$MaxWidth){
	foreach (keys %{$MaxLength}){
	    if (defined $$List{$_}){
		$$Header{$_}->configure(-width => $$MaxLength{$_});
		$$List{$_}->configure(-width => $$MaxLength{$_});
		$$Entry{$_}->configure(-width => $$MaxLength{$_});
	    }
	}
	return;
    }
    my $used;
    my $remain;
    foreach (keys %{$MaxLength}){
	if ($$MaxLength{$_}<$MinWidth){
	    $width{$_}=$$MaxLength{$_};
	    $used+=$width{$_};
	}
	else{
	    $remain+=$$MaxLength{$_};
	}
    }

    my $remain_space=$MaxWidth-$used;
    foreach (keys %{$MaxLength}){
	if (not $width{$_}){
	    if (not $remain_space){$remain_space=$MinWidth;}
	    $width{$_}=int($remain_space/$remain*$$MaxLength{$_});
	    if ($width{$_}<$MinWidth){
		$width{$_}=$MinWidth;
	    }
	    $used+=$width{$_};
	}
    }
    foreach (keys %width){
	if (defined $$List{$_}){
#	    print STDERR "width of $_ = $width{$_}\n";
	    $$Header{$_}->configure(-width => $width{$_});
	    $$List{$_}->configure(-width => $width{$_});
	    $$Entry{$_}->configure(-width => $width{$_});
	}
    }
    return %width;
}



sub CreateEditHashFrame{

    my ($ParentFrame,$IniData,$name,$add,$delete,$widgets)=@_;

    my $Frame=$$ParentFrame->Frame;
    $Frame->pack;
    my %para;
    if ($IniData=~/ARRAY/){
	my @CAT=(0..$#{$IniData});
	&CreateArrayWidgets(\$Frame,\@CAT,$IniData,$ParentFrame,
			    $name,$add,$delete);
    }
    elsif ($IniData=~/HASH/){
	my @CAT=sort keys %{$IniData};
	@CAT=grep((not &IsHidden($IniData,$_,$name)),@CAT);
	if (defined $widgets){
	    $$IniData{'widgets'}=$widgets;
	}
	&CreateAttributeWidgets(\$Frame,\@CAT,$IniData,$ParentFrame,
				$name,$add,$delete);
	if (defined $widgets){
	    delete $$IniData{'widgets'};
	}
    }
}


sub message {

    my $WH=shift;                                # window handle
    my $text=shift;
    my $ok = 'OK';
    my $DIALOG = $$WH->Dialog(
	    -title          => 'Message',
            -wraplength     => '4i',
	    -justify    => 'center',
            -text           => $text,
            -default_button => $ok,
            -buttons        => [$ok],
        );
    my $button = $DIALOG->Show;
    return 1 if $button eq $ok;
}

sub UplugQuit{
    &SaveGUIpareameters;
    $MW->destroy;                          # finally close main window
}

sub SaveGUIpareameters{
    if (defined $OpenedSystem){
	$GuiIni{'sessions'}{'last session'}{'system'}=
	    $OpenedSystem;
    }
    if (defined $GuiIni{'module frame'}{'show input'}){
	    $GuiIni{'sessions'}
	           {'systems'}
	           {'show input stream buttons'}=$GuiIni{'module frame'}{'show input'};
	}
    if (defined $GuiIni{'module frame'}{'show output'}){
	$GuiIni{'sessions'}
	           {'systems'}
	           {'show output stream buttons'}=$GuiIni{'module frame'}{'show output'};
	}
#	&WriteAll2IniFile($__XPLUGINIFILE,\%GuiIni);
#	&RemoveTempFiles;                      # remove tmp files from PlugIO
}

sub SetGuiParameter{
    if (not ref($GuiIni{'module frame'}) eq 'HASH'){
	$GuiIni{'module frame'}={};
    }
    if (not ref($GuiIni{'submodule frame'}) eq 'HASH'){
	%{$GuiIni{'submodule frame'}}=%{$GuiIni{'module frame'}};
    }
    if ($GuiIni{'module frame'}{'show input'}){
	$GuiIni{'module frame'}{'showintext'}='hide module input';
    }
    else{$GuiIni{'module frame'}{'showintext'}='show module input';}
    if ($GuiIni{'module frame'}{'show output'}){
	$GuiIni{'module frame'}{'showouttext'}='hide module output';
    }
    else{$GuiIni{'module frame'}{'showouttext'}='show module output';}
    if ($GuiIni{'submodule frame'}{'show input'}){
	$GuiIni{'submodule frame'}{'showintext'}='hide submodule input';
    }
    else{$GuiIni{'submodule frame'}{'showintext'}='show submodule input';}
    if ($GuiIni{'submodule frame'}{'show output'}){
	$GuiIni{'submodule frame'}{'showouttext'}='hide submodule output';
    }
    else{$GuiIni{'submodule frame'}{'showouttext'}='show submodule output';}
}


sub AddGuiParamMenu{
    my $menu=shift;
    my $frame=shift;

    &ParamCheckMenu($menu,$frame,'show input');
    &ParamCheckMenu($menu,$frame,'show output');
    &ParamCheckMenu($menu,$frame,'show parameter');
    &ParamCheckMenu($menu,$frame,'show submodules');

}


sub ParamCheckMenu{
    my $menu=shift;
    my $frame=shift;
    my $name=shift;

    if (defined $GuiIni{$frame}{$name}){
	if (not defined $GuiIni{$frame}{$name.' (label)'}){
	    $GuiIni{$frame}{$name.' (label)'}=$frame.' - '.$name;
	}
	if ($GuiIni{$frame}{$name}){
	    $GuiIni{$frame}{$name.' (label)'}=~s/show/hide/;
	}
	$menu->command(
    -label     => $GuiIni{$frame}{$name.' (label)'},
    -underline => 0,
    -command   => sub{
	if (not $OpenedSystem){return;}
	if ($GuiIni{$frame}{$name}){
	    my $newtext=$GuiIni{$frame}{$name.' (label)'};
	    $newtext=~s/hide/show/;
	    $GuiIni{$frame}{$name}=0;
	    $menu->entryconfigure($GuiIni{$frame}{$name.' (label)'},
				  -label => $newtext);
	    $GuiIni{$frame}{$name.' (label)'}=$newtext;
	}
	else{
	    $GuiIni{$frame}{$name}=1;
	    my $newtext=$GuiIni{$frame}{$name.' (label)'};
	    $newtext=~s/show/hide/;
	    $menu->entryconfigure($GuiIni{$frame}{$name.' (label)'},
				  -label => $newtext);
	    $GuiIni{$frame}{$name.' (label)'}=$newtext;
	}
	pop @ParentSystems;
	&OpenSystem($OpenedSystem);
    },
		   );
    }
}
