#####################################################################
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# Uplug::Config
#
#
#####################################################################
# $Author$
# $Id$


package Uplug::Config;

use strict;
use vars qw(@ISA @EXPORT %NamedStreams);
use Exporter;
use File::Copy;
use Fcntl qw(:DEFAULT :flock);
use Data::Dumper;
use FindBin qw($Bin);
use lib $Bin;
use lib "$Bin/lib";
use lib "$Bin/..";
use lib "$Bin/../lib";
use Uplug::Encoding;

@ISA = qw( Exporter);

@EXPORT = qw(&ReadIniFile &ReadIniString &LoadIniData &GetIniData
	     &WriteIniFile &WriteAll2IniFile &Write2IniFile
	     &SetIniAttribute &AddIniAttribute &SetAttribute
	     &SetValue &CheckParameter
	     &InitLocalUplugConfig &ReloadDefaults 
	     &InstallLocalFiles &InstallAllLocalFiles 
	     &LoadConfiguration &SaveConfiguration
	     &CheckConfigDir &SplitFileName
	     &ExpandNamedStreams &ExpandHash &ExpandVariables
	     &UplugHome &LocalUplugHome &UplugData &UplugSystem &UplugIni
	     &CopyFile &CopyDir &RmDir &FindDataFile);

my $MAXFLOCKWAIT=3;

if (not defined $ENV{UPLUGRUN}){$ENV{UPLUGRUN}='.';}   # check and set
if ((not defined $ENV{UPLUGHOME}) and                  # UPLUG environment
    (defined $ENV{UPLUG}) and                          # variables!
    (-d "$ENV{UPLUG}/ini") and 
    (-d "$ENV{UPLUG}/systems")){
    $ENV{UPLUGHOME}=$ENV{UPLUG};
}
elsif ((-d "$Bin/ini") and (-d "$Bin/systems")){
    $ENV{UPLUGHOME}=$Bin;
}
elsif ((-d "$Bin/../ini") and (-d "$Bin/../systems")){
    $ENV{UPLUGHOME}=$Bin.'/..';
}



sub ReadIniFile{
    my ($file,$cat,$subcat,$attr)=@_;
    my $IniData={};
    return &LoadIniData($IniData,$file,$cat,$subcat,$attr);
}

sub ReadIniString{
    my ($IniData,$DataString,$cat,$subcat,$attr)=@_;
    $IniData->{data}={};
    $IniData->{data} = eval $DataString;
    %{$IniData}=%{$IniData->{data}};
    return &GetIniData($IniData,$cat,$subcat,$attr);
}

sub MyCopyFile{
    my ($src,$dest)=@_;

    my @path=split(/[\\\/]/,$dest);
    pop(@path);
    my $dir='';
    while (@path){
	$dir.=shift @path;
	if (not -d $dir){
	    if (not mkdir $dir,0750){return 0;}
	}
	$dir.='/';
    }
    print STDERR "create $dest\n";
    copy($src,$dest);
    if (-e $dest){return 1;}
}

sub FindConfigFile{
    my $file=shift;
    my $config=$file;

    if (-f "ini/$file"){
	return "ini/$file";
    }
    elsif (-f "systems/$file"){
	return "systems/$file";
    }
    elsif(-f "$ENV{UPLUGHOME}/$file"){
	$file="$ENV{UPLUGHOME}/$file";
    }
    elsif(-f "$ENV{UPLUGHOME}/ini/$file"){
	$config="ini/$file";
	$file="$ENV{UPLUGHOME}/ini/$file";
    }
    elsif(-f "$ENV{UPLUGHOME}/systems/$file"){
	$config="systems/$file";
	$file="$ENV{UPLUGHOME}/systems/$file";
    }
    if (-f $file){
	if ($config ne $file){
	    if (&MyCopyFile($file,$config)){
		return $config;
	    }
	}
	return $file;
    }
    return 0;
}

