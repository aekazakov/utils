use LWP::Simple;
use strict;

my $infile = "PF12727_proteins_organisms.txt";
my $outfile = "PF12727_tree_organisms.nexml";
my $errorfile = "error_log.txt";
my $treefile = "PF12727_full_tree.nexml";

my %protlist = ();

open (ERRORFILE, ">>$errorfile");
print ERRORFILE "\n-------\nError log started \n\n";

open (LISTFILE, "$infile");
while (my $line = <LISTFILE>) {
	chomp $line;
	my @ids = split /\t/, $line;
	$protlist{$ids[0]} = $ids[1];
#	print $line."\n";
}
close LISTFILE;

open (TREEFILE, "$treefile");
open (OUTFILE, ">$outfile");

while (my $line = <TREEFILE>) {
	chomp $line;
	if ($line =~ /<node id=/) {
		my $protein = $1 if ($line =~ /label=\"(.+)_/);
		my $organism = 0;
		$organism = $protlist{$protein};
		if ($organism) {
			$line =~ s/\"\/>/ $organism\"\/>/;
		} else {
			print ERRORFILE "Protein $protein not found\n";
		}
#		print $line."\n";
	}
	print OUTFILE $line;
	print OUTFILE "\n";
}
close OUTFILE;
close TREEFILE;

print ERRORFILE "\n\n-------\nError log finished\n";
close ERRORFILE;

exit(0);
