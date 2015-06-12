=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Role::Bio::Gene::Homology;

### Compara-specific data-munging for gene pages

use Role::Tiny;

sub get_desc_mapping {
### Returns descriptions for ortholog types.
### TODO - get this info from compara API
  my ($self, $match_type) = @_;
  my %desc_mapping;

  my %orth_mapping = (
      ortholog_one2one          => '1 to 1 orthologue',
      apparent_ortholog_one2one => '1 to 1 orthologue (apparent)',
      ortholog_one2many         => '1 to many orthologue',
      ortholog_many2many        => 'many to many orthologue',
      possible_ortholog         => 'possible orthologue',
  );
  my %para_mapping = (
      within_species_paralog    => 'paralogue (within species)',
      other_paralog             => 'other paralogue (within species)',
      putative_gene_split       => 'putative gene split',
      contiguous_gene_split     => 'contiguous gene split',
  );

  if ($match_type eq 'Orthologue') {
    %desc_mapping = %orth_mapping;
  }
  elsif ($match_type eq 'Paralogue') {
    %desc_mapping = %para_mapping;
  }
  else {
    %desc_mapping = (%orth_mapping, %para_mapping);
  }
  return %desc_mapping;
}

sub get_homology_matches {
  my ($self, $homology_source, $homology_description, $disallowed_homology, $compara_db) = @_;
  #warn ">>> MATCHING $homology_source, $homology_description BUT NOT $disallowed_homology";

  $homology_source      ||= 'ENSEMBL_HOMOLOGUES';
  $homology_description ||= 'ortholog';
  $compara_db           ||= 'compara';

  my $key = $homology_source.'::'.$homology_description;

  if (!$self->{'homology_matches'}{$key}) {
    my $homologues = $self->fetch_homology_species_hash($homology_source, $homology_description, $compara_db);

    return $self->{'homology_matches'}{$key} = {} unless keys %$homologues;

    my $gene         = $self->api_object;
    my $geneid       = $gene->stable_id;
    my $adaptor_call = $self->param('gene_adaptor') || 'get_GeneAdaptor';
    my %homology_list;

    # Convert descriptions into more readable form
    my %desc_mapping = $self->get_desc_mapping;

    foreach my $display_spp (keys %$homologues) {
      my $order = 0;

      foreach my $homology (@{$homologues->{$display_spp}}) {
        my ($homologue, $homology_desc, $species_tree_node, $query_perc_id, $target_perc_id, $dnds_ratio, $gene_tree_node_id, $homology_id) = @$homology;

        next unless $homology_desc =~ /$homology_description/;
        next if $disallowed_homology && $homology_desc =~ /$disallowed_homology/;

        # Avoid displaying duplicated (within-species and other paralogs) entries in the homology table (e!59). Skip the other_paralog (or overwrite it)
        next if $homology_list{$display_spp}{$homologue->stable_id} && $homology_desc eq 'other_paralog';

        $homology_list{$display_spp}{$homologue->stable_id} = {
          homologue           => $homologue,
          homology_desc       => $Bio::EnsEMBL::Compara::Homology::PLAIN_TEXT_WEB_DESCRIPTIONS{$homology_desc} || 'no description',
          description         => $homologue->description       || 'No description',
          display_id          => $homologue->display_label     || 'Novel Ensembl prediction',
          species_tree_node   => $species_tree_node,
          spp                 => $display_spp,
          query_perc_id       => $query_perc_id,
          target_perc_id      => $target_perc_id,
          homology_dnds_ratio => $dnds_ratio,
          gene_tree_node_id   => $gene_tree_node_id,
          dbID                => $homology_id,
          order               => $order,
          location            => sprintf('%s:%s-%s:%s', $homologue->dnafrag()->name, map $homologue->$_, qw(dnafrag_start dnafrag_end dnafrag_strand))
        };

        $order++;
      }
    }

    $self->{'homology_matches'}{$key} = \%homology_list;
  }

  return $self->{'homology_matches'}{$key};
}

