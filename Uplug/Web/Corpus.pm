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

package Uplug::Web::Corpus;

use strict;
use Exporter;
use IO::File;
use POSIX qw(tmpnam);
use File::Copy;
use ExtUtils::Command;

use Uplug::Web::Process::Stack;
use Uplug::Web::User;
# use lib '/home/staff/joerg/cvs/upl_dev/';
# use lib '/home/staff/joerg/cvs/upl_dev/lib/';
# use lib '/corpora/OPUS/upl/';
# use lib '/corpora/OPUS/upl/lib/';
use Uplug::Config;
# use Uplug::IO::Any;
# use Uplug::Data::DOM;

use vars qw(@ISA @EXPORT);

@ISA=qw( Exporter);
@EXPORT = qw( &GetCorpusData );

my $RECODE='/home/staff/joerg/user_local/bin/recode';
my $ALIGN2CWB='/corpora/OPUS/uplug2-cwb/make-cwb-align';
my $CORPUS2CWB='/corpora/OPUS/uplug2-cwb/make-cwb-corpus';

my $GZIP='/usr/bin/gzip';
my $GUNZIP='/usr/bin/gunzip';

my $Uplug2Dir='/corpora/OPUS/uplug2';
my $CorpusDir=$Uplug2Dir;
my $CorpusIndexFile=$Uplug2Dir.'/corpora';
my $MAXFLOCKWAIT=3;

# my $IniDir=$CorpusDir.'/ini';
# my $CorpusFile=$IniDir.'/uplugUserStreams';

my $CorpusIndex=Uplug::Web::Process::Stack->new($CorpusIndexFile);


sub GetIndexedCorpora{
    my $data=shift;
    if (ref($data) ne 'HASH'){return $CorpusIndex->read();}
    my @corpora=$CorpusIndex->read();
    foreach (@corpora){
	my ($user,$name,$lang,$alg,$enc)=split(/\:/,$_);
	$$data{$user}{$name}{$lang}{encoding}=$enc;
	if ($alg){
	    push (@{$$data{$user}{$name}{$lang}{align}},$alg);
	}
    }
    return keys %{$data};
}


sub AddCorpusToIndex{
    my $user=shift;
    my $corpus=shift;
    my $srcenc=shift;
    my $trgenc=shift;
    my $alg=shift;
    my %info=&GetCorpusInfo($user,$corpus);
    if ($info{format}=~/align/){
	my ($src,$trg)=split(/\-/,$info{language});
	&AddCorpusToIndex($user,
			  &GetCorpusName($info{corpus},$src),
			  $srcenc,$trgenc,
			  $trg);
	&AddCorpusToIndex($user,
			  &GetCorpusName($info{corpus},$trg),
			  $trgenc,$srcenc,
			  $src);
    }
    else{
	$CorpusIndex->remove($user,$info{corpus},$info{language},$alg);
	$CorpusIndex->push($user,$info{corpus},$info{language},$alg,$srcenc);
    }
}




sub GetCorpusDataFile{
    my $user=shift;
    return "$CorpusDir/$user/ini/uplugUserStreams.ini";
}

sub GetCorpusDir{
    my $user=shift;
    my $corpus=shift;
    if (not defined $user){return $CorpusDir;}
    if (not defined $corpus){return "$CorpusDir/$user";}
    if (not -d $corpus){mkdir "$CorpusDir/$user/$corpus";}
    return "$CorpusDir/$user/$corpus";
}

sub GetRecycleDir{
    my $user=shift;
    my $corpus=shift;
    if (not -d "$CorpusDir/.recycled"){
	mkdir "$CorpusDir/.recycled",0755;
    }
    if (not defined $user){return "$CorpusDir/.recycled";}
    if (not -d "$CorpusDir/.recycled/$user"){
	mkdir "$CorpusDir/.recycled/$user",0755;
    }
    if (not defined $corpus){return "$CorpusDir/.recycled/$user";}
    if (not -d "$CorpusDir/.recycled/$user/$corpus"){
	mkdir "$CorpusDir/.recycled/$user/$corpus",0755;
    }
    return "$CorpusDir/.recycled/$user/$corpus";
}

sub GetCorpusStreams{
    my $user=shift;
    my %para=@_;
    my %CorpusData=();
    &GetCorpusData(\%CorpusData,$user);
    my @streams=();
    foreach my $c (keys %CorpusData){
	my $match=1;
	foreach (keys %para){
	    if ($CorpusData{$c}{$_}!~/$para{$_}/){$match=0;last;}
	}
	if ($match){push (@streams,$c);}
    }
    return @streams;
}


