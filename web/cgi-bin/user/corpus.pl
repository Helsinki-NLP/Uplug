#!/usr/bin/perl
#---------------------------------------------------------------------------
# corpus.pl - a simple corpus manager
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

require 5.002;
use strict;

use CGI qw/:standard/;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use UplugUser;
use UplugCorpus;
use UplugWeb;


#BEGIN { 
#    use CGI::Carp qw(carpout);
#    open L, ">>/tmp/uplugWeb.log" || die ("could not open log\n");
#    carpout(*L);
#}
#`chmod g+w /corpora/OPUS/uplug2/joerg\@stp.ling.uu.se/ini/uplugUserStreams.ini`;

if (defined &url_param('action')){&param('action',&url_param('action'));}
if (defined &url_param('pos')){&param('pos',&url_param('pos'));}
if (defined &url_param('style')){&param('style',&url_param('style'));}
if (defined &url_param('corpus')){&param('corpus',&url_param('corpus'));}
if (defined &url_param('owner')){&param('owner',&url_param('owner'));}

my $user = &remote_user;
my $action = param('action');
my $corpus = param('corpus');
my $owner = param('owner');
my $pos = param('pos');
my $style = param('style');
my @links = param('links');

my $url=url();
my $query=url(-query=>1);

######################################################################

print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug - Corpus Manager',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$CSS},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));


print &h2("UplugWeb - Corpus Manager");

print "tasks: ",&UplugWeb::ActionLinks($url,'view all','view my','add'),&p();
print &hr;

my %CorpusData=();
my %params;
if (param()) {%params=&CGI::Vars();}

if ($action eq 'remove'){
    &UplugCorpus::RemoveCorpus($user,$owner,$corpus);
    print &UplugWeb::ShowCorpusInfo($user,$owner,$corpus,$query);
}
elsif ($action eq 'view'){
    print &UplugWeb::ViewCorpus($user,$owner,$corpus,$query,$pos,$style,
				\%params,\@links);
}
elsif ($action eq 'send'){
    if (&UplugCorpus::SendCorpus($user,$owner,$corpus)){
	print "$corpus has been send to $user!";
    }
}
elsif ($action eq 'add'){
    &UplugCorpus::GetCorpusData(\%CorpusData,$user);
    &AddCorpus($user);
}
elsif ($action eq 'view my'){
    print &UplugWeb::ShowCorpusInfo($user,$user,$corpus,$query);
}
else{
    print &UplugWeb::ShowCorpusInfo($user,$owner,$corpus,$query);
}


print &end_html;


#------------------------------------------------------------





sub AddCorpus{
    my $user=shift;

    my $name=param('name');
    my $file=param('file');
    my $lang=param('lang');
    my $enc=param('enc');

    my $CorpusName=&UplugCorpus::GetCorpusName($name,$lang);

    #------------------------------------------------------------

    my $missing=0;
    my @rows=();

    if (not $name){$missing++;}
    if ((defined $name) and ($name!~/^[a-zA-Z\.\_0-9]{1,10}$/)){
	$missing++;
	print "Corpus name $name is not valid!",&br();
    }
    if (defined $CorpusData{$CorpusName}){
	$missing++;
	print "A corpus with the name '$CorpusName' exists already!",&br();
    }
    if (not $file){$missing++;}

    if (not defined $enc){$enc='utf8';}
    if (not defined $lang){$lang='en';}

    #------------------------------------------------------------

    if ($missing){
	print &AddCorpusQuery;
    }
    else{
	if (&UplugCorpus::AddTextCorpus($user,$name,$lang,$file,$enc)){
	    print &h3("The corpus $CorpusName has been successfully added!");
	}
	else{
	    print &h3("Operation failed!");
	    print &AddCorpusQuery;
	}
	print &UplugWeb::ShowCorpusInfo($user,$user,$corpus,$query);
    }
}



sub AddCorpusQuery{
    my @rows;
    push (@rows,&td(["Corpus name: ",
		     &textfield(-name=>'name',
				-size=>25,
				-maxlength=>50).
		     &UplugWeb::iso639_menu('lang','en')]));

    push (@rows,&td(["Corpus file: ",
		     &filefield(-name=>'file',
				-size=>25,
				-maxlength=>50)]));

    push (@rows,&td(['Encoding',&UplugWeb::encodings_menu('enc','utf8')]));

    my $str="Add corpus files to your repository!".&p();
    $str.= "Specify a unique name for your corpus ";
    $str.= "with not more than 10 characters!".&br;
    $str.= "Use ASCII characters only for the name of the corpus using the following character set: ";
    $str.= "[a-z,A-Z,0-9,_,.]!".&br();
    $str.= "Each corpus may consists of multiple files in different languages!".&p();
    $str.= "The file must be a plain text file! Additional markup is not recognized and will be used as text!".&br();
    $str.= "Make sure that the specified character encoding matches the encoding of your corpus file".&br();
    $str.= "Check for example ".&a({-href => 'http://czyborra.com/charsets/iso8859.html'},'this').' page for more information about character encoding'.&br();


    $str.= &start_multipart_form;
    $str.= &table({},caption(''),&Tr(\@rows));
    $str.= &p();
    $str.= &submit(-name => 'submit');
    $str.= &endform;
}
