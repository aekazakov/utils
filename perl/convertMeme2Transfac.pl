#! /usr/bin/perl

############################################################
###   Convert MEME v 4.4 profiles into Transfac matrix   ###
############################################################


#Modules
use warnings;
use strict;

#Variables
my $memeFileName = "bicluster_motifs_pssm_meme4.txt";
my $transfacFileName = $memeFileName;
my $line = "";
my $siteCount = 0;
my $matrix = "";
my $positionCount = 0;
my $profileSwitch = 0;
my $motifName = "";

$transfacFileName =~ s/meme/transfac/g;

open (INFILE, "$memeFileName");
open (OUTFILE, ">$transfacFileName");


while (<INFILE>)
	{
	$line = $_;
	chomp $line;
	if ($line =~ m/^MEME version 4.4/)
		{
		}
	elsif ($line =~ m/^MOTIF /)
		{
		#extract motif ID and put into matrix
		$line =~ s/^MOTIF //;
		$matrix = $matrix."DE\t".$line."\n";
		}
	elsif ($line =~ m/^letter-probability matrix/)
		{
		#extract nsites
		$line =~ s/letter-probability matrix: //;
		my @profileParameteres = split (" ", $line);
		$siteCount = $profileParameteres[5];
		#set profileSwitch = 1
		$profileSwitch = 1;
		}
	elsif (($line eq "")&&($profileSwitch == 1))
		{
		#put termination mark into matrix and flush matrix into the output file
		$matrix = $matrix."XX\n";
		print $matrix;
		#flush collected data into output file
		print OUTFILE $matrix;
		#reset variables
		$matrix = "";
		$siteCount = 0;
		$positionCount = 0;
		$profileSwitch = 0;
		}
	elsif (($line =~ m/^\d/)&&($profileSwitch == 1))
		{
		#get frequencies, multiply by nsites and write a line into matrix
		my @frequencies = split (" ", $line);
		$matrix = $matrix.$positionCount."\t";
		foreach my $frequency (@frequencies) 
			{
			$frequency = $frequency*$siteCount;
			$frequency = sprintf("%d", $frequency);
			$matrix = $matrix.$frequency."\t";
			};
		$matrix = $matrix."X\n";
		}
	else {};
	};

print OUTFILE $matrix;
close INFILE;
close OUTFILE;
exit;
