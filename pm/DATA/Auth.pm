package DATA::Auth ;

=head1 DATA::Auth

This module implements DATA's user authentication and account mangement
functionality.

=cut


use strict ;
use warnings ;

use base qw / DATA::Main / ;

use DATA::Auth::Constraints ;
use DATA::Auth::User ;

use App::Genpass ;
use Data::FormValidator::Constraints qw / email  / ;
use Data::FormValidator::Constraints::MethodsFactory qw / :bool / ;
use DateTime ;
use String::Random ;

my $_messages = {

  # A hash reference containing messages associated with constraints

  credentials_match    => 'credentials_match'  ,
  email_confirmed      => 'email_confirmed'    ,
  email_free          => 'email_free'          ,
  email_valid          => 'email_valid'        ,
  not_a_robot          => 'not_a_robot'        ,
  password_complex    => 'password_complex'    ,
  password_confirmed  => 'password_confirmed'  ,
  contact_valid       => 'contact_valid'      ,
  user_confirmed      => 'user_confirmed'      ,
  user_not_confirmed  => 'user_not_confirmed'  ,
  user_exists          => 'user_exists'        ,
  userid_long_enough  => 'userid_long_enough'  ,
  userid_unique        => 'userid_unique'      ,
  userid_valid        => 'userid_valid'        ,

} ;

sub _secret {

  # Internal method that is called whenever we want a secret string
  my $string = new String::Random ;
  my $secret = $string -> randregex ( '[a-z0-9]{20}' ) ;
  return $secret ;

}

sub setup {

   my $self = shift ;

   $self -> run_modes ( [

#
# Authentication
#

    # Login using your user credentials
      'login'                                                  ,
    # Logout
      'logout'                                                 ,

#
# Account Creation
#

    # Begin the registration of a user account
      'begin_registration'                                     ,
    # Complete the registration
    'complete_registration'                                  ,
    # Confirm a registration request
    'confirm_registration'                                  ,
    # Confirm the email address associated with a user account
      'confirm_email'                                       ,
    # Resend the confirmation email following user account creation
    'resend_confirmation_email'                              ,

#
# Account Management (Post Creation)
#

    # Get a reminder of your userid via email
      'userid_reminder'                                        ,

    # Request that a link to reset your password is emailed to you
      'request_password_reset'                                ,
    # Show the reset password page
    'show_password_reset_page'                                ,
    # Action a password reset
    'reset_password'                                      ,
    # Request a new, randomly generated password
    'request_password'                                                      ,

    # Run mode for the change of any details associated with a user account
    'update_account'                                      ,
    # Specific run mode for update of a password only, if you want that
      'update_password'                                        ,

   ] ) ;

}

=head2 Authentication

Controls the authentication of a session via login and logout methods.

=cut