sub LoadIniData{

    my ($IniData,$file,$cat,$subcat,$attr)=@_;

    if ($file=~/^\&/){
	my $command=$file;
	$command=~s/^\&//;
	my $DataString=`$command`;
	if ($DataString){
	    return &ReadIniString($IniData,$DataString,$cat,$subcat,$attr);
	}
	return ();
    }
    if (not -f $file){
	my $found;
	if (not ($found=&FindConfigFile($file))){
	    print STDERR "# Uplug::Config.pm: error: cannot load $file\n";
	    return ();
	}
	$file=$found;
    }

    my $DataString='';
    open FH,"<$file";
    my $del=$/;undef $/;
    $DataString=<FH>;
    close FH;
    $/=$del;

    $IniData->{'__newdata'}={};
    if (not $IniData->{'__newdata'} = eval $DataString){
	warn "# Uplug::Config.pm: problems with config file $file!\n# $@\n";
    }
    if (ref($IniData->{'__newdata'}) eq 'HASH'){
	if (defined $IniData->{'__newdata'}->{encoding}){
	    if ($IniData->{'__newdata'}->{encoding} ne 
		$Uplug::Encoding::DEFAULTENCODING){
		$DataString=
		    &Uplug::Encoding::convert($DataString,
					 $IniData->{'__newdata'}->{encoding},
					 $Uplug::Encoding::DEFAULTENCODING);
		$IniData->{'__newdata'} = eval $DataString;
	    }
	}

	foreach (keys %{$IniData->{'__newdata'}}){
	    $IniData->{$_}=$IniData->{'__newdata'}->{$_};
	    delete $IniData->{'__newdata'}->{$_};
	}
    }
    delete $IniData->{'__newdata'};
    &ExpandHash($IniData);
    return &GetIniData($IniData,$cat,$subcat,$attr);
}

sub GetIniData{
    my ($IniData,$cat,$subcat,$attr)=@_;

    if (ref($IniData) eq 'HASH'){
	if (defined $cat){
	    if (ref($$IniData{$cat}) eq 'HASH'){
		if (defined $subcat){
		    if (ref($$IniData{$cat}{$subcat}) eq 'HASH'){
			if (defined $attr){
			    return $$IniData{$cat}{$subcat}{$attr};
			}
			return wantarray ? %{$$IniData{$cat}{$subcat}} :
			    $$IniData{$cat}{$subcat};
		    }
		    return $$IniData{$cat}{$subcat};
		}
		return wantarray ? %{$$IniData{$cat}} : $$IniData{$cat};
	    }
	    return $$IniData{$cat};
	}
	return wantarray ? %{$IniData} : $IniData;
    }
    return $IniData;
}

############################
# WriteIniFile:
#    write inifile
############################

sub WriteIniFile{
    my ($file,$ATTR)=@_;

    sysopen(INI,$file,O_RDWR|O_CREAT) or die "can't open $file: $!\n";
    my $sec=0;
    while (not flock(INI,2)){
	$sec++;sleep(1);
	if ($sec>$MAXFLOCKWAIT){
	    close INI;
	    return 0;
	}
    }
    $Data::Dumper::Indent=1;
    $Data::Dumper::Terse=1;
    $Data::Dumper::Purity=1;
    seek (INI,0,0);
    print INI Dumper($ATTR);
    truncate(INI,tell(INI));
    close INI;
}

sub WriteAll2IniFile{
    return &WriteIniFile(@_);
}

############################
# Write2IniFile($file,$cat,$subcat,$attr,$value):
#    write/update one attribute in inifile
#    $value may be reference to array or hash
############################

sub Write2IniFile{
    my ($file,$cat,$subcat,$attr,$value)=@_;
    my %ATTR;
    &LoadIniData(\%ATTR,$file);
    &SetIniAttribute(\%ATTR,$cat,$subcat,$attr,$value);
    &WriteIniFile($file,\%ATTR);
}

