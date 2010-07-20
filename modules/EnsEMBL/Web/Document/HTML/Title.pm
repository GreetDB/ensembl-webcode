package EnsEMBL::Web::Document::HTML::Title;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Document::HTML);

sub new { return shift->SUPER::new( 'title' => 'Untitled document' ); }
sub set { $_[0]{'title'} = $_[1]; }
sub get { return $_[0]{'title'}; }

sub render {
  my $self  = shift;
  my $title = $self->get;
  $title =~ s/<[^>]+>//g;
  $title = encode_entities($title);
  $self->print("\n<title>$title</title>");
}
1;

