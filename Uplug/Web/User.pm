
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
package Uplug::Web::User;

use strict;
use Exporter;
use lib '/home/staff/joerg/user_perl/lib/perl5/site_perl/5.6.1/';
use Mail::Mailer;
use Uplug::Web::Process::Stack;

use vars qw(@ISA @EXPORT);

@ISA=qw( Exporter);
@EXPORT = qw( ReadUserInfo );

our $UplugAdmin='joerg@stp.ling.uu.se';

my $Uplug2Dir='/corpora/OPUS/uplug2/';
my $CorpusDir=$Uplug2Dir;
my $UserDataFile=$Uplug2Dir.'user';
my $PasswordFile=$Uplug2Dir.'.htpasswd';

# my $IniDir=$CorpusDir.'/ini';
# my $CorpusFile=$IniDir.'/uplugUserStreams';


######################################################################

sub RemoveUser{
    my $user=shift;
    my %UserData=();
    &ReadUserInfo(\%UserData,$user);
    if (not -e "$CorpusDir/.recycled"){
	`mkdir $CorpusDir/.recycled`;
	`chmod 755 $CorpusDir/.recycled`;
	`chmod g+s $CorpusDir/.recycled`;
    }
    if (-e "$CorpusDir/.recycled/$user"){
	`rm -fr $CorpusDir/.recycled/$user`;
    }
    `mv $CorpusDir$user $CorpusDir/.recycled/`;

    my $UserInfo=Uplug::Web::Process::Stack->new($UserDataFile);
    $UserInfo->remove($user);

    &SendMail($user,'UplugWeb account',
	      'Your UplugWeb account has been removed!');
}


sub EditUser{
    my $user=shift;
    my %UserData=();
#    &ReadUserInfo(\%UserData,$user);
    print "edit $user (not implemented yet!)";
}


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

    my ($to,$subject,$message)=@_;

    my $mailer=Mail::Mailer->new("sendmail");
    $mailer->open({From    => $UplugAdmin,
		   To      => $to,
		   Subject => $subject});
    print $mailer $message;
    $mailer->close();
}


sub SendFile{

    my ($to,$subject,$file)=@_;

    if (not -e $file){return 0;}

    my $mailer=Mail::Mailer->new("sendmail");
    $mailer->open({From    => $UplugAdmin,
		   To      => $to,
		   Subject => $subject});

    if ($file=~/\.gz$/){open F,"gzip -cd $file |";}
    else{open F,"<$file";}
    binmode (F);
    while (<F>){print $mailer $_;}
    $mailer->close();
}

