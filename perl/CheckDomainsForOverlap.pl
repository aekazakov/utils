#! /usr/bin/perl

###############################################
###  Check results for overlapping entries  ###
###############################################


#Modules
use warnings;
use strict;
use DBI;
use DBD::mysql;

#Variables
my $resultsFileName = "HTH_FullResultsList.csv";
my $outfilename = "hth_nonOverlappingDomainHits.txt";
#MicrobesOnline database
my $host_mo = "pub.microbesonline.org";
my $database_mo = "genomics";
my $user_mo = "guest";
my $pw_mo = "guest";
my $select_statement_mo = "SELECT DomainInfo.iprName FROM DomainInfo WHERE DomainInfo.domainId = '";

my $db_handler_mo = DBI->connect("DBI:mysql:database=$database_mo;host=$host_mo", $user_mo, $pw_mo) or die "Unable to connect to $database_mo database!";
my $moStatement = $db_handler_mo->prepare("SELECT Locus2Domain.domainId, Locus2Domain.seqBegin, Locus2Domain.seqEnd FROM Locus2Domain
WHERE Locus2Domain.locusId = ?
AND Locus2Domain.domainId IN (?, ?)");

open (INFILE, "<$resultsFileName");
open (OUTFILE, ">$outfilename");

while (<INFILE>)
	{
		my $line = $_;
		chomp $line;
		my ($firstDomain, $secondDomain, $locusId) = split(/\t/, $line);
		$moStatement->execute($locusId, $firstDomain, $secondDomain) or print OUTFILE "Couldn't execute statement: " . $moStatement->errstr;
		my $multipleHits = 0;
		if ($moStatement->rows != 2) {
			$multipleHits = 1;
		};
		my ($firstDomainBegin, $firstDomainEnd, $secondDomainBegin, $secondDomainEnd) ;
		while (my @searchResults = $moStatement->fetchrow_array()) {
			if ($firstDomain eq $searchResults[0]) {
				$firstDomainBegin = $searchResults[1];
				$firstDomainEnd = $searchResults[2];
			}
			elsif ($secondDomain eq $searchResults[0]) {
				$secondDomainBegin = $searchResults[1];
				$secondDomainEnd = $searchResults[2];
			};
		};
		if (($firstDomainBegin < $secondDomainBegin) && ($firstDomainEnd < $secondDomainBegin)) {
			if ($multipleHits == 0) {
				print OUTFILE "$line\tverified\n";
			}
			else {
				print OUTFILE "$line\tunverified\n";
			};
		}
		elsif (($firstDomainBegin > $secondDomainEnd) && ($firstDomainEnd > $secondDomainEnd)) {
			if ($multipleHits == 0) {
				print OUTFILE "$line\tverified\n";
			}
			else {
				print OUTFILE "$line\tunverified\n";
			};
		};
	};

close INFILE;
close OUTFILE;
exit;

