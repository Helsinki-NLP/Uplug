#!/usr/bin/perl
#-*-perl-*-

use Test::More;
use File::Compare;

use Uplug;

my $UPLUG = 'uplug';
my $DATA  = 'data';

my $null = "2> /dev/null >/dev/null";

for $l ('de','en','sv'){
    system("$UPLUG pre/$l/tagHunPos -in $DATA/xml/1988$l.basic.xml -out pos_$l.xml $null");
    is( compare( "pos_$l.xml", "$DATA/xml/1988$l.hunpos.xml" ),0, "$l POS tagged (hunpos)" );
    unlink("pos_$l.xml");
}


done_testing;

