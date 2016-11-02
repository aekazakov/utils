use LWP::Simple;
use strict; 

my $gi_file = "../GB_taoR/GI_shortlist.txt";
my $blast_file = "../GB_taoR/DVU3193_blast_output.txt";

my $label_1 = "taoR";

my $outfile = "../GB_taoR/".$label_1."_GI_longlist.txt";

my $errorfile = "genes_errorlog.txt";


open (ERRORFILE, ">>$errorfile");
print ERRORFILE "\n-------\nError log started \n\n";

my %gis = ();

open (INFILE, "$gi_file");
while (my $line = <INFILE>) {
	chomp $line;
	if ($line ne "") {
		$gis{$line}="";
	}
}
close INFILE;

my $alignment_flag = 0;
my $entry_flag = 0;

open (OUTFILE, ">$outfile");

open (INFILE, "$blast_file");
while (my $line = <INFILE>) {
	chomp $line;
	if ($line eq "") {
		#do nothing on empty lines
	} elsif ($alignment_flag) {
		if ($line =~ /^>gi\|/) {
			my $gi = $1 if ($line =~ /^>gi\|(\d+)\|/);
			if (exists $gis{ $gi }) {
				print OUTFILE $gi."\n";
				$entry_flag = 1;
			} #else {print "not found\n";}
		} elsif (($line =~ /^ gi\|/)&&($entry_flag)) {
			print $line."\n";
			my $gi = $1 if ($line =~ /^ gi\|(\d+)\|/);
			print $gi."\n";
			print OUTFILE $gi."\n";
		} elsif ($line =~ /^Length=/) {
			$entry_flag = 0;
		} elsif ($line eq "  Database: All non-redundant GenBank CDS translations+PDB+SwissProt+PIR+PRF") {
			$alignment_flag = 0;
		}
	} elsif ($line =~ /^ALIGNMENTS$/) {
		print "Start working\n";
		$alignment_flag = 1;
	} elsif ($line =~ /^  Database: All non-redundant GenBank CDS translations+PDB+SwissProt+PIR+PRF/) {
		$alignment_flag = 0;
	}
}
close INFILE;
close OUTFILE;


exit;



#######################
##### SUBROUTINES #####
#######################

