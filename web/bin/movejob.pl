#!/usr/bin/perl
#---------------------------------------------------------------------------
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------

require 5.002;
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use UplugProcess;

my ($user,$process,$from,$to)=@ARGV;

&UplugProcess::MoveJob($user,$process,$from,$to);

