package Microbesonline;

=pod

=head1 NAME

Regprecise - PERL module for MicrobesOnline database access

=head1 SYNOPSIS

  my $object = Microbesonline->new(
      hostname  => 'pub.microbesonline.org',
      database => 'genomics',
      port => 3306,
      login => 'guest',
      password => 'guest',
  );
  
  $object->dummy;

=head1 DESCRIPTION

Module for access to MicrobesOnline database.

=head1 METHODS

=cut

use 5.010;
use strict;
use warnings;
use DBI;
use DBD::mysql;
use Carp;

our $VERSION = '0.02';

=pod

=head2 new

  my $object = new Microbesonline;

The C<new> constructor lets you create a new B<Microbesonline> object.

So no big surprises there...

Returns a new B<Microbesonline> or dies on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}


=pod

=head2 connect

	$object->connect();
	
Set up connection to MicrobesOnline MySQL database
Parameters: none
Returns: none

=cut


sub connect {
	my $self = shift;
	#MicrobesOnline database access parameters
	my $moHostname = "pub.microbesonline.org";
	my $moDatabase = "genomics";
	my $moUsername = "guest";
	my $moPassword = "guest";
	my $connectionHandler = DBI->connect("DBI:mysql:database=$moDatabase;host=$moHostname", $moUsername, $moPassword) or die "Unable to connect to $moDatabase database!";
	$self->{connection} = $connectionHandler;
	return 1;
}

=pod

=head2 disconnect

	$object->disconnect();
	
Disconnect from Microbesonline MySQL database
Parameters: none
Returns: none

=cut

sub disconnect {
	my $self = shift;
	if ($self->{connection}){
		($self->{connection})->disconnect;
	};
	return 1;
}

=pod

=head2 getGenesOfGenome

	@geneList = $object->getGenesOfGenome(genomeName);

Select all genes from a given genome
Parameters: genome name
Returns: array of MO IDs

=cut

sub getGenesOfGenome {
	my $self = shift;
	my $genomeName = shift;
	my $selectStatement = "SELECT Locus.locusId FROM Locus JOIN LocusType ON Locus.type = LocusType.type
	JOIN Scaffold ON Locus.scaffoldId = Scaffold.scaffoldId JOIN Taxonomy ON Scaffold.taxonomyId = Taxonomy.taxonomyId
	WHERE Taxonomy.name LIKE \"$genomeName\"
	AND Locus.priority=1 AND LocusType.description=\"Protein-coding gene\"";
	my $result = ($self->{connection})->selectcol_arrayref($selectStatement) || die "Can not execute statement \" $selectStatement\"\n";
	return @$result;
}

=pod

=head2 getGeneCoordinates

	(geneBegin, geneEnd, geneStrand) = $object->getGeneCoordinates(moId);

Retrieves start, end positions and strand of a gene
Parameters: MicrobesOnline ID of a gene
Returns: list containing geneBegin, geneEnd, geneStrand

=cut


sub getGeneCoordinates {
	my $self = shift;
	my $moId = shift;
	my $selectStatement = "SELECT Position.begin, Position.end, Position.strand FROM Position 
	JOIN Locus ON Position.posId = Locus.posId
	WHERE Locus.LocusId = $moId
	AND Locus.priority = 1";
	my $result = ($self->{connection})->selectall_arrayref($selectStatement) ;#or print "Unable to get data from MicrobesOnline for $moId \n";
	my $row = $$result[0];
	if (defined ($row)) {
		my @coords = @$row;
		return @coords;
	}
	else {
		print "No data for gene $moId\n";
		};
	return 0;
};	

=pod

=head2 getGeneScaffold

	scaffoldId = $object->getGeneCoordinates(moId);

Retrieves scaffold Id of a gene
Parameters: MicrobesOnline ID of a gene
Returns: scaffoldId

=cut

sub getGeneScaffold {
	my $self = shift;
	my $moId = shift;
	my $selectStatement = "SELECT Locus.scaffoldId FROM Locus WHERE Locus.locusId = $moId AND Locus.priority=1";
	my ($scaffoldId) = ($self->{connection})->selectrow_array($selectStatement) or print "Unable to get data from MicrobesOnline for $moId \n";
	return $scaffoldId;
}


=pod

=head2 getUpstreamRegion

	($upstreamSequence, $scaffoldId, $moGeneStrand, $upstreamBegin, $upstreamEnd) = $object->getUpstreamRegion(moId, upstreamLength);

Retrieves upstream region of a gene
Parameters: MicrobesOnline ID of a gene, length of upstream region
Returns: upstream sequence, scaffold ID, strand, upstream start position, upstream end position

=cut

