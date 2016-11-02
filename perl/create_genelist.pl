#! /usr/bin/perl

use 5.010;
use strict;
use warnings;

if (@ARGV != 1) {
	print "Usage: perl create_genelist.pl <file name>";
	exit(0);
};
my $filename = $ARGV[0];
my $line;

my $gene_flag = 0;
my $outdata = "#START\tSTOP\tLabel\tColor\tDecoration\n";
open (INFILE, $filename);
my $contig_data = {};

while ($line = <INFILE>) {
	chomp $line;
	if ($line =~ /^     CDS/) {
		if (!$gene_flag) {
			$gene_flag = 1;
		} else {
			print "Not found locus tag before line $line \n";
			$outdata = $outdata."\t\t\n";
		};
		$line =~ s/     CDS             //g;
		$line =~ s/\)//g;
		$line =~ s/complement\(//g;
		$line =~ s/\.\./\t/g;
		print $line."\n";
		$outdata = $outdata.$line."\t";

	} elsif ($line =~ /^                     \/locus_tag="/) {
		if ($gene_flag){
			$gene_flag = 0;
			$line =~ s/                    \/locus_tag=//g;
			$line =~ s/\"//g;
			print $line."\n";
			$outdata = $outdata.$line."\t\t\n";
		};
	} else {
	};
};
close INFILE;

my $result_file = $filename.".tab";
open (OUTFILE, ">$result_file");
print OUTFILE $outdata;
close OUTFILE;
exit(0);