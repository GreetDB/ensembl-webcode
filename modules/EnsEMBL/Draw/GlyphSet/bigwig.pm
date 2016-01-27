=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Draw::GlyphSet::bigwig;

### Module for drawing data in BigWIG format (either user-attached, or
### internally configured via an ini file or database record

use strict;

use parent qw(EnsEMBL::Draw::GlyphSet::UserData);

sub can_json { return 1; }

sub init {
  my $self = shift;
  my @roles = ('EnsEMBL::Draw::Role::BigWig', 'EnsEMBL::Draw::Role::Wiggle');
  Role::Tiny->apply_roles_to_object($self, @roles);
}


sub render_text {
  my ($self, $wiggle) = @_;
  warn 'No text render implemented for bigwig';
  return '';
}

1;