sub getUpstreamRegion {
	my $self = shift;
	my ($moId, $upstreamPosition, $upstreamLength) = @_;
	my ($moGeneBegin, $moGeneEnd, $moGeneStrand) = $self->getGeneCoordinates($moId);
	if (defined ($moGeneBegin) && defined ($moGeneEnd) && defined ($moGeneStrand)){
		my $scaffoldId = $self->getGeneScaffold($moId);
		my $upstreamBegin;
		my $upstreamEnd;
		my $upstreamSequence = "";
		if ($moGeneStrand eq "+") {
			$upstreamBegin = $moGeneBegin + $upstreamPosition;
			$upstreamEnd = $upstreamBegin + $upstreamLength;
			my $sqlQuery = "SELECT SUBSTRING(ScaffoldSeq.sequence, $upstreamBegin, $upstreamLength) FROM ScaffoldSeq WHERE ScaffoldSeq.scaffoldId =  $scaffoldId";
			($upstreamSequence) = ($self->{connection})->selectrow_array($sqlQuery) or print "Unable to get data from MicrobesOnline for $moId \n";
		}
		elsif ($moGeneStrand eq "-") {
			$upstreamEnd = $moGeneEnd - $upstreamPosition + 1;
			$upstreamBegin = $upstreamEnd - $upstreamLength;

			my $sqlQuery = "SELECT SUBSTRING(ScaffoldSeq.sequence, $upstreamBegin, $upstreamLength) FROM ScaffoldSeq WHERE ScaffoldSeq.scaffoldId =  $scaffoldId";
			($upstreamSequence) = ($self->{connection})->selectrow_array($sqlQuery) or print "Unable to get data from MicrobesOnline for $moId \n";
			$upstreamSequence = reverseComplement($upstreamSequence);
		}
		return ($upstreamSequence, $scaffoldId, $moGeneStrand, $upstreamBegin, $upstreamEnd);
	}
	else {
		return 0;
	};
}

=pod

=head2 getLocusTag

	$locusTag = $object->getLocusTag(moId);

Retrieves locus tag of a gene
Parameters: MicrobesOnline ID of a gene
Returns: locus tag

=cut

sub getLocusTag {
	my $self = shift;
	my $moId = shift;
	my $sqlQuery = "SELECT Synonym.name FROM Synonym JOIN SynonymType ON Synonym.type=SynonymType.type
	WHERE SynonymType.description IN (\'NCBI locus tag\', \'alternative locus tag\') AND Synonym.locusId = $moId";
	my ($locustag) = ($self->{connection})->selectrow_array($sqlQuery) or print "Unable to get data from MicrobesOnline for $moId \n"; 
	if (!defined($locustag)){
		$locustag = "";
	}
	return $locustag;
};	

=pod

=head2 getGenomeName

	$genomeName = $object->getGenomeName(moId);

Retrieves name of genome
Parameters: MicrobesOnline ID of a gene
Returns: name of genome

=cut

sub getGenomeName {
	my $self = shift;
	my $moId = shift;
	my $sqlQuery = "SELECT Taxonomy.name FROM Taxonomy JOIN Scaffold ON Scaffold.taxonomyId = Taxonomy.taxonomyId JOIN Locus ON Locus.scaffoldId = Scaffold.scaffoldId WHERE Locus.locusId = $moId";
	my ($genomeName) = ($self->{connection})->selectrow_array($sqlQuery) or print "Unable to get data from MicrobesOnline for $moId \n"; 
	if (!defined($genomeName)){
		$genomeName = "EMPTY NAME";
	}
	return $genomeName;
};	

=pod

=head2 getGenomeNameById

	$genomeName = $object->getGenomeNameById(taxId);

Retrieves name of genome by taxonomy ID
Parameters: taxonomy ID
Returns: name of genome

=cut

sub getGenomeNameById {
	my $self = shift;
	my $taxId = shift;
	my $sqlQuery = "SELECT TaxName.name FROM TaxName WHERE TaxName.class = 'scientific name' AND TaxName.taxonomyId = $taxId";
	my ($genomeName) = ($self->{connection})->selectrow_array($sqlQuery) or print "Unable to get data from MicrobesOnline for $taxId \n"; 
	if (!defined($genomeName)){
		$genomeName = "EMPTY NAME";
	}
	return $genomeName;
};	

=pod

=head2 getTaxonomyParent

	$genomeName = $object->getTaxonomyParent(taxId);

Retrieves taxonomy ID of parent taxon by taxonomy ID
Parameters: taxonomy ID
Returns: taxonomy ID of parent taxon

=cut

sub getTaxonomyParent {
	my $self = shift;
	my $taxId = shift;
	my $sqlQuery = "SELECT TaxNode.parentId FROM TaxNode WHERE TaxNode.taxonomyId = $taxId";
	my ($parentId) = ($self->{connection})->selectrow_array($sqlQuery) or print "Unable to get data from MicrobesOnline for $taxId \n"; 
	if (!defined($parentId)){
		$parentId = "UNDEFINED";
	}
	return $parentId;
};	

=pod

=head2 getTaxonomyLineage

	$genomeName = $object->getTaxonomyLineage(taxId);

Retrieves taxonomical lineage taxonomy ID
Parameters: taxonomy ID
Returns: string with all parent taxa

=cut

sub getTaxonomyLineage {
	my $self = shift;
	my $taxId = shift;
	my $lineage="";
	my $parentId = "";
	while (($parentId ne "1")&&($parentId ne "UNDEFINED")){
		$parentId = $self->getTaxonomyParent($taxId);
		my $parentName = $self->getGenomeNameById($parentId);
		$taxId = $parentId;
		$lineage = $parentName."\;".$lineage;
	};
	return $lineage;
};	

sub reverseComplement {
#	my $self = shift;
	my $sequence = shift;
	$sequence = reverse $sequence;
	$sequence =~ tr/ACGTacgt/TGCAtgca/;
	return $sequence;
}