sub GetCorpusData{

    my $CorpusData=shift;
    my $user=shift;

    my $CorpusInfoFile=&GetCorpusDataFile($user);
    if (ref($CorpusData) ne 'HASH'){return 0;}
    if (not -e $CorpusInfoFile){return 0;}
    &LoadIniData($CorpusData,$CorpusInfoFile);
    return keys %{$CorpusData};
}

sub RemoveCorpus{
    my ($user,$owner,$name)=@_;

    if ($owner ne $user){print "Cannot remove corpus $name!";return 0;}

    my $CorpusInfoFile=&GetCorpusDataFile($owner);
    my %CorpusData;
    &LoadIniData(\%CorpusData,$CorpusInfoFile);
    if (defined $CorpusData{$name}){
	my $lang=$CorpusData{$name}{language};
	my $file=$CorpusData{$name}{file};
	my $corpus=$CorpusData{$name}{corpus};
	my $RecycleDir=&GetRecycleDir($owner,$corpus);
	if (-e $file){
	    move ($file,"$RecycleDir/");
	}
	delete $CorpusData{$name};
	&WriteIniFile($CorpusInfoFile,\%CorpusData);
    }

}

sub AddTextCorpus{
    my ($user,$name,$lang,$file,$enc)=@_;
    my $file=&SaveCorpusFile($user,$name,$lang,$file,$enc);
    if (not defined $file){return 0;}
    &AddCorpusInfo($user,$name,$lang,'text',
		   {file => $file,format => 'text'});
    return 1;
}

sub GetCorpusName{
    my ($name,$lang)=@_;
    return "$name ($lang)";
}

sub SplitCorpusName{
    my ($name)=@_;
    if ($name=~/^(.*)\s\((.*)\)/){
	return ($1,$2);
    }
    return undef;
}

sub GetCorpusInfo{
    my $user=shift;
    my $CorpusName=shift;

    my $CorpusInfoFile=&GetCorpusDataFile($user);
    my %CorpusData;
    &LoadIniData(\%CorpusData,$CorpusInfoFile);
    if (ref($CorpusData{$CorpusName}) eq 'HASH'){
	return %{$CorpusData{$CorpusName}}
    }
    return undef;
}

#sub ReadCorpus{
#    my $user=shift;
#    my $name=shift;
#    my $start=shift;
#    my $nr=shift;
#
#    my %stream=&Uplug::Web::Corpus::GetCorpusInfo($user,$name);
#    if (not keys %stream){
#	print "Cannot find corpus data for $name\n";
#    }
#    my $corpus=new Uplug::IO::Any(\%stream);
#    if (not $corpus->open('read',\%stream)){
#	print "Cannot open $name\n";
#    }
#    my $html;
#    my @rows;
#    my $data=Uplug::Data::DOM->new();
#    my $count;
#    my $skipped;
#    while ($corpus->read($data)){
#	if ($skipped<$start){$skipped++;next;}
#	$count++;
#	if ($count>$nr){last;}
#	push(@rows,$data->toHtml());
#    }
#    $corpus->close();
#    return @rows;
#}
#


sub SendCorpus{
    my $to=shift;
    my $owner=shift;
    my $corpus=shift;
    my %data=&GetCorpusInfo($owner,$corpus);
    if (defined $data{file}){
	&Uplug::Web::User::SendFile($to,'UplugWeb - '.$corpus,$data{file});
	return 1;
    }
    return 0;
}

sub AddCorpusInfo{

    my $user=shift;
    my $name=shift;
    my $lang=shift;
    my $status=shift;
    my $para=shift;

    my $CorpusInfoFile=&GetCorpusDataFile($user);
    my %CorpusData;
    my $CorpusName=&GetCorpusName($name,$lang);

    &LoadIniData(\%CorpusData,$CorpusInfoFile);
    if (defined $CorpusData{$CorpusName}){
	print "corpus $CorpusName exists already!\n";
	return 0;
    }
    %{$CorpusData{$CorpusName}}=('language' => $lang,
				 'corpus' => $name,
				 'status' => $status);
    if (ref($para) eq 'HASH'){
	foreach (keys %{$para}){
	    $CorpusData{$CorpusName}{$_}=$$para{$_};
	}
    }
    &WriteIniFile($CorpusInfoFile,\%CorpusData);
}


