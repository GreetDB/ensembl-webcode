package EnsEMBL::Web::ImageConfig::reg_summary;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;
  
  $self->set_parameters({
    'title'         => 'Feature context',
    'show_buttons'  => 'no',
    'show_labels'   => 'yes',
    'label_width'   => 113,
    'opt_lines'     => 1,
    'margin'        => 5,
    'spacing'       => 2,
  });  

  $self->create_menus(
    'sequence'        => 'Sequence',
    'transcript'      => 'Genes',
    'prediction'      => 'Prediction transcripts',
    'dna_align_rna'   => 'RNA alignments',
    'oligo'           => 'Probe features',
    'simple'          => 'Simple features',
    'misc_feature'    => 'Misc. regions',
    'repeat'          => 'Repeats',
    'functional'      => 'Functional Genomics', 
    'variation'       => 'Variation',
    'other'           => 'Decorations',
    'information'     => 'Information', 
  );

  $self->add_tracks( 'other',
    [ 'scalebar',  '',            'scalebar',        { 'display' => 'normal',  'strand' => 'b', 'name' => 'Scale bar'  } ],
    [ 'ruler',     '',            'ruler',           { 'display' => 'normal',  'strand' => 'b', 'name' => 'Ruler'      } ],
  );
  $self->add_tracks( 'sequence',
    [ 'contig',    'Contigs',              'stranded_contig', { 'display' => 'normal',  'strand' => 'r'  } ],
  );

  $self->load_tracks;
  $self->load_configured_das;

  $self->modify_configs(
    [qw(functional)],
    {qw(display normal)}
  );
  $self->modify_configs(
    [qw(ctcf_funcgen_Nessie_NG_STD_2)],
    {qw(display tiling)}
  );
  $self->modify_configs(
    [qw(ctcf_funcgen_blocks_Nessie_NG_STD_2)],
    {qw(display compact)}
  );
  $self->modify_configs(
    [qw(histone_modifications_funcgen)],
    {qw(display tiling)}
  );
  $self->modify_configs(
    [qw(transcript_core_ensembl)],
    {qw(display transcript_nolabel)}
  );

}
1;
