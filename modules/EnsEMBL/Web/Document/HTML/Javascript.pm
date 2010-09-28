# $Id$

package EnsEMBL::Web::Document::HTML::Javascript;

use strict;

use base qw(EnsEMBL::Web::Document::HTML);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new('scripts' => '', 'sources' => {});
  return $self;
}

sub add_source { 
  my ($self, $src) = @_;
  
  return unless $src;
  return if $self->{'sources'}{$src};
  
  $self->{'sources'}{$src} = 1;
  $self->{'scripts'} .= qq{ <script type="text/javascript" src="$src"></script>\n};
}

sub add_script {
  return unless $_[1];
  $_[0]->{'scripts'} .= qq{  <script type="text/javascript">\n$_[1]</script>\n};
}

sub _content { return $_[0]->{'scripts'}; }

sub init {
  my ($self, $controller) = @_;
  
  return unless $controller->request eq 'ssi';
  
  my $head = $controller->content =~ /<head>(.*?)<\/head>/sm ? $1 : '';
  
  while ($head =~ s/<script(.*?)>(.*?)<\/script>//sm) {
    my ($attr, $cont) = ($1, $2);
    
    next unless $attr =~ /text\/javascript/;
    
    if ($attr =~ /src="(.*?)"/) {
      $self->add_source($1);
    } else {
      $self->add_script($cont);
    }   
  }
}

1;