sub ChangeCorpusInfo{

    my $user=shift;
    my $CorpusName=shift;
    my $para=shift;

    my $CorpusInfoFile=&GetCorpusDataFile($user);
    my %CorpusData;
    &LoadIniData(\%CorpusData,$CorpusInfoFile);
    if (not defined $CorpusData{$CorpusName}){
	if ((ref($para) eq 'HASH') and (defined $$para{language})){
	    $CorpusName=&GetCorpusName($CorpusName,$$para{language});
	}
    }
    if (ref($para) eq 'HASH'){
	foreach (keys %{$para}){
	    $CorpusData{$CorpusName}{$_}=$$para{$_};
	}
    }
    &WriteIniFile($CorpusInfoFile,\%CorpusData);
}

sub ChangeCorpusStatus{

    my $user=shift;
    my $CorpusName=shift;
    my $status=shift;

    my $CorpusInfoFile=&GetCorpusDataFile($user);
    my %CorpusData;
    &LoadIniData(\%CorpusData,$CorpusInfoFile);
    if (not defined $CorpusData{$CorpusName}){return undef;}
    my $old=$CorpusData{$CorpusName}{status};
    $CorpusData{$CorpusName}{status}=$status;
    &WriteIniFile($CorpusInfoFile,\%CorpusData);
    return $old;
}


sub SaveCorpusFile{
    my ($user,$name,$lang,$fh,$enc)=@_;
    my $ThisCorpusDir=&GetCorpusDir($user,$name);
    my $txtfile="$ThisCorpusDir/$lang.gz";

    #----------------------------------
    # open a temp file
    # (use PerlIO for encoding in perl > 5.8)
    #
    my $out;
    my $tmpfile=&GetTempFileName;
    if ($]>=5.008){
	binmode($fh);require Encode;
#	binmode($fh,":encoding($enc)");print $!;
	open $out, '>:encoding(utf8)',$tmpfile;
    }
    else{open $out,">$tmpfile";}

    #----------------------------------
    # read data and save them in tempfile
    #
    while (<$fh>){
	if ($]>=5.008){
	    eval {$_=&Encode::decode($enc,$_,1); };
	    if ($@){print $@;return undef;}
	}
	print $out $_;
    }
    close $out;

    #----------------------------------
    # for perl < 5.8:
    #   check encoding with recode and convert to UTF8
    #
    if ($]<5.008){
	if ($enc=~/utf\-?8/i){
	    my $err=`$RECODE $enc..utf16 $tmpfile 2>&1`;
	    if ($err){print "problems with encoding (UTF8)";return undef;}
	    my $err=`$RECODE utf16..$enc $tmpfile 2>&1`;
	    if ($err){print "problems with encoding (UTF8)";return undef;}
	}
	my $err=`$RECODE $enc..utf8 $tmpfile 2>&1`;
	if ($err){print "problems with recode: ",$err;return undef;}
    }

    #----------------------------------
    # gzip file and move to corpus dir
    #
    my $err=`$GZIP $tmpfile 2>&1`;
    if ($err){print "problems with gzip: ",$err;return undef;}

    while (-e $txtfile){$txtfile='A'.$txtfile;}
    move("$tmpfile.gz",$txtfile);                # create the corpus file
    my $lckfile="$ThisCorpusDir/$lang.gz.lock";
    open F,">$lckfile";close F;                  # create a lock file
    chmod 0664,$txtfile;
    chmod 0664,$lckfile;
    unlink $tmpfile;
    unlink "$tmpfile.gz";

    return $txtfile;
}

sub GetTempFileName{
    my $fh;
    my $file;
    do {$file=tmpnam();}
    until ($fh=IO::File->new($file,O_RDWR|O_CREAT|O_EXCL));
    $fh->close;
    return $file;
}



sub ChangeWordLinks{
    my $file=shift;
    my $links=shift;
    my $params=shift;

    my $sentLink=$params->{seg};
    print "change links is not implemented yet!<br>";
    print join '+',@{$links};
    print '<hr>';


#    if (not -e $file){return 0;}
#    if ($file=~/\.gz$/){open F,"$GUNZIP < $file |";}
#    else{open F,"< $file";}
#    my $sec=0;
#    while (not flock(F,2)){
#	$sec++;sleep(1);
#	if ($sec>$MAXFLOCKWAIT){
#	    close F;
#	    return 0;
#	}
#    }
#    local $/='<link ';
#    my @align=<F>;
#    print join '<hr>',@align;
#
#    close F;

}
