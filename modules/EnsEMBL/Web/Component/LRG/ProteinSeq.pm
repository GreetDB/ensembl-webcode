=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::LRG::ProteinSeq;

use strict;

use base qw(EnsEMBL::Web::Component::Transcript::ProteinSeq);

sub _init {
  my $self = shift;
  $self->object($self->get_transcript); # Become like a transcript
  return $self->SUPER::_init;
}

sub object {
  my $self = shift;
  $self->{'object'} = shift if @_;
  return $self->{'object'};
}

sub get_transcript {
	my $self        = shift;
	my $param       = $self->hub->param('lrgt');
	my $transcripts = $self->builder->object->get_all_transcripts;
  return $param ? grep $_->stable_id eq $param, @$transcripts : $transcripts->[0];
}

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $translation = $object->translation_object;
  return ($translation ? sprintf '<h2>Protein ID: %s</h2><h3>(Transcript ID: %s)</h3>', $translation->Obj->display_id, $object->Obj->external_name : '') . $self->SUPER::content;
}

1;