sub login {

=head3 login

Process an attempt to authenticate

=cut

  my $self = shift ;
  my $query = $self -> query ;

  my $env = $self -> conf -> param ( 'env' ) ;

  my $login_form = sub {

    if ( $env -> { use_captcha } ) {

      # We are using Google reCAPTCHA in this environment

      return {

        required => [ qw /
          g-recaptcha-response
          user_userid
          user_password
        / ] ,

        constraint_methods => {

          'g-recaptcha-response' => {
            constraint_method => not_a_robot (
              $env -> { recaptcha_secret_key }
            ) ,
            name => 'not_a_robot'
          } ,

          user_userid => [
            {
              constraint_method => user_exists ( $self -> dbh ) ,
              name => 'user_exists'
            } ,
            {
              constraint_method => FV_or (
                FV_not ( user_exists ( $self -> dbh ) ) ,
                user_confirmed ( $self -> dbh )
              ) ,
              name => 'user_confirmed'
            } ,
          ] ,

          user_password => {
            constraint_method => credentials_match (
              $self -> dbh ,
              { fields => [ qw / user_userid / ] }
            ) ,
            name => 'credentials_match'
          } ,

        } ,

        msgs => {

          constraints => $_messages

        }

      } ; # End of return statement

    } else {

      # We are NOT using Google reCAPTCHA in this environment

      return {

        required => [ qw /
          user_userid
          user_password
        / ] ,

        constraint_methods => {

          user_userid => [
            {
              constraint_method => user_exists ( $self -> dbh ) ,
              name => 'user_exists'
            } ,
            {
              constraint_method => FV_or (
                FV_not ( user_exists ( $self -> dbh ) ) ,
                user_confirmed ( $self -> dbh )
              ) ,
              name => 'user_confirmed'
            } ,
          ] ,

          user_password => {
            constraint_method => credentials_match (
              $self -> dbh ,
              { fields => [ qw / user_userid / ] }
            ) ,
            name => 'credentials_match'
          } ,

        } ,

        msgs => {

          constraints => $_messages

        }

      } ; # End of return statement

    }

  } ; # End of login_form sub

   my $results = $self -> check_rm (
      'form_response' ,
      $login_form ,
      { fill_password => 0 } ,
   ) || return \$self -> check_rm_error_page ;

  # We have logged on okay so user must exist. Fetch it for the role.
   my $user = new DATA::Auth::User ;
   $user -> userid ( scalar $query -> param ( 'user_userid' ) ) ;
  $user -> fetch ( $self -> dbh ) ;

   $self -> session_recreate ;
   $self -> session -> param ( 'userid' , $user -> userid ) ;
  $self -> session -> param ( 'role' , $user -> role ) ;
  $self -> session -> flush ;

   # Add a cookie to the outgoing headers containing the session
   $self -> session_cookie ;

   $self -> redirect ( $query -> param ( 'onSuccess' ) ) ;

}

sub logout {

=head3 logout

Unauthenticate a session via a logout method

=cut

   my $self = shift ;

   $self -> session -> clear ( [ 'userid' , 'role' ] ) ;
  $self -> session -> flush ;

   return $self -> redirect ( '/' ) ;

}

=head2 Account Creation

=cut

sub begin_registration {

=head3 begin_registration

The first step of account registration is a test that the email that the account
is to be associated with is valid for an account.

=cut

   my $self = shift ;
   my $query = $self -> query ;
  my $env = $self -> conf -> param ( 'env' ) ;

   my $begin_registration_form = sub {

    if ( $env -> { disable_recaptcha } ) {

        return {

           required => [ qw /
              user_email
              user_confirm_email
           / ] ,

           constraint_methods => {

          user_email => [
            {
              constraint_method => email ,
              name => 'email_valid'
            } ,
            {
              constraint_method => FV_or (
                FV_not ( email ) ,
                FV_not ( email_taken ( $self -> dbh ) ) ) ,
              name => 'email_free'
            } ,
           ] ,

              user_confirm_email => {
            constraint_method => FV_eq_with ( 'user_email' ) ,
            name => 'email_confirmed'
          } ,

           } ,

           msgs => {

              constraints => $_messages

           }

        } ; # End of return

    } else {

        return {

           required => [ qw /
          g-recaptcha-response
              user_email
              user_confirm_email
           / ] ,

           constraint_methods => {

          'g-recaptcha-response' => {
            constraint_method => not_a_robot (
              $env -> { recaptcha_secret_key }
            ) ,
            name => 'not_a_robot'
          } ,

              user_confirm_email => {
            constraint_method => FV_eq_with ( 'user_email' ) ,
            name => 'email_confirmed'
          } ,

          user_email => [
            {
              constraint_method => email ,
              name => 'email_valid'
            } ,
            {
              constraint_method => FV_or (
                FV_not ( email ) ,
                FV_not ( email_taken ( $self -> dbh ) ) ) ,
              name => 'email_free'
            } ,
           ] ,

           } ,

           msgs => {

              constraints => $_messages

           }

        } ; # End of return

    }

   } ; # End of begin_registration_form profile

   my $results = $self -> check_rm (
      'form_response' ,
      $begin_registration_form ,
   ) || return \$self -> check_rm_error_page ;

#
# Test if the user is either a committee member or a known member society
# representative. As we have aleady defined constaints for these tests we use
# those in an explicit call to Data::FormValidator
#

  my $input_hash = { user_email => $query -> param ( 'user_email' ) } ;

  my $dfv_profile = {

    required => [ qw /
      user_email
    / ] ,

    constraint_methods => {

      user_email => {
        constraint_method => FV_or (
          committee_member ( $self -> dbh ) ,
          representative_known ( $self -> dbh )
        )
      }

    }

  } ;

  $results = Data::FormValidator -> check ( $input_hash , $dfv_profile ) ;

  my $return ;

  if ( %{ $results -> valid } ) {

    $return = $query -> param ( 'onSuccess' ) ;

  } else {

    $return = $query -> param ( 'onWarning' ) ;

  }

  $self -> session -> param (
    'tmpl_params' , { user_email => $query -> param ( 'user_email' ) }
  ) ;
  $self -> session -> flush ;
   return $self -> redirect ( $return ) ;

}

