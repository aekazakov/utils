use LWP::Simple;
use strict;

my $infile = "../GB_taoR/genome_GIs_shortlist.txt";
my $outfile = "../GB_taoR/genome_taxonomy_shortlist.txt";
my $errorfile = "error_log.txt";
my $genomes_dir = "../GB_taoR/gbk";

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
	$seqfile = $genomes_dir."/".$genome_gi.".gb";
	my $flag = 0;
	if (-e $seqfile) {
		open (SEQFILE, "$seqfile");
		while (my $line = <SEQFILE>) {
			if ($line =~ /^  ORGANISM/) {
				$flag = 1;
			} elsif ($flag == 1) {
				chomp $line;
				$line =~ s/^            //g;
				print OUTFILE $genome_gi."\t".$line."\n";
				$flag = 2;
				last;
			}
		}
		if (!$flag) {
			print OUTFILE $genome_gi."\tTAXONOMY NOT FOUND\n";
		}
		close SEQFILE;
	} else {
		print OUTFILE $genome_gi."\tFILE NOT FOUND\n";
	}
}


close OUTFILE;

print ERRORFILE "\n\n-------\nError log finished\n";
close ERRFILE;

exit(0);
