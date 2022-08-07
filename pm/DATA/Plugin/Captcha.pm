package DATA::Plugin::Captcha ;

=head1 DATA::Plugin::Captcha

CGI:Application integration with Google's reCAPTCHA.

=cut

use strict ;
use warnings ;

use base qw / Exporter / ;

sub verify {

=head2 verify

Verify's a user's reCAPTCHA response.

=cut

   my $self = shift ;

   my $query = $self -> query ;

   my $captcha = $query -> param ( 'g-recaptcha-response' ) ;

   # HTTP client
   use LWP::UserAgent ;

   my $user_agent = new LWP::UserAgent (

      # Ensure valid certificate
      ssl_opts => { verify_hostname => 1 }

   ) ;

   my $response = $user_agent -> post (

      'https://www.google.com/recaptcha/api/siteverify' ,

      {
         # See:
         # https://github.com/varilink/data-app/issues/15
         secret => '6LcreBcTAAAAAGX1e7pY8Hv6ayKJbshxW_JoZ3rn' ,
         response => $captcha ,
      } ,

   ) ;

   my $json_text = $response -> content ;

}

sub import {

   my $caller = scalar caller ;

   $caller -> add_callback (

       # Again, see:
       # https://github.com/varilink/data-app/issues/15
       # Specifically the comment about how this import does not appear to be
       # using the correct method name.
      'init' , \&_init

   ) ;

   goto &Exporter::import ;

}

1 ;

__END__
