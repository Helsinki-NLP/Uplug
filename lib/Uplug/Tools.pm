#-*-perl-*-
#####################################################################
#
# $Author$
# $Id$
#
#---------------------------------------------------------------------------
# Copyright (C) 20012 Joerg Tiedemann
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



package Uplug::Tools;

use strict;

use File::ShareDir qw(dist_dir);

our $SHARED_BIN = -d &dist_dir('Uplug') ? 
    &dist_dir('Uplug') . '/bin' : $ENV{UPLUGHOME}.'/share/bin';
our $SHARED_LIB = -d &dist_dir('Uplug') ? 
    &dist_dir('Uplug') . '/lib' : $ENV{UPLUGHOME}.'/share/lib';

our $OS_TYPE      = $ENV{OS_TYPE} || `uname -s`;
our $MACHINE_TYPE = $ENV{MACHINE_TYPE} || `uname -m`;

chomp($OS_TYPE);
chomp($MACHINE_TYPE);


sub find_executable{
  my $name = shift;

  # try to find in the path

  my $path = `which $name`;
  chomp($path);
  return $path if (-e $path);

  # try to find it in the shared tools dir

  return join('/',$SHARED_BIN,$OS_TYPE,$MACHINE_TYPE,$name) 
      if (-e join('/',$SHARED_BIN,$OS_TYPE,$MACHINE_TYPE,$name) );
  return join('/',$SHARED_BIN,$OS_TYPE,$name) 
      if (-e join('/',$SHARED_BIN,$OS_TYPE,$name) );
  return $SHARED_BIN.'/'.$name if (-e $SHARED_BIN.'/'.$name);

  # try to find it

  $path = `find -type f -name '$name' $SHARED_BIN`;
  chomp($path);
  return $path if (-x $path);

}


1;
