use LWP::Simple;

my $label = "taoR";
my $work_dir = "../PFAM_taoR/";
my $infile = $work_dir.$label."_GI_longlist.txt";
my $outfile = $work_dir.$label."_prot_ncbi_download.fasta";

$db = 'protein';
$base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
$counter = 0;
$id_list="";
open (INFILE, $infile);

while ($line = <INFILE>) {
	$counter++;
	chomp $line;
	$id_list .= $line;
#	if ($counter == 5) {
		$url = $base . "epost.fcgi?db=$db&id=$id_list";
		$output = get($url);
		$web = $1 if ($output =~ /<WebEnv>(\S+)<\/WebEnv>/);
		$key = $1 if ($output =~ /<QueryKey>(\d+)<\/QueryKey>/);
		$url = $base . "efetch.fcgi?db=$db&query_key=$key&WebEnv=$web";
		$url .= "&rettype=fasta&retmode=text";
		$data = get($url);
		open (OUTFILE, ">>$outfile");
		print OUTFILE $data."\n";
		close OUTFILE;
		$id_list = "";
		$counter = 0;
#	} else {
#		$id_list .= ",";
#	}
	
};

close INFILE;


