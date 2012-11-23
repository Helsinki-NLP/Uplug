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

#-------------------------------------------------
# basic word alignment

system("$UPLUG align/word/basic -in $DATA/xml/de-en/1988.sent.xml -out align.xml $null");
is( compare( "align.xml", "$DATA/xml/de-en/1988.wa.basic.xml" ),0, "wordalign (basic)" );
unlink('align.xml');
system("rm -fr data/runtime");

done_testing;

