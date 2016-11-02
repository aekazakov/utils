#! /usr/bin/perl

use 5.010;
use strict;
use warnings;

my $gene_prefix;

if (@ARGV == 1) {
	$gene_prefix = "";
} elsif (@ARGV != 2) {
	print "Usage: perl convert_genome2.pl <file name> <gene prefix> (omit gene prefix to convert locus tags into gene names)";
	exit(0);
};
my $filename = $ARGV[0];
my $line;
my @contigs = ();
my $length = 0;
my $definition = "";
my $contig_count = 0;
my $gene_count = 1;
my $definition_flag = 0;
my $sequence_flag = 0;
my $features_flag = 0;
my $features = "";
my @sequence = ();
my $a_count = 0;
my $c_count = 0;
my $g_count = 0;
my $t_count = 0;
my $tail = "";
open (INFILE, $filename);
my $contig_data = {};

while ($line = <INFILE>) {
	chomp $line;
	if ($line =~ /^LOCUS     /) {
		$line =~ s/ {1,}/ /g;
		my @locus_data= split(" ",$line);
		$contig_data->{"locus"}=$locus_data[1];
		$contig_data->{"length"}=$locus_data[2];
		$length += $locus_data[2];
	} elsif ($line =~ /^DEFINITION  /) {
		$definition_flag = 1;
		my @definition_data= split("/t",$line);
		$definition = $definition_data[1];
	} elsif ($line =~ /^ACCESSION   /) {
		$definition_flag = 0;
	} elsif ($line =~ /^FEATURES   /) {
		$definition_flag = 0;
		$features_flag = 1;
	} elsif ($line =~ /^BASE COUNT   /) {
		$definition_flag = 0;
		$features_flag = 0;
		$line =~ s/ {1,}/ /g;
		my @basecount_data= split(" ",$line);
		$a_count += $basecount_data[2];
		$c_count += $basecount_data[4];
		$g_count += $basecount_data[6];
		$t_count += $basecount_data[8];
	} elsif ($line =~ /^ORIGIN/) {
		$definition_flag = 0;
		$features_flag = 0;
		$sequence_flag = 1;
	} elsif ($line =~ /^\/\//) {
		$contig_data->{"features"}=$features;
		push(@contigs, $contig_data);
		$features = "";
		$contig_data = {};
		$definition = "";
		$definition_flag = 0;
		$features_flag = 0;
		$sequence_flag = 0;
		$contig_count++;
	} elsif (($definition_flag == 1) && ($features_flag == 0) && ($sequence_flag == 0)){
		$definition = $definition.$line;
	} elsif (($definition_flag == 0) && ($features_flag == 1) && ($sequence_flag == 0)){
		$features = $features.$line."\n";
	} elsif (($definition_flag == 0) && ($features_flag == 0) && ($sequence_flag == 1)){
		$line =~ s/(\d+)//g;
		$line =~ s/\s//g;
		$line = $tail.$line;
		if (length($line) > 60) {
			push(@sequence, substr($line, 0, 60));
			$line = substr($line, 60);
		}
		$tail = $line;
		
	} else {
#		print "Unexpected line:\n".$line."\n";
#		exit(1);
#		if ($line =~ /^     CDS             /) {
#			$contig_data = $contig_data.$line."                     /gene=\"".$filename."_".$gene_count."\"\n";
#			$gene_count++;
#		} else {
#			$contig_data = $contig_data.$line;
#		};
	};
};
push(@sequence, $tail);
close INFILE;

my $result_file = $filename.".gbk";
open (OUTFILE, ">$result_file");
print OUTFILE "LOCUS       $filename         $length bp    DNA     linear   UNK\n";
print OUTFILE "DEFINITION  Genome sequences from $filename file, $contig_count contigs\n";
print OUTFILE "ACCESSION   Unknown\n";
print OUTFILE "FEATURES             Location/Qualifiers\n";
print OUTFILE "     source          1..$length\n";

my @sourcedata = split ("\n",${$contigs[0]}{features});
foreach my $line (@sourcedata) {
	if ($line =~ /^     source          /){}
	elsif ($line =~ /^     \w/){
		last;
	}
	else {
		print OUTFILE $line."\n";
	};
};

#print feature table
my $shift = 0;
foreach my $contig_ref (@contigs){
	foreach my $line (split ("\n",${$contig_ref}{features})){
		if ($line =~ /^     source          /) {
			$line =~ s/     source          /     misc_feature    /;
		};
		if ($line =~ /(\d+)\.\.(\d+)/){
			my @all_nums = $line =~ /(\d+)/g;
			if ($all_nums[2]) {
				print "Unknown format: $line\n";
				exit(1);
			} else {
				my $feature_start = $all_nums[0] + $shift;
				my $feature_end = $all_nums[1] + $shift;
				$line =~ s/$all_nums[0]\.\./$feature_start../;
				$line =~ s/\.\.$all_nums[1]/..$feature_end/;
			};
		};
		if ($line =~ /(\d+)\.\.\>(\d+)/){
			my @all_nums = $line =~ /(\d+)/g;
			if ($all_nums[2]) {
				print "Unknown format: $line\n";
				exit(1);
			} else {
				my $feature_start = $all_nums[0] + $shift;
				my $feature_end = $all_nums[1] + $shift;
				$line =~ s/$all_nums[0]\.\./$feature_start../;
				$line =~ s/\.\.>$all_nums[1]/..>$feature_end/;
			};
		};
		if ($line =~ /locus_tag=\"/) {
			if ($gene_prefix eq "") {
				$line =~ s/                     \/locus_tag=\"/                     \/gene=\"/;
				print OUTFILE $line."\n";
			};
		} else {
			print OUTFILE $line."\n";
		};
		if ($line =~ /^     CDS             /) {
			if ($gene_prefix ne "") {
				print OUTFILE "                     /gene=\"".$gene_prefix."_".$gene_count."\"\n";
				$gene_count++;
			};
		};
		if ($line =~ /^     misc_feature    /) {
			print OUTFILE "                     /note=\"contig ".${$contig_ref}{locus}."\"\n";
		};
	};
	$shift += ${$contig_ref}{length};		
};

print OUTFILE "BASE COUNT     $a_count a   $c_count c   $g_count g   $t_count t\n";
print OUTFILE "ORIGIN\n";

#print sequence
my $line_count = 0;
foreach my $line (@sequence) {
	my @str = $line =~ /.{1,10}/gs;
	printf OUTFILE '%9s', $line_count*60 + 1;
	foreach my $str (@str){
		print OUTFILE " $str";
	};
	print OUTFILE "\n";
	$line_count++;
};

print OUTFILE "\/\/\n";
close OUTFILE;
exit(0);