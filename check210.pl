#!/usr/bin/perl

############################################################
# You will need an OCLC developer's key to make the program
# work. You can get a free one from OCLC http://oclc.org/developer/
# Anyone can use the basic API, but you need the unlimited
# one (institutional cataloging subscription required) so
# you don't bounce off limits on the service.
#
# This program takes a tab delimited file extracted from 
# a Millennium system (repeated field delimiter is a semicolon)
# searches the record in OCLC using the WorldCat API, and 
# generates a message if a field you're looking for is not
# present or if there are values in that field in Mil which 
# are not present in the master record.
#
# In the example code, it looks for the key title and subjects
# but different fields (or more fields) could be used
##############################################################


use strict;
use warnings;
use LWP::Simple;

my $milfile = '210.txt';
my $outputfile = 'fix_210.txt';

######################################
# make sure line feeds delimit records
######################################
local $/ = undef;
$/ = "\n";

########################################################################
# initialize a few variables. You'll need a developer's key from OCLC to
# make this work
########################################################################
my $baseurl = "http://worldcat.org/webservices/catalog/content/";

open my $wskeyfile, '<', "wskey.txt";
my $wskey = <$wskeyfile>;
close $wskeyfile;

#####################################
# if you create any new fields to 
# search for, you should declear them
# here
#####################################
my $content = '';
my $url = '';
my $keytitle = '';
my $oclc = '';
my $entry = '';
my $subject = '';
my $record_message = '';
my $match_expression = '';
my $headingcounter = 0;

my @mildata = [];
my @fields = [];
my @subjects = [];

########################################
# Read the entire file from Millennium
# into an array
########################################
open (MILDATA, $milfile) or die("Unable to open data file \"$milfile\"");
@mildata = <MILDATA>;
close(MILDATA);

open (OUTFILE, '>:utf8',$outputfile);

foreach $entry(@mildata) {
	$record_message = '';

	@fields = split(/\t/, $entry);

	############################
	# oclc is in the first field
	# and is not expected to contain
	# multiple values
	############################
	$oclc = $fields[0];
	$keytitle = $fields[1];
	chomp($keytitle);

	#######################################
	# First, let's get the record from OCLC
	#######################################
	$url = $baseurl . $oclc . '?servicelevel=full&wskey=' . $wskey; 
	$content = get $url;

	##################################################################
	# The XML retrieved from OCLC is full of whitespace, so we remove
	# whitespace between tags. This allows us to use simpler and faster
	# string processing rather than XML parsing to do our tests
	##################################################################
	$content =~ s/>\s+</></g;

	####################################################################
	# Our search criteria for the Create List did not require this field
	# to be present, so we check for its existence before running any
	# tests on the OCLC record
	####################################################################

	if ($fields[1] =~ /[a-z]/) {
		
		#########################################
		# verify presence of field in OCLC record
		#
		# Note that we are matching on regular
		# expressions, not just simple strings
		#########################################
		if ($content !~ /<datafield ind1="." ind2="." tag="210">/) {
			print OUTFILE $oclc . "\t" . $keytitle . "\n";
			$record_message .= " $keytitle not found. ";
			print "$keytitle not found in $oclc\n";
			} else {
			print "$keytitle located in $oclc\n";
			}
		}

	}	


#sleep(3);  #  recommended delay between queries


