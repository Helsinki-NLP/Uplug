#!/usr/bin/perl
#---------------------------------------------------------------------------
# register.pl                                 Joerg Tiedemann
#
#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------

require 5.002;
use strict;

use lib '/home/staff/joerg/user_perl/lib/perl5/site_perl/5.6.1/';
use Mail::Mailer;
use CGI qw/:standard/;

my $css = '/~joerg/uplug2/menu.css';
my $UplugAdmin='joerg@stp.ling.uu.se';
my $UplugHomeUrl='/~joerg/uplug2/user/';

my %ParamValue=();
my @ParamName = (
		 'User',
		 'Name',
		 'Address',
		 'ZIP',
		 'City',
		 'Country',
		 'Telephone',
		 'Password',
		 're-typed',
		 'license'
		 );
&GetParameter(\@ParamName,\%ParamValue);
my %ParamSpec=(
	       'User'     => '^\S+\@\S+\.\w{2,3}$',
	       'Name'     => '\S',
	       'Address'  => '.*',
	       'ZIP'      => '.*',
	       'City'     => '.*',
	       'Country'  => '.*',
	       'Telephone'=> '.*',
	       'Password' => '.+',
	       'license' => '1',
	       're-typed' => "\^$ParamValue{'Password'}\$"
	       );

my $Uplug2Dir='/corpora/OPUS/uplug2/';
my $CorpusDir=$Uplug2Dir;
my $UserDataFile=$Uplug2Dir.'user';
my $PasswordFile=$Uplug2Dir.'.htpasswd';

# my $PasswordFile='/tmp/tttt';


print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug user registry',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$css},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));




if (not &CheckParameter(\%ParamValue,\@ParamName,\%ParamSpec)){
    print &end_html;
    exit;
}


if (&MakeNewUser(\%ParamValue)){
    my $body=&MakeEmailBody(\%ParamValue);
    my $subject='UplugWeb registration';
    &SendUserInfo($UplugAdmin,$ParamValue{'User'},$subject,$body);
    &SendUserInfo($UplugAdmin,$UplugAdmin,$subject,$body);
}
&PrintUserInfo;
print &end_html;


sub PrintUserInfo{
    print '<table border=0>';
    print "<tr><th>Name</th><td>$ParamValue{'Name'}</td></tr>\n";
    print "<tr><th>Address</th><td>$ParamValue{'Address'}</td></tr>\n";
    print "<tr><th></th><td>$ParamValue{'ZIP'} $ParamValue{'City'}</td></tr>\n";
    print "<tr><th></th><td>$ParamValue{'Country'}</td></tr>\n";
    print "<tr><th>Telphone</th><td>$ParamValue{'Telephone'}</td></tr>\n";
    print "<tr><th>e-mail</th><td>$ParamValue{'User'}</td></tr>\n";
    print '</table>';
    print '<p>Your e-mail address will be used as your private user name. 
              Please, use it exactely as specified
              above to enter the Uplug user pages.
              The password, you have specified, will be sent to you by e-mail.
              You do not have to wait for the mail. Your account has been
              created already.
           <br>Click ';
    print "<a target=\"_top\" href=\"$UplugHomeUrl\">here</a> to login!";
    print '
           <p>Send e-mail to 
           <A HREF="mailto:joerg@stp.ling.uu.se">joerg@stp.ling.uu.se</A>
           in case of any trouble. Any kind of feedback is very welcome!
           <p>Enjoy using UplugWeb and good luck!';
}


