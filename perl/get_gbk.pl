use LWP::Simple;
use strict;

my $label = "taoR";
my $work_dir = "../PFAM_taoR/";
my $infile = $work_dir.$label."_GI_longlist.txt";
my $outfile = $work_dir.$label."_prot_report.txt";
my $listfile = $work_dir."prot_list.txt";
my $genomelistfile = $work_dir."genome_list.txt";
my $errorfile = $work_dir."error_log.txt";
my $genomes_dir = $work_dir."gbk";

if (($genomes_dir ne "")&&(!(-e $genomes_dir))) {
	print "Directory $genomes_dir does not exist!\n";
	exit(1);
}
my @genome_seq_list = ();


my $base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
my $db_prot = 'protein';
my $db_tax = 'taxonomy';
my $db_nucl = 'nuccore';
my $header = "Protein GI\tTaxonomy ID\tTaxonomy name\tNucleotide GI\n";
my @known_prot_ids = ();

open (ERRFILE, ">>$errorfile");
print ERRORFILE "\n-------\nError log started \n\n";

open (LISTFILE, "$listfile");
while (my $line = <LISTFILE>) {
	chomp $line;
	if (!($line eq "")) {
		my @ids = split /\t/, $line;
		push @known_prot_ids,$ids[0];
		push @genome_seq_list,$ids[3];
		#print $ids[3]."\n";
		#print $line."\n";
	}
}
close LISTFILE;

open (LISTFILE, "$genomelistfile");
while (my $line = <LISTFILE>) {
	chomp $line;
	push @genome_seq_list,$line;
	print $line."\n";
}
close LISTFILE;


#print OUTFILE $header;


#get protein GI
my @prot_ids = ();
open (INFILE, "$infile");
while (my $line = <INFILE>) {
	chomp $line;	
	if (!($line eq "")) {
		if (!($line ~~ @known_prot_ids)){
			push @prot_ids,$line;
		}
		
		
	}
}
close INFILE;

open (OUTFILE, ">>$outfile");

#print @prot_ids;
foreach my $protein_id (@prot_ids){
	#open (OUTFILE, ">>$outfile");
	my $output_line = $protein_id."\t";
	#print OUTFILE $protein_id."\t";
	print $protein_id."\n";

#get taxonomy id
	my $url = $base . "elink.fcgi?dbfrom=$db_prot&db=$db_tax&id=$protein_id";
	#print $url."\n";
	my $data = get($url);
	#print $data;
	$data =~ s/\n//g;
	my $tax_id = $1 if ($data =~ /<LinkName>protein_taxonomy<\/LinkName>(.+)<\/LinkSetDb>/);
	$tax_id = $1 if ($tax_id =~ /<Id>(\d+)<\/Id>/);
	#print $tax_id."\n";
	$output_line .= $tax_id."\t";
	#print OUTFILE $tax_id."\t";
	
#get organism name	
	$url = $base . "efetch.fcgi?db=$db_tax&id=$tax_id";
	#print $url."\n";
	$data = get($url);
	#print $data;
	$data =~ s/\n//g;
	my $tax_name = $1 if ($data =~ /<ScientificName>(.+?)<\/ScientificName>/);
	print $tax_name."\n";
	$output_line .= $tax_name."\t";
	#print OUTFILE $tax_name."\t";
	
#get nucleotide sequence GI list
	$url = $base . "elink.fcgi?dbfrom=$db_prot&db=$db_nucl&id=$protein_id";
	#print $url."\n";
	$data = get($url);
	#print $data;
	$data =~ s/\n//g;
	my $nucl_id = $1 if ($data =~ /<LinkName>protein_nuccore<\/LinkName>(.+?)<\/LinkSetDb>/);
	my @matches = ( $nucl_id =~ /<Id>(\d+)<\/Id>/g );
#	$nucl_id = $1 if ($nucl_id =~ /<Id>(\d+)<\/Id>/);
	if (@matches == ()) {#try find in protein_nuccore_wp if no data found in nuccore
		$nucl_id = $1 if ($data =~ /<LinkName>protein_nuccore_wp<\/LinkName>(.+?)<\/LinkSetDb>/);
		@matches = ( $nucl_id =~ /<Id>(\d+)<\/Id>/g );
	}

	if (@matches == ()) {
		print ERRFILE "Nucleotide sequence not found for ".$protein_id."\n";
		print ERRFILE $data."\n\n";
	}
	for (my $i = 0; $i < @matches; $i++) {
		if ($matches[$i] ne "") {
			print OUTFILE $output_line .$matches[$i]."\t";
		#get taxonomy id for nucleotide sequence
			$url = $base . "elink.fcgi?dbfrom=$db_nucl&db=$db_tax&id=$matches[$i]";
			$data = get($url);
			$data =~ s/\n//g;
			my $tax_id2 = $1 if ($data =~ /<LinkName>nuccore_taxonomy<\/LinkName>(.+)<\/LinkSetDb>/);
			$tax_id2 = $1 if ($tax_id2 =~ /<Id>(\d+)<\/Id>/);
			print "\t".$tax_id2."\n";
			print OUTFILE $tax_id2."\t";
	
		#get organism name for nucleotide sequence
			$url = $base . "efetch.fcgi?db=$db_tax&id=$tax_id2";
			$data = get($url);
			$data =~ s/\n//g;
			my $tax_name2 = $1 if ($data =~ /<ScientificName>(.+?)<\/ScientificName>/);
			print OUTFILE $tax_name2."\n";

		#get genome sequence

			if ($matches[$i] ~~ @genome_seq_list) {
				print "Nucleotide sequence $matches[$i] already exists\n";
			} else{
				my $seqfile = $genomes_dir."/".$matches[$i].".gb";
				print "\t\tDownloading ".$matches[$i]."...\n";
				$url = $base . "efetch.fcgi?db=$db_nucl&id=$matches[$i]&rettype=gbwithparts&retmode=text";
				my $nucl_data = get($url);
				open (SEQFILE, ">$seqfile");
				print SEQFILE $nucl_data;
				close SEQFILE;
				print " Done.\n";
				$seqfile ="";
				push @genome_seq_list, $matches[$i];
			}
		$tax_name2 = "";
		$tax_id2="";
		} 		
	}
	
	$tax_name="";
	$tax_id="";
}

close OUTFILE;

print ERRORFILE "\n\n-------\nError log finished\n";
close ERRFILE;

exit(0);
