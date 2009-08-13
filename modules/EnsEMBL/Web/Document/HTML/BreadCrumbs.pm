package EnsEMBL::Web::Document::HTML::BreadCrumbs;
use strict;
use EnsEMBL::Web::Document::HTML;
use EnsEMBL::Web::RegObj;

### Package to generate breadcrumb links (currently incorporated into masthead)
### Limited to three levels in order to keep masthead neat :)

our @ISA = qw(EnsEMBL::Web::Document::HTML);

sub render   {
  my $species_defs = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $you_are_here = $ENV{'SCRIPT_NAME'};
  my $html = '<span class="print_hide">';

  ## Link to home page
  if ($you_are_here eq '/index.html') {
    $html .= qq(<strong>Home</strong>);
  }
  else {
    $html .= qq(<a href="/">Home</a>);
  }
  $html .= '</span>';

  ## Species/static content links
  my $species = $ENV{'ENSEMBL_SPECIES'};

  if ($species && $species !~ /multi/i) {
    $html .= '<span class="print_hide"> &gt; </span>';
    if ($species eq 'common') {
      $html .= qq(<strong>Control Panel</strong>);
    }
    else {
      if ($species_defs->SPP_ARE_GROUPED) {
        $html .= '<a href="/'.$species_defs->GROUP_URL.'/">'.$species_defs->DISPLAY_NAME.'</a> &gt; ';
      }
      my $species_name = $species_defs->get_config($species, 'SPECIES_COMMON_NAME');
      if ($species_name =~ /\./) {
        $species_name = '<i>'.$species_name.'</i>'
      }
      if ($ENV{'ENSEMBL_TYPE'} eq 'Info') {
        $html .= qq(<strong>$species_name</strong>);
      }
      else {
        $html .= qq(<a href="/$species/Info/Index">).$species_name.qq(</a>);
      }
      $html .= ' <span style="font-size:75%">['.$species_defs->ASSEMBLY_DISPLAY_NAME.']</span>';
    }
  }
  elsif ($you_are_here =~ m#^/info/#) {

    $html .= '<span class="print_hide"> &gt; </span>';
    ## Level 2 link
    if ($you_are_here eq '/info/' || $you_are_here eq '/info/index.html') {
      $html .= qq(<strong>Help &amp; Documentation</strong>);
    }
    else {
      $html .= qq(<strong><a href="/info/">Help &amp; Documentation</a></strong>);
    }

  }
  $_[0]->printf($html);
}

1;