sub SetIniAttribute{
    my ($IniData,$cat,$subcat,$attr,$value)=@_;
    my $data;

    if (not defined $IniData->{$cat}){
	$IniData->{$cat}={};
    }
    if (not defined $IniData->{$cat}->{$subcat}){
	$IniData->{$cat}->{$subcat}={};
    }
    if ($value=~/^\((.*\=\>.*)\)$/){
	$data={};
	my $tmp=$1;
	$tmp=~s/\=\>/,/g;
	%{$data}=split(/,/,$tmp);
#	eval '%{$data}='.$value;
    }
    elsif ($value=~/^\((.*)\)$/){
	$data=[];
	@{$data}=split(/,/,$1);
#	eval '@{$data}='.$value;
    }
    else{$data=$value;}
    &SetAttribute($IniData->{$cat}->{$subcat},$attr,$data);
}


############################
# AddIniAttribute(\%ATTR,$key,$val)
#    adds an attribute-value structure    
#    to an IniHash
############################

sub AddIniAttribute{
    &SetAttribute(@_);
}

sub SetAttribute{
    my ($ATTR,$key,$val)=@_;
    if (defined $ATTR->{$key}){
	if (ref($ATTR->{$key})){
	    if (ref($ATTR->{$key}) ne ref($val)){
		&SetValue($ATTR,$key,$val);
		return;
	    }
	    if (ref($val) eq 'ARRAY'){
		push (@{$ATTR->{$key}},@{$val});
		&SetValue($ATTR,$key,$ATTR->{$key});
		return;
	    }
	    if (ref($val) eq 'HASH'){
		foreach (keys %{$val}){
		    $ATTR->{$key}->{$_}=$val->{$_};
		}
		&SetValue($ATTR,$key,$ATTR->{$key});
		return;
	    }
	}
    }
    &SetValue($ATTR,$key,$val);
}

sub SetValue{
    my ($hash,$key,$val)=@_;
    if (ref($val)){
	$Data::Dumper::Indent=0;
	$Data::Dumper::Terse=1;
	$Data::Dumper::Purity=1;
	my $ValString=Dumper($val);
	$hash->{$key}=eval $ValString;
    }
    else{
	$hash->{$key}=$val;
    }
}



sub CheckParameter{
    my ($Data,$ArgVal,$IniFile)=@_;

    my $PrintIniAndExit=0;

    if (-e $IniFile){
	&LoadIniData($Data,$IniFile);
    }
    my $shorts={};
    if (ref($Data) ne 'HASH'){return 0;}
    if (ref($Data->{arguments}) eq 'HASH'){
	if (ref($Data->{arguments}->{shortcuts}) eq 'HASH'){
	    $shorts=$Data->{arguments}->{shortcuts};
	}
    }

    if (ref($ArgVal) eq 'ARRAY'){
	foreach (0..$#{$ArgVal}){
	    if ($ArgVal->[$_]=~/^\-i$/){
		$IniFile=$ArgVal->[$_+1];
		&LoadIniData($Data,$IniFile);
		if (ref($Data->{arguments}) eq 'HASH'){
		    if (ref($Data->{arguments}->{shortcuts}) eq 'HASH'){
			$shorts=$Data->{arguments}->{shortcuts};
		    }
		}
	    }
	}

	while ($ArgVal->[0]=~/^\-/){
	    my $flag=shift @{$ArgVal};
	    if (($flag=~/^\-h$/) or ($flag=~/^\-help/)){
		&PrintHelpScreen($Data);
		exit;
	    }
	    if ($flag=~/^\-(.*)$/){
		if (defined $$shorts{$1}){
		    $flag=$$shorts{$1};
		}
		my @ini=split(/\:/,$flag);
		my $value;
		if (($ArgVal->[0]=~/^\-/) or (not @{$ArgVal})){
		    $value=1;
		}
		else{$value=shift @{$ArgVal};}

		if (defined $ini[3]){
		    $Data->{$ini[0]}->{$ini[1]}->{$ini[2]}->{$ini[3]}=$value;
		}
		elsif (defined $ini[2]){
		    $Data->{$ini[0]}->{$ini[1]}->{$ini[2]}=$value;
		}
		elsif (defined $ini[1]){
		    $Data->{$ini[0]}->{$ini[1]}=$value;
		}
		else {
		    $Data->{$ini[0]}=$value;
		}
	    }
	}
    }
}