sub complete_registration {

=head3 complete_registration

Register a user account. As well as success for failure outcomes there is a
warning outcome for which confirmation to proceed with account registration is
required.

=cut

   my $self = shift ;
   my $query = $self -> query ;
  my $env = $self -> conf -> param ( 'env' ) ;

   my $complete_registration_form = sub {

    if ( 1 ) {

        return {

           required => [ qw /
              user_email
              user_first_name
              user_surname
          user_userid
              user_password
              user_confirm_password
           / ] ,

           constraint_methods => {

          user_email => [
            {
              constraint_method => email ,
              name => 'email_valid'
            } ,
            {
              constraint_method => FV_or (
                FV_not ( email ) ,
                FV_not ( email_taken ( $self -> dbh ) ) ) ,
              name => 'email_free'
            } ,
           ] ,

          user_userid => [
            {
              constraint_method =>  FV_min_length ( 8 ) ,
              name => 'userid_long_enough'
            } ,
            {
              constraint_method => userid_valid
            } ,
            {
              constraint_method =>
                FV_not ( user_exists ( $self -> dbh ) ) ,
              name => 'userid_unique'
            }
          ] ,

          user_password => password_complex ,

              user_confirm_password => {
            constraint_method => FV_eq_with ( 'user_password' ) ,
            name => 'password_confirmed'
          } ,

           } ,

           msgs => {

              constraints => $_messages

           }

        } ; # End of return

    } else {

        return {

           required => [ qw /
          g-captcha_response
              user_email
              user_first_name
              user_surname
          user_userid
              user_password
              user_confirm_password
           / ] ,

           constraint_methods => {

          'g-recaptcha-response' => {
            constraint_method => not_a_robot (
              $env -> { recaptcha_secret_key }
            ) ,
            name => 'not_a_robot'
          } ,

          user_email => [
            {
              constraint_method => email ,
              name => 'email_valid'
            } ,
            {
              constraint_method => FV_or (
                FV_not ( email ) ,
                FV_not ( email_taken ( $self -> dbh ) ) ) ,
              name => 'email_free'
            } ,
           ] ,

          user_userid => [
            {
              constraint_method =>  FV_min_length ( 8 ) ,
              name => 'userid_long_enough'
            } ,
            {
              constraint_method => userid_valid
            } ,
            {
              constraint_method =>
                FV_not ( user_exists ( $self -> dbh ) ) ,
              name => 'userid_unique'
            }
          ] ,

          user_password => password_complex ,

              user_confirm_password => {
            constraint_method => FV_eq_with ( 'user_password' ) ,
            name => 'password_confirmed'
          } ,

           } ,

           msgs => {

              constraints => $_messages

           }

        } ; # End of return

    }

   } ; # End of complete_registration_form profile

   my $results = $self -> check_rm (
      'form_response' ,
      $complete_registration_form ,
   ) || return \$self -> check_rm_error_page ;

  my $user = new DATA::Auth::User ;

   $user -> userid ( scalar $self -> query -> param ( 'user_userid' ) ) ;
   $user -> email ( scalar $self -> query -> param ( 'user_email' ) ) ;
   $user -> first_name ( scalar $self -> query -> param ( 'user_first_name' ) ) ;
   $user -> surname ( scalar $self -> query -> param ( 'user_surname' ) ) ;
   $user -> password ( scalar $self -> query -> param ( 'user_password' ) ) ;
   $user -> status ( 'UNCONFIRMED' ) ; # Posit
   $user -> datetime ( DateTime -> now ) ;

#
# Check where the user is a committee member or a known member society
# representative to determine their role. As we have aleady defined constaints
# for these tests we use those in an explicit call to Data::FormValidator.
#

  # DFV input hash for checking whether the user_email corresponds to a
  # committee member or a known member society representative.
  my $input_hash = { user_email => $query -> param ( 'user_email' ) } ;

  # DFV profile for the same test. We reverse the sense of the constaints so
  # that they return whether the user is a committee member or a known member
  # society representative rather than enforcing them as constraints.
  my $dfv_profile = {

    required => [ qw /
      user_email
    / ] ,

    constraint_methods => {

      user_email => [
        {
          constraint_method =>
            FV_not ( committee_member ( $self -> dbh ) ) ,
          name => 'committee_member'
        } ,
        {
          constraint_method =>
            FV_not ( representative_known ( $self -> dbh ) ) ,
          name => 'representative'
        }
      ]

    }

  } ;

  $results = Data::FormValidator -> check ( $input_hash , $dfv_profile ) ;

  my @roles = ( ) ;
  if ( %{ $results -> invalid } ) {
    @roles = @{ $results -> invalid ( 'user_email' ) } ;
  }

  if ( grep /^committee_member$/ , @roles ) {

    # If they are both a committee member and a known representative then
    # give them admin access as then they can do anything.

    $user -> role ( 'admin' ) ;

  } elsif ( grep /^representative$/ , @roles ) {

    $user -> role ( 'rep' ) ;

  }

  $user -> secret ( &_secret ) ;
   $self -> sendmail (
      $user -> email ,
      'DATA Diary - New Userid Registration' ,
    { user => $user }
   ) ;

   $user -> save ( $self -> dbh ) ;

  $self -> session -> param (
    'tmpl_params' , {
      user => $user ,
      email => { subject => 'DATA Diary - New Userid Registration' }
    }
  ) ;
  $self -> session -> flush ;

   return $self -> redirect ( $query -> param ( 'onSuccess' ) ) ;

}

