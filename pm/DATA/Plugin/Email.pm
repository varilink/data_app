package DATA::Plugin::Email ;

use strict ;
use warnings ;

use base qw / Exporter / ;

use Email::MIME ;

our @EXPORT = qw / sendmail / ;

sub sendmail {

   my ( $self , $to , $subject , $params ) = @_ ;

  my $original = undef ;

  if ( my $email = $self -> conf -> param ( 'env' ) -> { email } ) {

      # We are debugging, replace "to" if it's been overridden
    if ( $to ne $email ) {
      $original = $to ;
        $to = $email ;
    }

   }

  my $tmpl = $self -> template -> load (
    $self -> get_current_runmode . '_email'
  );

   foreach my $name ( keys %{ $params } ) {

    my $value = $params -> { $name } ;
    $tmpl -> param ( $name => $value ) ;

   }

  $tmpl -> param ( 'original' => $original ) if $original ;

  my $html_part = $tmpl -> output ( part => 'html' ) ;
  my $text_part = $tmpl -> output ( part => 'text' ) ;

   use Email::MIME ;

   my @parts = (
      Email::MIME -> create (
         attributes => {
         content_type => 'text/plain' ,
        charset => 'utf-8' ,
        encoding => 'quoted-printable' ,
      } ,
      body => $text_part ,
    ) ,
    Email::MIME -> create (
      attributes => {
        content_type => 'text/html' ,
        charset => 'utf-8' ,
        encoding => 'quoted-printable' ,
      } ,
      body => $html_part ,
    ) ,
  ) ;

   my $email = Email::MIME -> create (
    header_str => [
      From => 'admin@derbyartsandtheatre.org.uk' ,
      To => $to ,
      Subject => $subject ,
      'Content-Type' => 'multipart/alternative' ,
    ] ,
    parts => [ @parts ] ,
  ) ;

   my $message = $email -> as_string ;

   open ( SENDMAIL ,
    '|/usr/sbin/sendmail -t -f admin@derbyartsandtheatre.org.uk'
  ) or die 'Cannot open sendmail' ;
   print SENDMAIL $message ;
   close SENDMAIL ;

}

sub import {

   goto &Exporter::import ;

}

1 ;

__END__
