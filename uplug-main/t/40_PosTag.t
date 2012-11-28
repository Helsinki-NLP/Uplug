#!/usr/bin/perl
#-*-perl-*-

use FindBin qw( $Bin );
use lib $Bin. '/../lib';

use Test::More;
use File::Compare;

use Uplug;

my $UPLUG = $Bin.'/../uplug';
my $DATA  = $Bin.'/data';

my $null = "2> /dev/null >/dev/null";


for $l ('en','sv'){
    system("$UPLUG pre/$l/tagGrok -in $DATA/xml/1988$l.basic.xml -out pos_$l.xml $null");
    is( compare( "pos_$l.xml", "$DATA/xml/1988$l.grok.xml" ),0, "$l POS tagged (Grok)" );
    unlink("pos_$l.xml");

}

system("$UPLUG pre/en/chunk -in $DATA/xml/1988en.grok.xml -out chunk.xml $null");
is( compare( "chunk.xml", "$DATA/xml/1988en.chunk.xml" ),0, "en chunking (grok)" );
unlink("chunk.xml");
system("rm -fr data/runtime");


done_testing;