sub MakeEmailBody{
    my $ParamValue=shift;
    my $MailText="Name        $ParamValue{'Name'}\n";
    $MailText.="Address     $ParamValue{'Address'}\n";
    $MailText.="            $ParamValue{'ZIP'} $ParamValue{'City'}\n";
    $MailText.="            $ParamValue{'Country'}\n";
    $MailText.="Tel         $ParamValue{'Telephone'}\n";
    $MailText.="e-mail      $ParamValue{'User'}\n";
    $MailText.="Password    $ParamValue{'Password'}\n\n";
    $MailText.='
Your e-mail address will be used as your private user name. 
Please, use your complete e-mail address exactely as specified
above to enter the Uplug user pages.

Send e-mail to joerg@stp.ling.uu.se in case of any trouble.
Any kind of feedback is very welcome!

Enjoy using UplugWeb and good luck!


Jörg Tiedemann

***********/\/\/\/\/\/\/\/\/\/\/\************************************
**  Joerg Tiedemann                 joerg@stp.ling.uu.se           **
**  Department of Linguistics    http://stp.ling.uu.se/~joerg/     **
**  Uppsala University               tel: (018) 471 7007           **
**  S-751 20 Uppsala/SWEDEN          fax: (018) 471 1416           **
*************************************/\/\/\/\/\/\/\/\/\/\/\**********
';
    return $MailText;
}


sub SendUserInfo{

    my ($from,$to,$subject,$message)=@_;

    my $mailer=Mail::Mailer->new("sendmail");
    $mailer->open({From    => $from,
		   To      => $to,
		   Subject => $subject});
    print $mailer $message;
    $mailer->close();
}

sub GetParameter{
    my ($ParamName,$ParamValue)=@_;
    foreach (@{$ParamName}){
	$$ParamValue{$_} = param($_);
    }
}

sub CheckParameter{
    my ($ParamValue,$ParamName,$ParamSpec)=@_;
    my $ParamOK=1;
    foreach (@{$ParamName}){
	if ($$ParamValue{$_}!~/$ParamSpec{$_}/){
	    if ($ParamOK){
		print '<strong>Oops!</strong> ';
		print "The following data have not been specified correctly:";
		print '<strong><ul>';
	    }
	    print "<li>$_\n";
	    $ParamOK=0;
	}
    }
    if (not $ParamOK){
	print '</ul></strong>';
	print '<p><hr>Please, fill out the form correctly and try again<br>';
    }
    return $ParamOK;
}


sub MakeNewUser{

    my $UserData=shift;
    my $User=$UserData->{User};
    my $Password=$UserData->{Password};

    if (not -e $CorpusDir){
	system "mkdir $CorpusDir";
    }
    if (not -e "$CorpusDir$User"){
	system "mkdir $CorpusDir$User";
	system "mkdir $CorpusDir$User/ini";
	system "touch $CorpusDir$User/ini/uplugUserStreams.ini";
	system "chmod g+w $CorpusDir$User/ini/uplugUserStreams.ini";
	system "touch $CorpusDir$User/user";

#	system "touch $PasswordFile";
#	system "chmod g+w $PasswordFile";
	$UserData->{corpora}="$CorpusDir$User/ini/uplugUserStreams.ini";

	if (system "/usr/bin/htpasswd -nb '$User' '$Password' >>$PasswordFile"){
	    print "problems: $!<br>";
	}

#	if (not -e $PasswordFile){
#	    if (system "/usr/bin/htpasswd -c -b $PasswordFile '$User' '$Password'"){
#		print "problems: $? --- $! -- $@\n";
#	    }
#	}
#	elsif (system "/usr/bin/htpasswd -nb '$User' '$Password' >>$PasswordFile";){
#	    print "problems: $? --- $! -- $@<br>";
#	}
#	else{
#	    if (system "/usr/bin/htpasswd -b $PasswordFile '$User' '$Password'"){
#		print "problems: $? --- $! -- $@<br>";
#	    }
#	}
	
	&SaveUserData("$CorpusDir$User/user",$UserData);
	system "echo '$UserData->{User}:$CorpusDir$User/user' >>$UserDataFile";
    }
    else{
	print "User $User exists already!".&p();
	return 0;
    }
    return 1;
}




sub SaveUserData{
    my ($file,$UserData)=@_;
    if (not -e $Uplug2Dir){
	system "mkdir $Uplug2Dir";
    }
    open F,">$file";
    foreach (keys %{$UserData}){
	if ($_ eq 'license'){next;}
	if ($_ eq 're-typed'){next;}
	print F "$_:$UserData->{$_}\n";
    }
    close F;
}
