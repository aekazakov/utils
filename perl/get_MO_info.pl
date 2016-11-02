#! /usr/bin/perl

###############################################
### Get locus tags and genome name by MO id ###
###############################################


#Modules
use warnings;
use strict;
use Microbesonline;

#open (STDERR, ">&STDOUT");

#Variables
my $moFileName = "moids.txt";
my $outFileName = "out.txt";
my $microbesonline = new Microbesonline;
my $moId;

$microbesonline->connect;

open (INFILE, "$moFileName");
open (OUTFILE, ">$outFileName");

while (<INFILE>)
	{
		chomp;
		$moId = $_;
		if ($moId eq "-"){
			print OUTFILE "-\n";
		} else{
			my $genomeName = $microbesonline->getGenomeName($moId);
			my $locusTag = $microbesonline->getLocusTag($moId);
			print OUTFILE "$moId\t$locusTag\t$genomeName\n";
		}
	}

close INFILE;
close OUTFILE;
$microbesonline->disconnect;

exit;

