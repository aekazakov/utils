#! /usr/bin/perl

###############################################
###    Get locus ids by 2 domain ids        ###
###############################################


#Modules
use warnings;
use strict;
use DBI;
use DBD::mysql;

#Variables
my $dbDomainsFileName = "hthclan_short.txt";
my $sensingDomainsFileName = "sensingDomainsFinalList.txt";
my @dbDomainsList = ();
my @sensingDomainsList = ();
#MicrobesOnline database
my $host_mo = "pub.microbesonline.org";
my $database_mo = "genomics";
my $user_mo = "guest";
my $pw_mo = "guest";

my $db_handler_mo = DBI->connect("DBI:mysql:database=$database_mo;host=$host_mo", $user_mo, $pw_mo) or die "Unable to connect to $database_mo database!";
my $moStatement = $db_handler_mo->prepare("SELECT DISTINCT Locus2Domain.locusId FROM Locus2Domain
WHERE Locus2Domain.domainId = ? 
AND Locus2Domain.locusId IN 
	(
	SELECT DISTINCT Locus.locusId FROM Locus2Domain
	JOIN Locus ON Locus.locusId = Locus2Domain.locusId 
	JOIN Synonym ON Locus.locusId = Synonym.locusId 
	WHERE Locus.priority=1 
	AND Locus2Domain.domainId = ? 
	AND Synonym.type=1)");

open (DBDOMAINFILE, "<$dbDomainsFileName");
while (<DBDOMAINFILE>) {
	my $domainItem = $_;
	chomp $domainItem;
	push (@dbDomainsList, $domainItem);
};
close DBDOMAINFILE;

open (SENSDOMAINFILE, "<$sensingDomainsFileName");
while (<SENSDOMAINFILE>) {
	my $domainItem = $_;
	chomp $domainItem;
	push (@sensingDomainsList, $domainItem);
};
close SENSDOMAINFILE;

foreach my $dbDomainId (@dbDomainsList) {
	my $outfilename = "hthclan-$dbDomainId-searchResults.txt";
	open (OUTFILE, ">$outfilename");
	print OUTFILE "DNA binding domain\tSensing domain\tLocus ID\n";
	foreach my $sensingDomainId (@sensingDomainsList) {
		my @searchResults;
#used for test purposes:
#my $dbDomainId = "PF00455";
#my $sensingDomainId = "PF08220";
		$moStatement->execute($sensingDomainId, $dbDomainId) or print OUTFILE "Couldn't execute statement: " . $moStatement->errstr;
		if ($moStatement->rows == 0) {
			print OUTFILE "$dbDomainId\t$sensingDomainId\tProteins not found\n";
		}
		else {
			while (@searchResults = $moStatement->fetchrow_array()) {
				my $locusId = $searchResults[0];
				print OUTFILE "$dbDomainId\t$sensingDomainId\t$locusId\n";
			};
		};
		$moStatement->finish;
	};
	close OUTFILE;
};

$db_handler_mo->disconnect;
exit;




