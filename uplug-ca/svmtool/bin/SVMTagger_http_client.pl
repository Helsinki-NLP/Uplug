#!/usr/bin/perl
# Author      : Jesus Gimenez
# Date        : November 30, 2009
# Description : SVMTagger HTTP client.
#
# Usage: SVMTagger_http_client [options]
#
# ------------------------------------------------------------------------
# ------------------------------------------------------------------------

#Copyright (C) 2009 Jesus Gimenez and Lluis Marquez

#This library is free software; you can redistribute it and/or
#modify it under the terms of the GNU Lesser General Public
#License as published by the Free Software Foundation; either
#version 2.1 of the License, or (at your option) any later version.

#This library is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#Lesser General Public License for more details.

#You should have received a copy of the GNU Lesser General Public
#License along with this library; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# ------------------------------------------------------------------------

my $URL = 'localhost';
my $PORT = 26080;

require HTTP::Request;
require LWP::UserAgent;
use URI;
use URI::QueryParam;
use Getopt::Long;
use Data::Dumper;

sub get_out {
   $0 =~ /\/([^\/]*$)/;
   print STDERR "Usage : ", $1, " [options]\n\n";
   print STDERR "options:\n";
   print STDERR "  - url        URL (default $URL)\n";
   print STDERR "  - port       port number (default $PORT)\n";
   print STDERR "  - v          verbose\n";
   print STDERR "  - help!      this help\n";
   print STDERR "\nExample : $1 -v -url $URL -port $PORT\n\n";
   exit(1)
}

sub process_response($) {
    #description _ extracts true response out from raw response content
    #param1  _ response object

    my $response = shift;

    my @result = split("\n", $response->decoded_content);
    my @tags = split(" ", $result[0]);
    shift(@tags);
    return join(" ", @tags); 
}

# read options ------------------------------------------------------------------
my %options = ();
GetOptions(\%options, "url=s", "port=i", "v!", "help!");
if ($options{"help"}) { get_out(); }
my $verbose = $options{"v"};
my $url = $URL;
my $port = $PORT;
if (defined($options{"url"})) { $url = $options{"url"}; }
if (defined($options{"port"})) { $port = $options{"port"}; }

if ($verbose) { print STDERR "READY FOR TAGGING [http://$url:$port]\n"; }

while (my $sentence = <STDIN>) {    
    # send request ------------------------------------------------------------------
    my $uri = URI->new_abs('tag', 'http://'.$url.':'.$port);
    $uri->query_param('input', $sentence);
    $request = HTTP::Request->new(GET => $uri);
    $ua = LWP::UserAgent->new;
    $response = $ua->request($request);

    # show response -----------------------------------------------------------------
    if ($response->is_success) {
       $tags = process_response($response);
       print $tags, "\n";
    }
    else { die $response->status_line; }
}