sub confirm_registration {

=head3 confirm_registration

Confirm a registration when the email address isn't recognised as belonging to
either a member of the DATA committee or a known representative of a DATA member
society.

=cut

   my $self = shift ;
   my $query = $self -> query ;

   my $confirm_registeration_form = sub {

      return {

         required => [ qw /
            user_email
         / ] ,

         constraint_methods => {

        user_email => [
          {
            constraint_method => email ,
            name => 'email_valid'
          } ,
          {
            constraint_method => FV_or (
              FV_not ( email ) ,
              FV_not ( email_taken ( $self -> dbh ) ) ) ,
            name => 'email_free'
          } ,
         ] ,

         } ,

         msgs => {

            constraints => $_messages

         }

      } ;

   } ;

   my $results = $self -> check_rm (
      'form_response'             ,
      $confirm_registeration_form ,
   ) || return \$self -> check_rm_error_page ;

  my $user = new DATA::Auth::User ;

   $user -> email ( scalar $self -> query -> param ( 'user_email' ) ) ;
   $user -> first_name ( scalar $self -> query -> param ( 'user_first_name' ) ) ;

  my $env = $self -> conf -> param ( 'env' ) ;
  my $webmin = $env -> { webmin } ;

   $self -> sendmail (
    $webmin ,
      'DATA Diary - Registration' ,
    { user => $user }
   ) ;

   return $self -> redirect ( $query -> param ( 'onSuccess' ) ) ;

}

