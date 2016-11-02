#! /usr/bin/perl

###############################################
###    Get domain names from MO             ###
###############################################


#Modules
use warnings;
use strict;
use DBI;
use DBD::mysql;

#Variables
my $dbDomainsFile = "sensingDomains-mo.txt";
my $outfilename = "sensingDomainsNames.txt";
#MicrobesOnline database
my $host_mo = "pub.microbesonline.org";
my $database_mo = "genomics";
my $user_mo = "guest";
my $pw_mo = "guest";
my $select_statement_mo = "SELECT DomainInfo.iprName FROM DomainInfo WHERE DomainInfo.domainId = '";

my $db_handler_mo = DBI->connect("DBI:mysql:database=$database_mo;host=$host_mo", $user_mo, $pw_mo) or die "Unable to connect to $database_mo database!";

open (DOMAINFILE, "<$dbDomainsFile");
open (OUTFILE, ">$outfilename");

while (<DOMAINFILE>)
	{
		my $domainId = $_;
		chomp $domainId;
		my $request = "$select_statement_mo$domainId'";
		my $domainData = $db_handler_mo->selectcol_arrayref($request);
		foreach my $domainName (@$domainData) 
			{
			if (defined $domainName) 
				{
				print OUTFILE "$domainId\t$domainName\n";
				}
			else 
				{
					print OUTFILE "$domainId\tName not found\n";
				};
			};
		
	};

close DOMAINFILE;
close OUTFILE;
exit;




