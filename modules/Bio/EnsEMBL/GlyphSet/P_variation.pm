package Bio::EnsEMBL::GlyphSet::P_variation;

use strict;

use base qw(Bio::EnsEMBL::GlyphSet);

sub my_colour {
  my ($self, $key) = @_;
  $self->{'colour_map'} ||= $self->{'config'}->species_defs->colour('variation');
  return map $self->{'colour_map'}->{lc $key}->{$_}, qw(default text);
}

sub _init {
  my $self = shift;
  
  return $self->render_text if $self->{'text_export'};
  
  my $config     = $self->{'config'};
  my $snps       = $self->cache('image_snps');
  my $h          = $self->my_config('height') || 4; 
  my $pix_per_bp = $self->scalex;
  my $t_width    = $h * 0.75 / $pix_per_bp;
  
  $self->_init_bump(undef,  $self->my_config('depth') || 1e6);

  return unless $snps;
  
  foreach my $snp (@$snps) {
    my $x = $snp->{'position'};
    my ($colour, $legend) = $self->my_colour($snp->{'type'});
    
    if ($snp->{'indel'}) {
      my ($y, $end, $direction) = $snp->{'indel'} eq 'insert' ? ($h, 1, 'down') : (0, $snp->{'length'} - 1, 'up');
      my $pos    = $x . ($end ? '-' . ($x + $end) : '');
      my $type   = ucfirst $snp->{'indel'};
      
      my ($glyph, $zmenu) = $self->Triangle({
        x         => $x - $t_width,
        y         => 0,
        width     => $t_width * 2,
        height    => $h,
        direction => $direction,
        mid_point => [ $x, $y ],
        colour    => $colour,
        absolutey => 1,
        href      => $self->_url({
          type   => 'Variation',
          action => 'VariationProtein',
          v      => $snp->{'snp_id'},
          vf     => $snp->{'vdbid'},
          vtype  => $type,
          pos    => $pos,
          len    => $snp->{'length'},
          indel  => $snp->{'allele'}
        })
      });
      
      my $bump_start = int($glyph->x * $pix_per_bp);
      my $bump_end   = $bump_start + $glyph->width + 3;
      my $row        = $self->bump_row($bump_start, $bump_end);
      
      $_->transform({ translatey => 1.5 * $row * ($h + 2) }) for $glyph, $zmenu;
      
      $self->push($glyph, $zmenu);
      
      # Force to the end of the legend
      $config->{'P_variation_legend'}{"zz$type"} ||= {
        text  => $type,
        shape => 'Triangle'
      };
    } else {
      my $glyph = $self->Rect({
        x             => $x - $h / 2,
        y             => 0,
        width         => $h,
        height        => $h,
        colour        => $colour,
        absolutey     => 1,
        absolutewidth => 1,
        href          => $self->_url({
          type   => 'Variation',
          action => 'VariationProtein',
          v      => $snp->{'snp_id'},
          vf     => $snp->{'vdbid'},
          res    => $x,
          cod    => $snp->{'ambigcode'} ? join('', map { $_ == $snp->{'codon_var_pos'} ? "[$snp->{'ambigcode'}]" : $snp->{'codon_seq'}->[$_] } 0..2) : '',
          ar     => $snp->{'pep_snp'},
          al     => $snp->{'allele'}
        })
      });
      
      my $bump_start = int($glyph->x * $pix_per_bp);
      my $bump_end   = $bump_start + $glyph->width + 3;
      my $row        = $self->bump_row($bump_start, $bump_end);
      
      $glyph->y($glyph->y + 1.5 * $row * ($h + 2));
      $self->push($glyph);
      
      $config->{'P_variation_legend'}{$legend} ||= {
        text   => $legend,
        colour => $colour,
        shape  => 'Rect'
      };
    }
  }
}

sub render_text {
  my $self = shift;
  
  my $container = $self->{'container'};
  my $snps = $self->cache('image_snps');

  return unless $snps;

  my $export;

  foreach my $snp (@$snps) {
    my $codon = $snp->{'ambigcode'} ? join '', map { $_ == $snp->{'codon_var_pos'} ? "[$snp->{'ambigcode'}]" : $snp->{'codon_seq'}->[$_] } 0..2 : '';
    my $class;
    
    if ($snp->{'indel'}) {
      $class = $snp->{'indel'};
    } else {
      $class = $snp->{'type'} eq 'SYNONYMOUS_CODING' ? 'syn' : 'snp';
    }
    
    $export .= $self->_render_text($container, 'Variation', { 
      headers => [ 'variation_name', 'alleles', 'class', 'type', 'alternative_residues', 'codon' ],
      values  => [ $snp->{'snp_id'}, $snp->{'allele'}, $class, $snp->{'type'}, $snp->{'pep_snp'}, $codon ]
    }, { 
      start  => $snp->{'position'},
      end    => $snp->{'position'} + $snp->{'length'},
      source => $snp->{'snp_source'}
    });
  }
  
  return $export;
}

1;