sub PrintHelpScreen{
    my $data=shift;

    my $helpexists=0;
    if (ref($data->{help}) eq 'HASH'){$helpexists=1;}

    if (ref($data->{module}) eq 'HASH'){
	print STDERR "uplug module: $data->{module}->{name}\n\n";
	print STDERR "       usage: $data->{module}->{program} [OPTIONS]";
	if (defined $data->{module}->{stdin}){print STDERR " < input";}
	if (defined $data->{module}->{stdout}){print STDERR " > output";}
    }
    print STDERR "\n\nOPTIONS:\n";
    if (ref($data->{arguments}) eq 'HASH'){
	if (ref($data->{arguments}->{shortcuts}) eq 'HASH'){
	    my @para=sort { $data->{arguments}->{shortcuts}->{$a} cmp 
			    $data->{arguments}->{shortcuts}->{$b} } 
	    keys %{$data->{arguments}->{shortcuts}};
	    foreach my $i (0..$#para){
		my $p=$para[$i];
		printf STDERR "\t%-15s","\-$p arg";
		if ($helpexists and 
		    (ref($data->{help}->{shortcuts}) eq 'HASH') and
		    (defined $data->{help}->{shortcuts}->{$p})){
		    printf STDERR "%-40s\n","$data->{help}->{shortcuts}->{$p}";
		}
		else{
		    printf STDERR "%-40s\n","$data->{arguments}->{shortcuts}->{$p}";
		}
	    }
	}
    }
    printf STDERR "\t%-15s%-40s\n","-i config","configuration file <config>";
    printf STDERR "\t%-15s%-40s\n\n","-h","this help";
}






#---------------------------------------------------------------------
#
# taken from uplugLib.pl ....
#
#---------------------------------------------------------------------
# set Uplug home directories
#                            central: FindBin::Bin/..
#                            local:   $ENV{HOME}/Uplug       OR
#                                     $ENV{UPLUG}


chdir $ENV{UPLUGRUN};                    # Uplug runs always in UplugHome!!!
my @DataFiles=(
#	       '1988sv.txt',
#	       '1988de.txt',
#	       '1988en.txt',
#	       '000307sv.106.sgml',
#	       '000307en.106.sgml',
#	       '000307de.106.sgml',
#	       'svenprf.xml',
	       );

#---------------------------------------------------------------------
# get local settings
# (create local settings if they don't exist)


sub InitLocalUplugConfig{
    if ((not -d $ENV{UPLUGRUN}) or 
	(not -d "$ENV{UPLUGRUN}/ini") or 
	(not -d "$ENV{UPLUGRUN}/systems") or 
	(not -d "$ENV{UPLUGRUN}/data")){
	&InstallLocalFiles($ENV{UPLUGRUN},$ENV{UPLUGHOME});
    }
}

sub LoadConfiguration{
    my ($data,$file)=@_;
    $file=&ExpandVariables($file);
    &LoadIniData($data,$file);
#    &ExpandHash($data);
    &ExpandNamedStreams($data);
}

sub LoadNamedStreams{

    my $IniDir="$ENV{UPLUGRUN}/ini";
    my $NamedStreamFile=$IniDir.'/DataStreams.ini';
    my $LocalNamedStreamFile=$IniDir.'/UserDataStreams.ini';

    if (-f $LocalNamedStreamFile){
	&LoadIniData(\%NamedStreams,$LocalNamedStreamFile);
    }
    if (not &LoadIniData(\%NamedStreams,$NamedStreamFile)){
	if (-f "$ENV{UPLUGHOME}/ini/DataStreams.ini"){
	    $NamedStreamFile="$ENV{UPLUGHOME}/ini/DataStreams.ini";
	    return &LoadIniData(\%NamedStreams,$NamedStreamFile);
	}
	return 0;
    }
    return 1;
}