sub confirm_email {

=head3 confirm_email

Confirm a registration by clicking on the link in the email sent.

=cut

  my $self = shift ;

  my $query = $self -> query ;

  $query -> param ( 'user_email'  , $self -> param ( 'email'    ) ) ;
  $query -> param ( 'user_secret'  , $self -> param ( 'secret'  ) ) ;
  $query -> param ( 'onSuccess'    , $self -> param ( 'success'  ) ) ;
  $query -> param ( 'onError'    , $self -> param ( 'error'    ) ) ;

  my $confirm_email_profile = {

    required => [ qw /
      user_email
      user_secret
    / ] ,

    constraint_methods => {

      user_email => [
        {
          constraint_method => email_taken ( $self -> dbh ) ,
          name => 'user_exists'
        } ,
        {
          constraint_method => FV_or (
            FV_not ( email_taken ( $self -> dbh ) ) ,
            FV_not ( user_confirmed ( $self -> dbh ) )
          ) ,
          name => 'user_not_confirmed'
        } ,
      ] ,

      user_secret => {
        constraint_method => user_secret_valid ( $self -> dbh ) ,
        name => 'user_secret_valid'
      } ,

    } ,

    msgs => {

      constraints => $_messages

    }

  } ;

   my $results = $self -> check_rm (
      'form_response'             ,
      $confirm_email_profile ,
   ) || return \$self -> check_rm_error_page ;

  my $user = new DATA::Auth::User ;
  $user -> email ( $self -> param ( 'email' ) ) ;
  $user -> fetch ( $self -> dbh ) ;
  $user -> status ( 'CONFIRMED' ) ;
  $user -> secret ( '' ) ;
  $user -> datetime ( '' ) ;
  $user -> save ( $self -> dbh ) ;

  # Called via GET and if the action is repeated you get a sensible response,
  # which is "this user's email is already confirmed" so no need for a
  # redirect.
   my $tmpl = $self -> template -> load ( $query -> param ( 'onSuccess' ) ) ;

   return $tmpl -> output ;

}

sub resend_confirmation_email {

=head3 resend_confirmation_email

=cut

  my $self = shift ;
  my $query = $self -> query ;
  my $dbh = $self -> dbh ;

  sub _resend_confirmation_email {

    my $dbh_in = shift ;

    return {

      required => [ qw /
        user_email
      / ] ,

         constraint_methods => {

        user_email => [
          {
            constraint_method => user_exists ( $dbh_in ) ,
            name => 'user_exists'
          } ,
          {
            constraint_method => FV_or (
              FV_not ( user_exists ( $dbh_in ) ) ,
              FV_not ( user_confirmed ( $dbh_in ) )
            ) ,
            name => 'user_not_confirmed'
          } ,
        ] ,

         } ,

         msgs => {

            constraints => $_messages

         }

    }

  }

   $self -> check_rm (
      'form_response' ,
      &_resend_confirmation_email ( $dbh ) ,
   ) || return \$self -> check_rm_error_page ;

  my $user = new DATA::Auth::User ;
  $user -> email ( scalar $query -> param ( 'user_email' ) ) ;
  $user -> fetch ( $dbh ) ;
  $user -> secret ( &_secret ) ;
  $user -> datetime ( DateTime -> now ) ;
  $user -> save ( $dbh ) ;

   $self -> sendmail (
      $user -> email ,
      'DATA Diary - New Userid Registration' ,
    { user => $user }
   ) ;

   my $tmpl = $self -> template -> load ( $query -> param ( 'onSuccess' ) ) ;

  $tmpl -> param (
    user => $user ,
    email => { subject => 'DATA Diary - New Userid Registration' }
  ) ;

# Need to convert this to a redirect but not sure how to do that and include
# the parameter

   return $tmpl -> output ;

}

