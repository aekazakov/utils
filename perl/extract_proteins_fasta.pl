use LWP::Simple;
use strict;

my $outfile = "proteins.fasta";
my $errorfile = "error_log.txt";
my $genomes_dir = "gbk";

if (($genomes_dir ne "")&&(!(-e $genomes_dir))) {
	print "Directory $genomes_dir does not exist!\n";
	exit(1);
}


open (ERRFILE, ">>$errorfile");
print ERRORFILE "\n-------\nError log started \n\n";


opendir (DIR,"$genomes_dir");
print my $file = readdir(DIR) ."\n";

open (OUTFILE, ">$outfile");

while (defined (my $file = readdir(DIR)))
{
	open (INFILE, "$genomes_dir\\$file");
	my $flag = 0;
	my $cds_flag = 0;
	my $translation_flag = 0;
	my $source = "";
	my $locus_tag = "";
	my $protein_id = "";
	my $translation = "";
	while (my $line = <INFILE>) {
		chomp $line;
		#print $line."\n";
		if ($line =~ /^SOURCE      /) {
			$line =~ s/^SOURCE      //g;
			$source = $line;
		} elsif ($line =~ /^FEATURES             Location\/Qualifiers/){
			$flag = 1;
		} elsif ($flag) {
			if ($line =~ /^                     \/organism=\"/) {
				$line =~ s/^                     \/organism=\"//g;
				chop $line;
				$source = $line;
			} elsif ($line =~ /^     CDS /) {
				$cds_flag = 1;
			} elsif ($line =~ /^     \w+/) {
				if ($cds_flag && ($translation ne "")) {
					$cds_flag = 0;
					print OUTFILE ">".$protein_id."|".$locus_tag."|".$source."\n".$translation."\n\n";
					$locus_tag = "";
					$protein_id = "";
					$translation = "";
				}
			} elsif ($cds_flag) {
				if ($line =~ /^                     \/locus_tag=\"/){
					$line =~ s/^                     \/locus_tag="//g;
					chop $line;
					$locus_tag = $line;
				} elsif ($line =~ /^                     \/protein_id=\"/){
					$line =~ s/^                     \/protein_id=\"//g;
					chop $line;
					$protein_id = $line;
				} elsif ($line =~ /^                     \/translation=\"/){
					$translation_flag = 1;
					$line =~ s/^                     \/translation=\"//g;
					chop $line;
					$translation = $line;
				} elsif ($translation_flag && ($line =~ /\"$/)) {
					$line =~ s/ //g;
					chop $line;
					$translation .= $line;
					$translation_flag = 0;
				} elsif ($translation_flag) {
					$line =~ s/ //g;
					$translation .= $line;
				}
			}
		} elsif ($line =~ /^ORIGIN      /) {
			$flag = 0;
		}
	}
	close INFILE;
}

close OUTFILE;

print ERRORFILE "\n\n-------\nError log finished\n";
close ERRFILE;

exit(0);