sub CheckNamedStreams{
    my $stream=shift;
    my $format=shift;

    if (not keys %NamedStreams){
	&LoadNamedStreams;
    }
    if (defined $NamedStreams{$format}){
	%{$stream}=%{$NamedStreams{$format}};
	return $NamedStreams{$format}{format};
    }
    return 0;
}

sub GetNamedStream{    
    my $stream=shift;
    my $name=$stream->{'stream name'};
    if (not keys %NamedStreams){
	&LoadNamedStreams;
    }
    if (defined $NamedStreams{$name}){
	%{$stream}=%{$NamedStreams{$name}};
	return $NamedStreams{$name};
    }
    return undef;
}

sub ExpandNamedStreams{
    my $data=shift;
    if (ref($data) eq 'HASH'){
	if (ref($data->{input}) eq 'HASH'){
	    foreach my $s (keys %{$data->{input}}){
		if (defined $data->{input}->{$s}->{'stream name'}){
		    my $conf=&GetNamedStream($data->{input}->{$s});
		    if (ref($conf) eq 'HASH'){
			%{$data->{input}->{$s}}=%{$conf};
		    }
		}
	    }
	}
	if (ref($data->{output}) eq 'HASH'){
	    foreach my $s (keys %{$data->{output}}){
		if (defined $data->{output}->{$s}->{'stream name'}){
 		    my $conf=&GetNamedStream($data->{output}->{$s});
		    if (ref($conf) eq 'HASH'){
			%{$data->{output}->{$s}}=%{$conf};
		    }
		}
	    }
	}
    }
}

sub SaveConfiguration{
    my ($data,$file)=@_;
    $file=&ExpandVariables($file);
    &WriteIniFile($file,$data);
}


sub ReloadDefaults{
    &InstallLocalFiles($ENV{UPLUGRUN},$ENV{UPLUGHOME});
}

sub InstallAllLocalFiles{
    &InstallLocalFiles($ENV{UPLUGRUN},$ENV{UPLUGHOME});
    &CopyDir("$ENV{UPLUGHOME}/lang","$ENV{UPLUGRUN}/lang",1);
    &CopyDir("$ENV{UPLUGHOME}/ini","$ENV{UPLUGRUN}/ini",1);
    &CopyDir("$ENV{UPLUGHOME}/systems","$ENV{UPLUGRUN}/systems",1);
}


sub UplugHome{
    return $ENV{UPLUGHOME};
}
sub LocalUplugHome{
    return $ENV{UPLUGRUN};
}
sub UplugData{
    return "$ENV{UPLUGRUN}/data";
}
sub UplugSystem{
    return "$ENV{UPLUGRUN}/systems";
}
sub UplugIni{
    return "$ENV{UPLUGRUN}/ini";
}


sub SplitFileName{
    my $name=shift;
    if ($name=~/^(.*)[\/\\]([^\/\\]+)$/){
	return ($1,$2);
    }
    return ('.',$name);
}

sub CheckConfigDir{
    my ($dir,$system,$modules)=@_;

    if (not -d $dir){
	if (not mkdir $dir,0750){
# 	    die "Cannot create the local Uplug directory $dir!\n";
	    warn "Cannot create the local Uplug directory $dir!\n";
	}
    }
    if ($dir!~/\/$/){$dir.='/';}
    for my $s (@{$system}){
	if (ref($modules->{$s}) eq 'HASH'){
	    my $file=$modules->{$s}->{configuration};
	    if (not -f "$dir$file"){
		if (defined $modules->{$s}->{defaults}){
		    my %data=();
		    &LoadIniData(\%data,$modules->{$s}->{defaults});
		    &WriteIniFile("$dir$file",\%data);
		}
	    }
	}
    }
    return $dir;
}


sub ExpandHash{
    my $hash=shift;
    $Data::Dumper::Indent=1;
    $Data::Dumper::Terse=1;
    $Data::Dumper::Purity=1;
    my $DataString=Dumper($hash);
    $DataString=&ExpandVariables($DataString);
    $hash->{data}={};
    $hash->{data}=eval $DataString;
    %{$hash}=%{$hash->{data}};
}

