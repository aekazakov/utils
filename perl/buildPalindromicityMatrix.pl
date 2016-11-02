#! /usr/bin/perl

###############################################
###     Generate profile for palindromes    ###
###############################################

#Modules
use warnings;
use strict;

#Variables
my $inFileName = "Desal_0494.fasta";
#my $inFileName = "test.fasta";
my $line;
my @site;
my $sequence;
my @baseCounts = (0,0,0,0);
my $profileLength = 0;
my @sequences = ();
my $sequencesCount = 0;
open (INFILE, $inFileName);
while (<INFILE>) {
	$line = $_;
	chomp $line;
	if ($line =~ />/) {
#		print "\"$line\"\t";
		}
	else {
		$sequence = $line;
		if ($profileLength == 0) {
			$profileLength = length $sequence;
			}
			else {
				if ($profileLength != (length $sequence)) {
					die ("Sites in profile have different length")
					};
			};
		my @bases = split(//,$sequence);
		foreach my $base (@bases) {
			if ($base eq "A") {$baseCounts[0]++}
				elsif ($base eq "C") {$baseCounts[1]++}
				elsif ($base eq "G") {$baseCounts[2]++}
				elsif ($base eq "T") {$baseCounts[3]++}
				else {die("Unknown symbol $base\n")};
			};
		push (@sequences, $sequence);
		$sequencesCount++;
		};
	};

my $totalCount = $baseCounts[0] + $baseCounts[1] + $baseCounts[2] + $baseCounts[3];
my $backgroundProbability = 2*($baseCounts[0]*$baseCounts[3]/($totalCount**2) + ($baseCounts[1]*$baseCounts[2])/($totalCount**2));

#initialize positional matrix of palindromic position counts 
my @countsMatrix = ();
for  (my $i = 0; $i < $profileLength; $i++){
	$countsMatrix[$i] = 0;
	};

#build matrix of palindromic position counts
foreach (@sequences) {
	my $rcSequence = revcomp ($_);
	my @bases = split(//,$_);
	my @rcBases = split(//,$rcSequence);
	for (my $j = 0; $j<$profileLength; $j++) {
		if ($bases[$j] eq $rcBases[$j]) {
			$countsMatrix[$j]++;
			};
		};
	};
	

#build palindromic PWM
my @palindromicPWM = ();
for (my $k = 0; $k < $profileLength; $k++){
	if ($countsMatrix[$k] == 0){
		$palindromicPWM[$k] = 0;
		}
		else {
		$palindromicPWM[$k] = ($countsMatrix[$k]/$sequencesCount)*log($countsMatrix[$k]/($sequencesCount*$backgroundProbability));
		};
	};

#print PWM
print "Profile: $inFileName\n";
print "Profile length: $profileLength bp; Number of sites in profile: $sequencesCount\n^^\n";
foreach (@palindromicPWM) {
	printf("%1.2f\n", $_);
	};
print "=========================================\n";

my $scoreTreshold = 1000000;
foreach (@sequences) {
	my $score = evaluateSequence ($_, @palindromicPWM);
	print "$_\t$score\n";
	if ($score < $scoreTreshold) {
		$scoreTreshold = $score;
		};
	};
print "\nMin. score = $scoreTreshold\n";
close INFILE;
exit;


#######################
##### SUBROUTINES #####
#######################


sub revcomp {
my ($sequence) = @_;
my @bases = split(//,$sequence);
foreach my $base (@bases) {
	if ($base eq "A") {$base = "T"}
	elsif ($base eq "C") {$base = "G"}
	elsif ($base eq "G") {$base = "C"}
	elsif ($base eq "T") {$base = "A"}
	else {die("Unknown symbol $base\n")};
	}; 
my @reverseBases  = reverse(@bases);
my $rcSequence = "";
foreach (@reverseBases) {
	$rcSequence = $rcSequence.$_;
	};
return ($rcSequence); 
};

sub evaluateSequence {
my $sequence = shift;
my $sequenceLength = length $sequence;
my @profile = @_;
my $rcSequence = revcomp $sequence;
my @bases = split(//,$sequence);
my @rcBases = split(//,$rcSequence);
my $siteScore = 0;
for (my $i=0; $i<$sequenceLength; $i++){
	if ($bases[$i] eq $rcBases[$i]){
		$siteScore = $siteScore + $profile[$i];
		};
	};
return ($siteScore);
}