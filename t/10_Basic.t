#!/usr/bin/perl
#-*-perl-*-

use FindBin qw( $Bin );
use lib $Bin. '/../lib';

use Test::More;
use File::Compare;

use Uplug;


my $UPLUG = $Bin.'/../uplug';
my $DATA  = 'data';


my $null = "2> /dev/null >/dev/null";


# simple markup steps

system("$UPLUG pre/markup -ci 'iso-8859-1' -in $DATA/txt/1988en.txt -out 1988en.markup.xml $null");
is( compare( "1988en.markup.xml", "$DATA/xml/1988en.markup.xml" ),0, "markup (1988en)" );

system("$UPLUG pre/sent -in 1988en.markup.xml -out 1988en.sent.xml $null");
is( compare( "1988en.sent.xml", "$DATA/xml/1988en.sent.xml" ),0,"sent (1988en)" );

system("$UPLUG pre/tok -in 1988en.sent.xml -out 1988en.tok.xml $null");
is( compare( "1988en.tok.xml", "$DATA/xml/1988en.tok.xml" ),0,"tok (1988en)" );


# cleanup ....

unlink('1988en.markup.xml');
unlink('1988en.sent.xml');
unlink('1988en.tok.xml');


# basic markup for different languages

foreach ('de','en','fr','sv'){
    system("$UPLUG pre/basic -ci 'iso-8859-1' -in $DATA/txt/1988$_.txt -out 1988$_.xml $null");
    is( compare( "1988$_.xml", "$DATA/xml/1988$_.basic.xml" ),0, "basic (1988$_)" );
}

unlink('1988de.xml');
unlink('1988en.xml');
unlink('1988fr.xml');
unlink('1988sv.xml');

# sentence alignment

system("$UPLUG align/sent -src $DATA/xml/1988de.basic.xml -trg $DATA/xml/1988en.basic.xml -out align.xml $null");
is( compare( "align.xml", "$DATA/xml/de-en/1988.basic.sent.xml" ),0, "sentence alignment (de-en)" );


unlink('align.xml');


done_testing;