sub ExpandVariables{
    my $string=shift;
    $string=~s/\$UplugBin/$ENV{UPLUGHOME}\/bin/gs;
    $string=~s/\$UplugIni/$ENV{UPLUGRUN}\/ini/gs;
    $string=~s/\$UplugSystem/$ENV{UPLUGRUN}\/systems/gs;
    $string=~s/\$UplugLib/$ENV{UPLUGHOME}\/lib/gs;
    $string=~s/\$UplugLang/$ENV{UPLUGHOME}\/lang/gs;
    return $string;
}

sub InstallLocalFiles{
    my ($local,$central)=@_;

    if (not -d $local){
	if (not mkdir $local,0750){
	    warn "Cannot create the local Uplug directory $local!\n";
#	    die "Cannot create the local Uplug directory $local!\n";
	}
    }
    if (not -d "$local/data"){
	if (not mkdir "$local/data",0750){
	    warn "Cannot create the local Uplug directory $local/data!\n";
# 	    die "Cannot create the local Uplug directory $local/data!\n";
	}
    }
    if (not -d "$local/data/runtime"){
	if (not mkdir "$local/data/runtime",0750){
	    warn "Cannot create the local Uplug directory $local/data/runtime!\n";
# 	    die "Cannot create the local Uplug directory $local/data!\n";
	}
    }
    foreach (@DataFiles){
	if (-f "$central/data/$_"){
	    print STDERR "create $local/data/$_\n";
	    copy ("$central/data/$_","$local/data/$_");
	}
    }
#    &CopyDir("$central/lang","$local/lang",1);        # copy complete lang-dir
#    &CopyDir("$central/ini","$local/ini",1);          # copy ini/
#    &CopyDir("$central/systems","$local/systems",1);  # copy systems/
}

sub CopyFile{
    my ($file,$dir1,$dir2)=@_;
    if (not -d $dir2){
	if (not mkdir $dir2,0750){
	    die "Cannot create the directory $dir2!\n";
	}
    }
    if (-f "$dir1/$file"){
	copy("$dir1/$file","$dir2/$file");
    }
}


sub CopyDir{
    my ($dir1,$dir2,$recursive)=@_;
    if (opendir (DIR,$dir1)){
	my @files=readdir(DIR);
	closedir (DIR);
	if (not -d $dir2){
	    if (not mkdir $dir2,0750){
		die "Cannot create the directory $dir2!\n";
	    }
	}
	foreach (@files){
	    if ($_ eq 'CVS'){next;}
	    if (/^\./){next;}
	    print STDERR "create $dir2/$_\n";
	    if (-f "$dir1/$_"){
		copy("$dir1/$_","$dir2/$_");
	    }
	    elsif ((-d "$dir1/$_") and $recursive){
		&CopyDir("$dir1/$_","$dir2/$_",$recursive);
	    }
	}
    }
}

sub RmDir{
    my ($dir)=@_;
    if (opendir (DIR,$dir)){
	my @files=readdir(DIR);
	closedir (DIR);
	foreach (@files){
	    if ($_ eq 'CVS'){next;}
	    if (/^\./){next;}
	    print STDERR "delete $dir/$_\n";
	    if (-f "$dir/$_"){unlink "$dir/$_";}
	}
	print STDERR "delete $dir\n";
	rmdir $dir;
    }
}

sub FindDataFile{
    my ($file)=@_;
    if (-f $file){return $file;}
    if (-f "$ENV{UPLUGHOME}/$file"){return "$ENV{UPLUGHOME}/$file";}
    if (-f "$ENV{UPLUGRUN}/data/$file"){return "$ENV{UPLUGRUN}/data/$file";}
    if (-f "$ENV{UPLUGHOME}/data/$file"){return "$ENV{UPLUGHOME}/data/$file";}
    if ($file=~/[\\\/]([^\\\/]+)$/){
	if (-f "$ENV{UPLUGHOME}/data/$1"){return "$ENV{UPLUGHOME}/data/$1";}
    }
    return $file;
}

1;
