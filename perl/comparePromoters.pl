#! /usr/bin/perl

######################################
##### Compare promoter positions #####
######################################

# Aim: take a list of promoter predictions a compare with a list of experimental transcription starts
# Step 1: read a list of predicted promoters
# Step 2: find absolute coordinate for each predicted  promoter
# Step 3: find a range of possible TSSs for each predicted promoter
# Step 4: create a list of TSSs associated with each promoter

#Modules
use warnings;
use strict;
use DBI;
use DBD::mysql;

#Variables
my $tssFileName = "transcription_starts.tab";
my $predictionFileName = "strong_promoters_search_results_2box.txt";
my $outFileName = "promoters_tss.txt";
my $line;
my $tssLine;
my %tss;

#MicrobesOnline database
my $host_mo = "pub.microbesonline.org";
my $database_mo = "genomics";
my $user_mo = "guest";
my $pw_mo = "guest";
my $db_handler_mo = DBI->connect("DBI:mysql:database=$database_mo;host=$host_mo", $user_mo, $pw_mo) or die "Unable to connect to $database_mo database!";

open (TSSFILE, "<", $tssFileName) or die;
open (PROMFILE, "<", $predictionFileName) or die;
open (OUTFILE, ">$outFileName") or die;
print OUTFILE "Locus Tag\tPromoter Begin\tPromoter Score\tPpromoter Sequence\tShift\tGene Start\tGene Direction\tTSS Position\tTSS Data\tscaffoldId\tstart\tstrand\tnf\tnppp\tntot\tatrich\tmidrich\trrich\tlevelrich\tavgrich\tindexrich\tatmin\tmidmin\trmin\tlevelmin\tavgmin\tindexmin\tstartm\tbits\tpos\tlnp\tmotif\tmin\trich\tlogoddsRich\tlogoddsMin\tlogoddsBits\tlogoddsNTot\tlo\n";

while ($tssLine = <TSSFILE>)
	{
	chomp $tssLine;
	if ($tssLine =~ m/^scaffoldId/)
		{
		#do nothing
		}
	elsif ($tssLine eq "")
		{
		#do nothing
		} 
	else
		{
		my @tssData = split ("\t", $tssLine);
		my $tssPosition = $tssData[1];
		$tss{$tssPosition} = $tssLine;
		}
	};

while ($line = <PROMFILE>)
	{
	processPredictedPromoter ($line, \%tss);
	};

$db_handler_mo->disconnect;
close TSSFILE;
close PROMFILE;
close OUTFILE;
exit;

#######################
##### SUBROUTINES #####
#######################


sub processPredictedPromoter 
{
my ($line, $tssReference) = @_;
chomp $line;
my ($locusTag, $promoterBegin, $promoterScore, $promoterSequence) = split ("\t", $line);
my ($geneStart, $geneDirection) = getGeneInfo ($locusTag);
#print "$locusTag\t$geneStart\t$geneDirection\n";
if ($geneDirection eq "+")
	{
	my $possibleTSS = $geneStart + $promoterBegin + 35;
	for (my $i = 0; $i < 4; $i++)
		{
		my $checkTSS = $possibleTSS + $i;
		if (defined ${$tssReference}{$checkTSS})
			{
			my $tssData = ${$tssReference}{$checkTSS};
			print OUTFILE "$locusTag\t$promoterBegin\t$promoterScore\t$promoterSequence\t$i\t$geneStart\t$geneDirection\t$checkTSS\tTSS found\t$tssData\n";
			}
		else
			{
			print OUTFILE "$locusTag\t$promoterBegin\t$promoterScore\t$promoterSequence\t$i\t$geneStart\t$geneDirection\t$checkTSS\tNothing found\n";
			};
		};
	}
elsif ($geneDirection eq "-")
	{
	my $possibleTSS = $geneStart - $promoterBegin - 35;
	for (my $i = 3; $i > -1; $i--)
		{
		my $checkTSS = $possibleTSS - $i;
		if (defined ${$tssReference}{$checkTSS})
			{
			my $tssData = ${$tssReference}{$checkTSS};
			print OUTFILE "$locusTag\t$promoterBegin\t$promoterScore\t$promoterSequence\t$i\t$geneStart\t$geneDirection\t$checkTSS\tTSS found\t$tssData\n";
			}
		else
			{
			print OUTFILE "$locusTag\t$promoterBegin\t$promoterScore\t$promoterSequence\t$i\t$geneStart\t$geneDirection\t$checkTSS\tTSS not found\n";
			};
		};
	}
else 
	{
	print "Unknown gene direction = $geneDirection\n";
	};
}
	

sub getGeneInfo 
{
my ($locusTag) = @_;
my $getPositionStatement = "SELECT Position.strand, Position.begin, Position.end 
FROM Position 
JOIN Locus ON Position.posId = Locus.posId
JOIN Synonym USING (locusId,version) 
WHERE (Synonym.type = 1 OR  Synonym.type = 4)
AND Locus.priority = 1
AND name = '$locusTag' 
ORDER BY version DESC";
my @locusData = $db_handler_mo->selectrow_array($getPositionStatement);
my $geneStart;
if ($locusData[0] eq "+")
	{
	$geneStart = $locusData[1];
	}
else
	{
	$geneStart = $locusData[2];
	}
return ($geneStart, $locusData[0]);
}