sub userid_reminder {

=head3 userid_reminder

Send the user a reminder of their userid

=cut

  my $self = shift ;

  my $query = $self -> query ;

  my $userid_reminder = sub {

      return {

         required => [ qw /
            user_email
         / ] ,

         constraint_methods => {

        user_email => [
          {
            constraint_method => user_exists ( $self -> dbh ) ,
            name => 'user_exists'
          } ,
          {
            constraint_method => FV_or (
              FV_not ( user_exists ( $self -> dbh ) ) ,
              user_confirmed ( $self -> dbh )
            ) ,
            name => 'user_confirmed'
          } ,
        ]

         } ,

         msgs => {

            constraints => $_messages

         }

      } ;

   } ;

   $self -> check_rm (
      'form_response' ,
      $userid_reminder ,
   ) || return \$self -> check_rm_error_page ;

   my $user = new DATA::Auth::User ;

   $user -> email ( scalar $self -> query -> param ( 'user_email' ) ) ;

   if ( $user -> fetch ( $self -> dbh ) ) {

     $self -> sendmail (
        $user -> email ,
      'DATA Diary On-line Userid Reminder' ,
      { user => $user }
     ) ;

  }

   return $self -> redirect ( $query -> param ( 'onSuccess' ) ) ;

}

sub request_password_reset {

=head3 request_password_reset

=cut

  my $self = shift ;

  my $dbh = $self -> dbh ;

  my $request_password_reset_profile = sub {

    return {

      required => [ qw /
        user_userid
      / ] ,

         constraint_methods => {

        user_userid => [
          {
            constraint_method => user_exists ( $self -> dbh ) ,
            name => 'user_exists'
          } ,
          {
            constraint_method => FV_or (
              FV_not ( user_exists ( $self -> dbh ) ) ,
              user_confirmed ( $self -> dbh )
            ) ,
            name => 'user_confirmed'
          } ,
        ] ,

         } ,

      msgs => { constraints => $_messages }

    } ;

  } ;

   $self -> check_rm (
      'form_response' ,
      $request_password_reset_profile
   ) || return \$self -> check_rm_error_page ;

  my $query = $self -> query ;

  my $user = new DATA::Auth::User ;
  $user -> userid ( scalar $query -> param ( 'user_userid' ) ) ;
  $user -> fetch ( $dbh ) ;
  $user -> secret ( &_secret ) ;
  $user -> datetime ( DateTime -> now ) ;
  $user -> save ( $dbh ) ;

  $self -> sendmail (
    $user -> email ,
    'DATA Diary - Password Reset' ,
    { user => $user }
  ) ;

  return $self -> redirect ( $query -> param ( 'onSuccess' ) ) ;

}

sub show_password_reset_page {

  my $self = shift ;
  my $query = $self -> query ;

  # Copy application parameters from the URL to the query object for validateRM
  $query -> param ( 'user_userid' , $self -> param ( 'userid' ) ) ;
  $query -> param ( 'user_secret' , $self -> param ( 'secret' ) ) ;
  $query -> param ( 'onSuccess' , $self -> param ( 'onSuccess' ) ) ;
  $query -> param ( 'onError' , $self -> param ( 'onError' ) ) ;

  my $validation_profile = {

    required => [ qw /
      user_userid
      user_secret
      onSuccess
      onError
    / ] ,

    constraint_methods => {

      user_email => [
        {
          constraint_method => email_taken ( $self -> dbh ) ,
          name => 'user_exists'
        } ,
        {
          constraint_method => FV_or (
            FV_not ( email_taken ( $self -> dbh ) ) ,
            FV_not ( user_confirmed ( $self -> dbh ) )
          ) ,
        } ,
      ] ,

      user_secret => {
        constraint_method => user_secret_valid ( $self -> dbh ) ,
        name => 'user_secret_valid'
      } ,

    } ,

  } ;

   $self -> check_rm (
      'form_response' ,
      $validation_profile
   ) || return \$self -> check_rm_error_page ;

  my $user = new DATA::Auth::User ;
  $user -> userid ( $query -> param ( 'user_userid' ) ) ;
  $user -> fetch ( $self -> dbh ) ;

  # This runmode does not change state, so no need for a redirect
   my $tmpl = $self -> template -> load ( $query -> param ( 'onSuccess' ) ) ;
  $tmpl -> param ( user => $user ) ;

   return $tmpl -> output ;

}

