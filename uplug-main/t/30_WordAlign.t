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

#-------------------------------------------------
# basic word alignment

system("$UPLUG align/hun -src $DATA/xml/1988sv.basic.xml -trg $DATA/xml/1988en.basic.xml -out sentalign.xml $null");
system("$UPLUG align/word/basic -in sentalign.xml -out wordalign.xml $null");

is( &xtargets("wordalign.xml"), 
    &xtargets("$DATA/xml/sv-en/1988.wa.basic.xml"), 
	"word alignment (basic)" );

unlink('giza-refined.links');
unlink('sentalign.xml');
unlink('wordalign.xml');
system("rm -fr data/runtime");

done_testing;



sub xtargets{
    my $file=shift;
    open(F,"<$file");
    my @xtargets=<F>;
    close F;
    @xtargets = grep(/xtargets/,@xtargets);
    map( s/^.*(xtargets="[^"]*").*/$1/, @xtargets );
    return join("\n",@xtargets);
}
