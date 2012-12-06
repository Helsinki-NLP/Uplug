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

system("$UPLUG pre/ja/toktag -in $DATA/xml/wiki.xml -out pos.xml $null");
is( compare( "pos.xml", "$DATA/xml/chasen.xml" ),0, "tagging (chasen)" );
unlink("pos.xml");
system("rm -fr data/runtime");

done_testing;

