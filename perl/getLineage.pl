#! /usr/bin/perl

###############################################
###     Access MicrobesOnline database      ###
###############################################


#Modules
use warnings;
use strict;
use My::Microbesonline;

open (STDERR, ">&STDOUT");

my $infileName = "ModE-taxIds-COG.csv";
my $outfileName = "ModE-genomes-COG.csv";

my $host_mo = "pub.microbesonline.org";
my $database_mo = "genomics";
my $port_mo = "3306";
my $user_mo = "guest";
my $pw_mo = "guest";

my $microbesonline = new Microbesonline;
$microbesonline->connect($host_mo,$database_mo,$port_mo,$user_mo,$pw_mo);

my $line = "";
open (INFILE, "<$infileName");
my @entriesList = ();

while (<INFILE>) {
	$line = $_;
	chomp $line;
	if ($line ne "taxonomyId") {
		push @entriesList, $line;
		};
	};

close INFILE;

my @outList = ();

foreach my $entry (@entriesList) {
	my $name = $microbesonline->getGenomeNameById($entry);
	my $lineage = $microbesonline->getTaxonomyLineage($entry);
	print $entry.",".$name.",".$lineage."\n";
	push @outList, $entry.",".$name.",".$lineage;
	};


$microbesonline->disconnect;

open (OUTFILE, ">$outfileName");
print OUTFILE "taxId,name,lineage\n";
foreach my $entry0 (@outList) {
	print OUTFILE "$entry0\n";
	};

close OUTFILE;

exit;

