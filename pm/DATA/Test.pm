package DATA::Test ;

=head1 DATA::Test

=cut

use strict ;
use base qw / DATA::Main / ;

sub setup {

  my $self = shift ;

  $self -> run_modes ( {

    'test' => 'test'

  } ) ;

}

sub test {

  my $self = shift ;

  my $query = $self -> query ;

  print STDERR "\n\n\nI have got in to the test routing\n\n\n" ;

  use Data::Dumper ;
  print STDERR Dumper $query ;

}

1 ;

__END__
