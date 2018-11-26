#!/usr/bin/perl
#-*-perl-*-

use FindBin qw( $Bin );
use lib $Bin. '/../lib';

use Test::More;
use File::Compare;

use Uplug;

my $UPLUG = $Bin.'/../uplug';
my $DATA  = $Bin.'/data';

# POS tagging requires java!
my $JAVA=`which java`;
chomp $JAVA;

my $null = "2> /dev/null >/dev/null";

# make a dummy test (avoid failure in case java is not installed)
ok(1, 'load Uplug module');

if (-e $JAVA){
    system("$UPLUG pre/en/tagGrok -in $DATA/xml/1988en.basic.xml -out pos_en.xml $null");
    # is( compare( "pos_en.xml", "$DATA/xml/1988en.grok.xml" ),0, "en POS tagged (Grok)" );
    system("grep -o 'pos=\"[^\"]*\"' pos_en.xml > pos_en " );
    system("grep -o 'pos=\"[^\"]*\"' $DATA/xml/1988en.grok.xml > 1988en" );
    is( compare( "pos_en", "1988en" ),0, "en POS tagged (Grok)" );
    unlink("pos_en.xml");
    unlink("pos_en");
    unlink("1988en");

    system("$UPLUG pre/en/chunk -in $DATA/xml/1988en.grok.xml -out chunk.xml $null");
    # is( compare( "chunk.xml", "$DATA/xml/1988en.chunk.xml" ),0, "en chunking (grok)" );
    system("grep -o 'type=\"[^\"]*\"' chunk.xml > chunk " );
    system("grep -o 'type=\"[^\"]*\"' $DATA/xml/1988en.chunk.xml > 1988en" );
    is( compare( "chunk", "1988en" ),0, "en chunking (Grok)" );
    unlink("chunk");
    unlink("1988en");
    unlink("chunk.xml");
    system("rm -fr data/runtime");
}

done_testing;

