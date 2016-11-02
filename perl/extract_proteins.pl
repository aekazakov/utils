use LWP::Simple;
use strict;

my $infile = "gbk_list.txt";
my $outfile = "proteins.aa";
my $errorfile = "error_log.txt";
my $genomes_dir = "genomes";

if (($genomes_dir ne "")&&(!(-e $genomes_dir))) {
	print "Directory $genomes_dir does not exist!\n";
	exit(1);
}
my @genome_seq_list = ();

open (ERRFILE, ">>$errorfile");
print ERRORFILE "\n-------\nError log started \n\n";

open (LISTFILE, "$infile");
while (my $line = <LISTFILE>) {
	chomp $line;
	push @genome_seq_list,$line;
	#print $line."\n";
}
close LISTFILE;

my $seqfile = "";

open (OUTFILE, ">>$outfile");

foreach my $genome_gi (@genome_seq_list){
	$seqfile = $genomes_dir."/".$genome_gi;
	my $flag = 0;
	my $accession = "";
	my $translation = "";
	my $gi = "";
	my $gene_id = "";
	if (-e $seqfile) {
		open (SEQFILE, "$seqfile");
		my $organism = "";
		while (my $line = <SEQFILE>) {
			if ($line =~ /^                    \/organism=\"/) {
				chomp $line;
				$organism = $line;
				chop $organism;
				$organism =~ s/^                    \/organism=\"//g;
			} elsif ($line =~ /^     CDS             /) {
				$flag = 1;
				chomp $line;
				$line =~ s/^            //g;
				print OUTFILE ">".$accession."|".$gi."|".$genome_gi."\t".$line."\n";
				$flag = 2;
				last;
			}
		}
		if (!$flag) {
			print ERRORFILE $genome_gi."\tORGANISM NOT FOUND\n";
		}
		close SEQFILE;
	} else {
		print ERRORFILE $genome_gi."\tFILE NOT FOUND\n";
	}
}


close OUTFILE;

print ERRORFILE "\n\n-------\nError log finished\n";
close ERRFILE;

exit(0);
