#! /usr/bin/perl

##################################
##### Get promoter sequences #####
##################################

#Modules
use warnings;
use strict;
use DBI;
use DBD::mysql;

#Variables
my $tssFileName = "transcription_starts.tab";
my $outFileName = "transcription_starts_50.fasta";
my $seqIndexer = 1;
my $line = "";
#MicrobesOnline database
my $host_mo = "pub.microbesonline.org";
my $database_mo = "genomics";
my $user_mo = "guest";
my $pw_mo = "guest";

my $db_handler_mo = DBI->connect("DBI:mysql:database=$database_mo;host=$host_mo", $user_mo, $pw_mo) or die "Unable to connect to $database_mo database!";

open (INFILE, "<", $tssFileName) or die;
open (OUTFILE, ">$outFileName") or die;
while ($line = <INFILE>) 
	{
	chomp $line;
	if ($line =~ m/^scaffoldId/)
		{
		#do nothing
		}
	elsif ($line eq "")
		{
		#do nothing
		} 
	else
		{
		my @entry = split ("\t", $line);
		if ($entry[22] > -1)
			{
			my $sequence = getSequenceMO ($entry[0], $entry[1], $entry[2]);
			print OUTFILE ">$seqIndexer\n";
			print OUTFILE "$sequence\n";
			$seqIndexer++;
			};
		}
	};
	
$db_handler_mo->disconnect;
close INFILE;
close OUTFILE;
exit;

#######################
##### SUBROUTINES #####
#######################


sub getSequenceMO {
my ($scaffoldId, $tssPosition, $strand) = @_;
my $sequence = "";

if ($strand eq "+") 
	{
	my $get_sequence_statement = "SELECT SUBSTRING(ScaffoldSeq.sequence, $tssPosition-50, 50) FROM ScaffoldSeq WHERE ScaffoldSeq.scaffoldId = $scaffoldId";
	($sequence) = $db_handler_mo->selectrow_array($get_sequence_statement);
	}
elsif ($strand eq "-")
	{
	my $get_sequence_statement = "SELECT SUBSTRING(ScaffoldSeq.sequence, $tssPosition+50, 50) FROM ScaffoldSeq WHERE ScaffoldSeq.scaffoldId = $scaffoldId";
	($sequence) = $db_handler_mo->selectrow_array($get_sequence_statement);
	$sequence = ReverseComplement ($sequence);
	}
else 
	{
	print "Unknown strand $strand";
	};
return $sequence;
};

sub ReverseComplement {
my ($sequence) = @_;
my @bases = split(//,$sequence);
foreach my $base (@bases) {
	if ($base eq "A") {$base = "T"}
	elsif ($base eq "C") {$base = "G"}
	elsif ($base eq "G") {$base = "C"}
	elsif ($base eq "T") {$base = "A"};
	}; 
my @reverseBases  = reverse(@bases);
my $rcSequence = "";
foreach (@reverseBases) {
	$rcSequence = $rcSequence.$_;
	};
return ($rcSequence); 
}