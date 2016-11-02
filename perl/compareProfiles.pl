#! /usr/bin/perl

###############################################
###    Generate profile comparison table    ###
###############################################


#Modules
use warnings;
use strict;

#Variables
#RegPrecise database
my $familyName = "CodY";
my $infileName = "tomtomResults.txt";
my $outfileName = $familyName."table.html";
my $line = "";
open (INFILE, "<$infileName");

my @entriesList = ();
my @regulogList = ();

#populate array of arrays
while (<INFILE>) {
	$line = $_;
	chomp $line;
	my @singleEntry = ();
	if ($line !~ /Query ID/) {
		@singleEntry = split(/\t/, $line);  
		push @entriesList, [ @singleEntry ];
		};
	};

close INFILE;


#populate list of regulogs
foreach my $item (@entriesList) {
	my $regulogName = @$item[0];
	my $existsFlag = 0;
	foreach my $regulogItem (@regulogList) {
		if ($regulogName eq $regulogItem) {
			$existsFlag = 1
			};
		};
	if ($existsFlag == 0) {
		push @regulogList, $regulogName;
		};
	};

foreach my $item (@entriesList) {
	my $regulogName = @$item[1];
	my $existsFlag = 0;
	foreach my $regulogItem (@regulogList) {
		if ($regulogName eq $regulogItem) {
			$existsFlag = 1
			};
		};
	if ($existsFlag == 0) {
		push @regulogList, $regulogName;
		};
	};

open (OUTFILE, ">$outfileName");
print OUTFILE "<html>\n<head>\n";
print OUTFILE "<link rel=\"stylesheet\" href=\"../style.css\">\n";
print OUTFILE "</head>\n<body>\n";
print OUTFILE "<table border = \"1\" class=\"table1\">\n";
print OUTFILE "\t<tr><td></td>\n";


foreach my $regulog0 (@regulogList) {
	my $regulogId = $regulog0;
	$regulogId =~ s/^.+\_//;
	print OUTFILE "<td><a href=\"http://regprecise.lbl.gov/RegPrecise/project.jsp\?project_id=$regulogId\">$regulogId</td>\n";
	};
print OUTFILE "\t</tr>\n";


#build table with: q-values ( @$singleEntry[5] ) or e-values ( @$singleEntry[4] ) 
foreach my $regulog1 (@regulogList) {
	my $regulogId = $regulog1;
	$regulogId =~ s/^.+\_//;
	print OUTFILE "\t<tr><td><a href=\"http://regprecise.lbl.gov/RegPrecise/project.jsp\?project_id=$regulogId\">$regulog1</td>\n\t\t";
	foreach my $regulog2 (@regulogList) {
		my $valueFoundFlag = 0;
		foreach my $singleEntry (@entriesList) {
			if ((@$singleEntry[0] eq $regulog1) && (@$singleEntry[1] eq $regulog2)) {
				my $qValue = sprintf ("%.4f", @$singleEntry[5]);
				if ($qValue <= 0.001) {
					print OUTFILE "<td bgcolor = \"red\">$qValue</td>";
					}
				elsif ($qValue <= 0.01) {
					print OUTFILE "<td bgcolor = \"orange\">$qValue</td>";
					} 
				elsif ($qValue <= 0.1) {
					print OUTFILE "<td bgcolor = \"yellow\">$qValue</td>";
					} 
				else {
					print OUTFILE "<td>$qValue</td>";
					}; 
				$valueFoundFlag = 1;
				last;
				};
			};
		if ($valueFoundFlag == 0) {
			print OUTFILE "<td bgcolor = \"grey\">N/A</td>";
			};
		};
	print OUTFILE "\n\t</tr>\n";
	};

print OUTFILE "</table>\n";
print OUTFILE "</body>\n</html>";
close OUTFILE;

exit;

#######################
##### SUBROUTINES #####
#######################
