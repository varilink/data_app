package SiteFunk::MailForm ;

=head1 SiteFunk::MailForm

Application that provides a general purpose mail form run mode EVENTUALLY.
For the moment we have a separate run_mode for each occurrence of a mail form.

=cut

use strict ;

use base qw / SiteFunk::Action / ;

sub cgiapp_init {

   my $self = shift ;

   $self -> run_modes ( [

      'join_data' ,
		'add_event'

   ] ) ;

}

sub join_data {

=head2 join_data

Submit a mail form enquring about membership for a society.

=cut

   my $self = shift ;

   my $query = $self -> query ( ) ;

   my $form = sub {

      use SiteFunk::Auth::Constraints qw /
         credentials_match
      / ;

      return {

			use Data::FormValidator::Constraints qw /
				email
				FV_eq_with
			/ ;

			optional => [ qw /
				telephone
			/ ] ,

         required => [ qw /
				first_name
				surname
				email
				confirm_email
				society
				message
         / ] ,

         constraint_methods => {

				email => {
					constraint_method => email ,
					name => 'email_valid'
				} ,

				confirm_email => {
					constraint_method => FV_eq_with ( 'email' ) ,
					name => 'email_confirmed'
				} ,

         } ,


         msgs => {

            constraints => {
               'email_valid' => 'Auth_001' ,
					'email_confirmed' => 'Auth_002' ,
            }

         }

      } ; # End of return statement

   } ; # End of login_form sub

   my $results = $self -> check_rm (
      'form_response' ,
      &$login_form ,
      { fill_password => 0 } ,
   ) || return \$self -> check_rm_error_page ;



   $self -> header_add (
		-Content-Length => '' ,
		-Location => $query -> param ( 'onSuccess' ) ,
		-Status => 302
	) ;

   return $self -> redirect ( $query -> param ( 'onSuccess' ) ) ;

}

1 ;

__END__
