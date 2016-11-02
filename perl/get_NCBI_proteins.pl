use LWP::Simple;

# Download protein records corresponding to a list of GI numbers.

#$db = 'protein';
#$id_list = '916491140';

#assemble the epost URL
$base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
#$url = $base . "epost.fcgi?db=$db&id=$id_list";

#post the epost URL
#$output = get($url);

#parse WebEnv and QueryKey
#$web = $1 if ($output =~ /<WebEnv>(\S+)<\/WebEnv>/);
#$key = $1 if ($output =~ /<QueryKey>(\d+)<\/QueryKey>/);

### include this code for EPost-ESummary
#assemble the esummary URL
#$url = $base . "esummary.fcgi?db=$db&query_key=$key&WebEnv=$web";

#post the esummary URL
#$docsums = get($url);
#print "$docsums";

### include this code for EPost-EFetch
#assemble the efetch URL
#$url = $base . "efetch.fcgi?db=$db&query_key=$key&WebEnv=$web";
#$url .= "&rettype=fasta&retmode=text";

#post the efetch URL
#$data = get($url);
#print "$data";

$db = 'protein';
$dbnew = 'nuccore';#'taxonomy';
$id_list = '491489936';

$url = $base . "elink.fcgi?dbfrom=$db&db=$dbnew&id=$id_list";
print $url."\n";
$data = get($url);
#print $data;
$data =~ s/\n//g;
$nucl_id = $1 if ($data =~ /<LinkName>protein_nuccore<\/LinkName>(.+?)<\/LinkSetDb>/);
#print "Nucl data\n"."$nucl_data";
#$nucl_id = $1 if ($nucl_id =~ /<Id>(\d+)<\/Id>/);
my @matches = ( $nucl_id =~ /<Id>(\d+)<\/Id>/g );
print "\n"."$nucl_id";
for ($i = 0; $i < @matches; $i++) {
	$url = $base . "efetch.fcgi?db=$dbnew&id=$matches[$i]&rettype=gbwithparts&retmode=text";
	print $url."\n";
}
#$url = $base . "efetch.fcgi?db=$dbnew&id=$nucl_id&rettype=gbwithparts&retmode=text";

#$nucl_data = get($url);
$nucl_id = $1 if ($nucl_id =~ /<Id>(\d+)<\/Id>/);
$outfile = "test_sequence.gb";
#open (OUTFILE, ">$outfile");
#print OUTFILE $nucl_data;
#close OUTFILE;