sub reset_password {

  my $self = shift ;
  my $dbh = $self -> dbh ;

  my $validation_profile = {

    required => [ qw /
      user_userid
      user_secret
      user_password
      user_confirm_password
    / ] ,

    constraint_methods => {

      user_userid => [
        {
          constraint_method => user_exists ( $self -> dbh ) ,
          name => 'user_exists'
        } ,
        {
          constraint_method => FV_or (
            FV_not ( user_exists ( $self -> dbh ) ) ,
            user_confirmed ( $self -> dbh )
          ) ,
          name => 'user_confirmed'
        }
      ] ,

      user_secret => {
        constraint_method => user_secret_valid ( $self -> dbh ) ,
        name => 'user_secret_valid'
      } ,

      user_password => password_complex ,

      user_confirm_password => {
        constraint_method => FV_eq_with ( 'user_password' ) ,
        name => 'password_confirmed'
      } ,

    } ,

    msgs => { constraints => $_messages } ,

  } ;

  $self -> check_rm (
    'form_response' ,
    $validation_profile ,
  ) || return \$self -> check_rm_error_page ;

  my $query = $self -> query ;

  my $user = new DATA::Auth::User ;
  $user -> userid ( scalar $query -> param ( 'user_userid' ) ) ;
  $user -> fetch ( $dbh ) ;

  $user -> password ( scalar $self -> query -> param ( 'user_password' ) ) ;
  $user -> secret ( '' ) ;
  $user -> datetime ( '' ) ;

  $user -> save ( $dbh ) ;

  $self -> redirect ( $query -> param ( 'onSuccess' ) ) ;

}




sub request_password {

   my $self = shift ;

   my $query = $self -> query ;

   my $user = new DATA::Auth::User ;

   $user -> userid ( scalar $query -> param ( 'userid' ) ) ;
   $user -> email ( scalar $query -> param ( 'email' ) ) ;

   sub _request_password {

      return {

         required => [ qw /
            userid
            email
         / ] ,

         constraint_methods => {

        email => { constraint_method => email , name => 'email_valid' }

         } ,

         msgs => { constraints => $_messages }

      } ;

   }

   $self -> check_rm (
      'form_response' ,
      &_request_password ,
   ) || return \$self -> check_rm_error_page ;

   my $genpass = App::Genpass -> new ;

   $user -> password ( $genpass -> generate ) ;
   $user -> update_password ( $self -> dbh ) ;

   $self -> sendmail (
      $user -> email ,
      'DATA Diary On-line Password Reset' ,
    {
      user => $user
    }
   ) ;

   return $self -> redirect ( $query -> param ( 'onSuccess' ) ) ;

}

