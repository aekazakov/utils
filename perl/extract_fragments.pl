use LWP::Simple;
use strict;
use warnings;

my $infile = "intervals.csv";
my $outfile = "outfile.fasta";
my $genomefile = "P_stutzeri_RCH2.gb";

open (INFILE, $infile);
open (GENOMEFILE, $genomefile);
open (OUTFILE, ">$outfile");

my $line;
my $flag = 0;
my @sequence = ();
#read sequence
my $sequence_length = 0;
while ($line = <GENOMEFILE>) {
	chomp $line;
	if ($line =~ /^ORIGIN/) {
		$flag = 1;
	} elsif ($line =~ /^\/\//) {
		$flag = 0;
	} elsif ($flag) {
		if ($line ne ""){
			$line =~ s/(\d+)//g;
			$line =~ s/\s//g;
			push(@sequence, $line);
			$sequence_length += length($line);
		}
	} else {};
};
close GENOMEFILE;

print $sequence_length." ";
print $sequence[0];
print scalar @sequence;
print "\n\n\n";

while ($line = <INFILE>) {
#	print $line;
	chomp $line;
	my @coords = split /\,/, $line;
	if ($coords[0] < $coords[1]) {
		if (($sequence_length > $coords[0])&&($sequence_length > $coords[1])){
			print OUTFILE ">".$coords[0]."..".$coords[1]."\n";
			my $start = $coords[0];
			my $end = $coords[1];
			my $length = $coords[1] - $coords[0] + 1;
			
			my $start_remainder = $start % 60;
			my $start_index = ($start-$start_remainder) / 60;
			my $end_remainder = $end % 60;
			my $end_index = ($end-$end_remainder) / 60;

#			print "length = $length \n";
#			print "start_remainder = $start_remainder \n";
#			print "start_index = $start_index \n";
#			print "end_remainder = $end_remainder \n";
#			print "end_index = $end_index \n";
			
			if ($start_index == $end_index) {
				my $seq = substr ($sequence[$start_index], $start_remainder-1, $length);
				print OUTFILE $seq;
			} else {
				my $seq = substr ($sequence[$start_index], $start_remainder-1);
				print OUTFILE $seq."\n";
				for (my $i = $start_index + 1; $i < $end_index; $i++){
					$seq = $sequence[$i];
					print OUTFILE $seq;
					print OUTFILE "\n";
				}
				$seq = substr ($sequence[$end_index], 0, $end_remainder);
				print OUTFILE $seq;
			}
			print OUTFILE "\n\n";
		} else {
			print "Interval $line is out of limit ($sequence_length) \n";
		}
	} else {
		print "Zero or negative interval in line $line \n";
	}
};

close OUTFILE;
close INFILE;