sub get_homologies {
  my $self                 = shift;
  my $homology_source      = shift;
  my $homology_description = shift;
  my $compara_db           = shift || 'compara';

  $homology_source      = 'ENSEMBL_HOMOLOGUES' unless defined $homology_source;
  $homology_description = 'ortholog' unless defined $homology_description;

  my $geneid   = $self->stable_id;
  my $database = $self->database($compara_db);
  my %homologues;

  return unless $database;

  my $query_member   = $database->get_GeneMemberAdaptor->fetch_by_stable_id($geneid);

  return unless defined $query_member;

  my $homology_adaptor = $database->get_HomologyAdaptor;
  my $homologies_array = $homology_adaptor->fetch_all_by_Member($query_member); # It is faster to get all the Homologues and discard undesired entries than to do fetch_all_by_Member_method_link_type

  # Strategy: get the root node (this method gets the whole lineage without getting sister nodes)
  # We use right - left indexes to get the order in the hierarchy.

  my %classification = ( Undetermined => 99999999 );

  if (my $taxon = $query_member->taxon) {
    my $node = $taxon->root;

    while ($node) {
      $node->get_tagvalue('scientific name');

      $classification{$node->{_tags}{'scientific name'}} = $node->{'_right_index'} - $node->{'_left_index'};
      $node = $node->children->[0];
    }
  }

  my $ok_homologies = [];
  foreach my $homology (@$homologies_array) {
    push @$ok_homologies, $homology if $homology->description =~ /$homology_description/;
  }
  return ($ok_homologies, \%classification, $query_member);
}

sub fetch_homology_species_hash {
  my $self                 = shift;
  my $homology_source      = shift;
  my $homology_description = shift;
  my $compara_db           = shift || 'compara';
  my ($homologies, $classification, $query_member) = $self->get_homologies($homology_source, $homology_description, $compara_db);
  my %homologues;

  foreach my $homology (@$homologies) {
    my ($query_perc_id, $target_perc_id, $genome_db_name, $target_member, $dnds_ratio);

    foreach my $member (@{$homology->get_all_Members}) {
      my $gene_member = $member->gene_member;

      if ($gene_member->stable_id eq $query_member->stable_id) {
        $query_perc_id = $member->perc_id;
      } else {
        $target_perc_id = $member->perc_id;
        $genome_db_name = $member->genome_db->name;
        $target_member  = $gene_member;
        $dnds_ratio     = $homology->dnds_ratio;
      }
    }

    # FIXME: ucfirst $genome_db_name is a hack to get species names right for the links in the orthologue/paralogue tables.
    # There should be a way of retrieving this name correctly instead.
    push @{$homologues{ucfirst $genome_db_name}}, [ $target_member, $homology->description, $homology->species_tree_node->taxon_id, $query_perc_id, $target_perc_id, $dnds_ratio, $homology->{_gene_tree_node_id}, $homology->dbID ];
  }

  @{$homologues{$_}} = sort { $classification->{$a->[2]} <=> $classification->{$b->[2]} } @{$homologues{$_}} for keys %homologues;

  return \%homologues;
}

sub get_homologue_alignments {
  my $self        = shift;
  my $compara_db  = shift || 'compara';
  my $database    = $self->database($compara_db);
  my $hub         = $self->hub;
  my $msa;

  if ($database) {
    my $member  = $database->get_GeneMemberAdaptor->fetch_by_stable_id($self->api_object->stable_id);
    my $tree    = $database->get_GeneTreeAdaptor->fetch_default_for_Member($member);
    my @params  = ($member, 'ENSEMBL_ORTHOLOGUES');
    my $species = [];
    foreach (grep { /species_/ } $hub->param) {
      (my $sp = $_) =~ s/species_//;
      push @$species, $sp if $hub->param($_) eq 'yes';
    }
    push @params, $species if scalar @$species;
    $msa        = $tree->get_alignment_of_homologues(@params);
    $tree->release_tree;
  }
  return $msa;
}

1;