sub update_account {

=head3 update_account

=cut

  my $self = shift ;
  my $query = $self -> query ;

  my $update_account_form = {

    required => [ qw /

      user_first_name
      user_surname
      user_userid
      user_email

    / ] ,

    optional => [ qw /

      user_confirm_email
      user_password
      user_confirm_password

    / ] ,

    dependencies => {

      'user_password' => [ qw / user_confirm_password / ] ,

      'user_email' => sub {

        # If the user_email is changed then user_confirm_email is mandated
        my ( $dfv , $email ) = @_ ;
        my $user = new DATA::Auth::User ;
        # Use the session userid in case user_userid field is also changed
        $user -> userid ( $self -> session -> param ( 'userid' ) ) ;
        $user -> fetch ( $self -> dbh ) ;
        return [ 'user_confirm_email' ] if $email ne $user -> email ( ) ;
        return [ ] ;
      } ,

    } ,

    constraint_methods => {

      user_userid => [

        # Constraints only apply if the user_userid is changed

        {
          constraint_method => FV_or (
            user_userid_unchanged ( $self -> session ) ,
            FV_min_length ( 8 )
          ) ,
          name => 'userid_long_enough'
        } ,
        {
          constraint_method => FV_or (
            user_userid_unchanged ( $self -> session ) ,
            userid_valid
          ),
          name => 'userid_valid'
        } ,
        {
          constraint_method => FV_or (
            user_userid_unchanged ( $self -> session ) ,
            FV_not ( user_exists ( $self -> dbh ) )
          ) ,
          name => 'userid_unique'
        }
      ] ,

      user_email => [

        # Constraints only apply if the user_email is changed

        {
          constraint_method => FV_or (
            user_email_unchanged ( $self -> dbh , $self -> session ) ,
            email
          ) ,
          name => 'email_valid'
        } ,
        {
          constraint_method => FV_or (
            user_email_unchanged ( $self -> dbh , $self -> session ) ,
            FV_not ( email ) ,
            FV_not ( email_taken ( $self -> dbh ) )
          ) ,
          name => 'email_free'
        } ,
      ] ,

      user_confirm_email => {
        constraint_method => FV_eq_with ( 'user_email' ) ,
        name => 'email_confirmed'
      } ,

      user_password => password_complex ,

      user_confirm_password => {
        constraint_method => FV_eq_with ( 'user_password' ) ,
        name => 'password_confirmed'
      } ,

    } ,

    msgs => {

      constraints => $_messages

    } ,

  } ;

   $self -> check_rm (
      'form_response' ,
      $update_account_form ,
   ) || return \$self -> check_rm_error_page ;

  my $user = new DATA::Auth::User ;

  # Use the session userid rather than the userid in the query object. The
  # userid in the query object may represent a change that is yet to be applied
  # to the database.
  $user -> userid ( $self -> session -> param ( 'userid' ) ) ;
  $user -> fetch ( $self -> dbh ) ;

  # The user first name and surname may or may not be changed but it's fine to
  # update the user record with them either way.
  $user -> first_name ( scalar $query -> param ( 'user_first_name' ) ) ;
  $user -> surname ( scalar $query -> param ( 'user_surname' ) ) ;

  my $redirect ;

  if (
    $user -> userid  ne scalar $query -> param ( 'user_userid' )        ||
    $user -> email    ne scalar $query -> param ( 'user_email' )        ||
    scalar $query -> param ( 'user_password' )
  ) {

    print STDERR "We have detected a change affecting authentication\n" ;

    $user -> userid ( scalar $query -> param ( 'user_userid' ) ) ;
    $user -> password ( scalar $query -> param ( 'user_password' ) )
      if $query -> param ( 'user_password' ) ;

    if ( $user -> email ne scalar $query -> param ( 'user_email' ) ) {

      $user -> email ( scalar $query -> param ( 'user_email' ) ) ;

      # Email address has changed so we need to get the user to confirm
      # their new email address.

      $user -> secret ( &_secret ) ;
      $user -> datetime ( DateTime -> now ) ;
      $user -> status ( 'UNCONFIRMED' ) ;

       $self -> sendmail (
          $user -> email ,
          'DATA Diary - Change of Account Email Address' ,
        { user => $user }
       ) ;

    }


     $self -> session -> clear ( [ 'userid' , 'role' ] ); # To log the user off
    $self -> session -> flush ;

    $redirect = scalar $query -> param ( 'onWarning' ) ;

  } else {

    $redirect = scalar $query -> param ( 'onSuccess' ) ;

  }

  $user -> save ( $self -> dbh ) ;

  $self -> redirect ( $redirect ) ;

}

sub update_password {

=head3 update_password

Updates the password of the currently logged on user

=cut

   my $self = shift ;

   my $query = $self -> query ;

   sub _update_password_form {

      return {

         required => [ qw /
            password
            confirm_password
         / ] ,

         msgs => {

            constraints => $_messages

         }

      } ;

   }

   $self -> check_rm (
      'form_response' ,
      &_update_password_form ,
   ) || return \$self -> check_rm_error_page ;

   my $user = new DATA::Auth::User ;

   $user -> userid ( scalar $self -> session -> param ( 'userid' ) ) ;
   $user -> password ( scalar $query -> param ( 'password' ) ) ;

   $user -> update_password ( $self -> dbh ) ;

   return $self -> redirect ( $query -> param ( 'onSuccess' ) ) ;

}

1 ;

__END__
