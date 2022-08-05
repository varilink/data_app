package SiteFunk::Auth::Constraints ;

use strict ;
use warnings ;

use base qw / Exporter / ;

use Carp ;
use DateTime ;
use Digest::MD5 qw / md5_hex / ;
use SiteFunk::Auth::User ;

use Data::FormValidator::Constraints qw /
	email
	FV_eq_with
	FV_min_length
/ ;

use Data::FormValidator::Constraints::MethodsFactory qw /
	:bool
/ ;

our @EXPORT = qw /

   credentials_match
	email
	FV_eq_with
	FV_min_length
	FV_and
	FV_not
	not_a_robot
	password_complex
   representative_known
   committee_member
	user_confirmed
	user_email_unchanged
   user_exists
	user_secret_valid
	user_userid_unchanged
	userid_valid
	email_taken

/ ;

sub credentials_match {

=head2 credentials_match

Tests supplied login credentials to see if they match what we have on record.

=cut

   my ( $dbh , $attrs ) = @_ ;
   my ( $userid ) = @ { $attrs -> { fields } } if $attrs -> { fields } ;

   return sub {

      my ( $dfv , $value ) = @_ ;

      my $data = $dfv -> get_filtered_data ( ) ;

		my $user = new SiteFunk::Auth::User ;
		$user -> userid ( $data -> { $userid } ) ;

		my $result = $user -> fetch ( $dbh ) ;
		
		$user -> fetch ( $dbh ) && md5_hex ( $value ) eq $user -> password
			? return 1
			: return 0 ;

   }

}

sub not_a_robot {

	my $recaptcha_secret_key = shift ;

	return sub {

		my ( $dfv , $value ) = @_ ;

		$dfv -> name_this ( 'not_a_robot' ) ;

		use LWP::UserAgent ;

		my $user_agent = new LWP::UserAgent (

			# Ensure valid certificate
			ssl_opts => { verify_hostname => 1 }

		) ;

		my $response = $user_agent -> post (

			'https://www.google.com/recaptcha/api/siteverify' ,

			{
				secret => $recaptcha_secret_key ,
				response => $value ,
			} ,

		) ;

		my $json_text = $response -> content ;

		use JSON ;

		my $json = new JSON ;

		my $perl_scalar = $json -> decode ( $json_text ) ;

		my	$response_code = $perl_scalar -> { success } ;

		return $response_code ;

	}

}

sub password_complex {

	return sub {

		my ( $dfv , $value ) = @_ ;

		$dfv -> name_this ( 'password_complex' ) ;

      use Data::Password::Check ;

      my $check = Data::Password::Check -> check ( {
         'password' => $value ,
         'tests' => [ 'length' , 'alphanumeric_only' , 'alphanumeric' ] ,
			'min_length' => 8 ,
		} ) ;

		$check -> has_errors
			? return undef
			: return 1 ; 

	}

}

sub representative_known {

=head3 representative_known

Validates that a registering user, who claims to represent one or more socities
is actually known to be a representative of those societies.

=cut

   my ( $dbh ) = @_ ;

   return sub {

      my $dfv = shift ;

		my $value = $dfv -> get_current_constraint_value ;

      my $data = $dfv -> get_filtered_data ( ) ;

      use SiteFunk::WhatsOn::Contact ;

      my $contact = new SiteFunk::WhatsOn::Contact ;

      $contact -> email ( $value ) ;
      return $contact -> representative ( $dbh ) ;

   }

}

sub committee_member {

=head3 committee_member

Validates that a registering user is a committee member.

=cut

	my ( $dbh ) = shift ;

	return sub {

		my $dfv = shift ;

		my $value = $dfv -> get_current_constraint_value ;

		my $data = $dfv -> get_filtered_data ( ) ;

		use SiteFunk::WhatsOn::Contact ;

		my $contact = new SiteFunk::WhatsOn::Contact ;

		$contact -> email ( $value ) ;
		return $contact -> committee_member ( $dbh ) ;

	}

}

sub user_confirmed {

=head3 user_confirmed

Tests if a user has been confirmed, by which we mean its email address has been
confirmed by clicking on the confirmation link that we send to the email address
in an email. It uses userid if that's provided or email as an alternative if
userid is not present.

=cut

	my $dbh = shift ;

	return sub {

		my $dfv = shift ;

		my $user = new SiteFunk::Auth::User ;

		my $data = $dfv -> get_filtered_data ;

		my @keys = keys %{ $data } ;

		if ( grep /^user_userid$/ , @keys ) {

			$user -> userid ( $data -> { user_userid } ) ;

		} elsif ( grep /^user_email$/ , @keys ) {

			$user -> email ( $data -> { user_email } ) ;

		} else {

			# I've been called and neither the userid nor the email is present, so
			# die.

			croak
				"user_confirmed constraint called with neither userid nor email" ;

		}

		# Always use this in conjunction with a user_exists check and then this
		# line become redundant.
		unless ( $user -> fetch ( $dbh ) ) { return undef } ;

		$user -> status eq 'CONFIRMED'
			? return 1
			: return undef ;

	}

}

sub user_email_unchanged {

=head3 user_email_unchanged

This constraint tests the user_email field supplied against that found in the
database using the userid associated with the current session for the database
lookup. This is used in account management where certain validations are only
applied to the user_email if it changed, e.g. is it unique, i.e. not found in
the database. Of course if it hasn't changed then it will be found in the
database.

=cut

	my ( $dbh , $session ) = @_ ;

	return sub {

		my ( $dfv , $value ) = @_ ;

		my $user = new SiteFunk::Auth::User ;
		# User the session userid in case user_userid field is also changed
		$user -> userid ( $session -> param ( 'userid' ) ) ;
		$user -> fetch ( $dbh ) ;
		if ( $user -> email eq $value ) { return 1 }
		else { return 0 } ;

	}

}

sub user_exists {

=head3 user_exists

This constraint tests if the user exists. The user can be identified by userid
or by email.

=cut

   my $dbh = shift ;

   return sub {

      my ( $dfv , $value ) = @_ ;

		my $user = new SiteFunk::Auth::User ;

		if ( $dfv -> get_current_constraint_field eq 'user_userid' ) {

			$user -> userid ( $value ) ;

		} elsif ( $dfv -> get_current_constraint_field eq 'user_email' ) {

			$user -> email ( $value ) ;

		} else {

			# If we end up here something is wrong and we could throw an exception.

		}

		return $user -> fetch ( $dbh ) ;

   }

}

sub user_secret_valid {

=head3 user_secret_valid

This constraint checks a user_secret provided in conjunction with an action that
requires a valid user_secret to authorise it.

=cut

	my $dbh = shift ;

	return sub {

		my ( $dfv , $user_secret ) = @_ ;

		my $data = $dfv -> get_filtered_data ;

		my @keys = keys %{ $data } ;

		my $user = new SiteFunk::Auth::User ;

		if ( grep /^user_userid$/ , @keys ) {

			$user -> userid ( $data -> { user_userid } ) ;

		} elsif ( grep /^user_email$/ , @keys ) {

			$user -> email ( $data -> { user_email } ) ;

		} else {

			# I've been called and neither the userid nor the email is present, so
			# die.

			croak
				"user_confirmed constraint called with neither userid nor email" ;

		}

		return 0 unless $user -> fetch ( $dbh ) ;

		# If there isn't a secret or a datetime set then this constraint must fail
		return 0 unless $user -> secret && $user -> datetime ;

		# Now compare the provided user_secret with the secret stored in the user
		# object.

		my $rc = 0 ;

		my $secret_created_at = new DateTime (
			year			=> substr ( $user -> datetime , 0	, 4 ) ,
			month			=> substr ( $user -> datetime , 5	, 2 ) ,
			day			=> substr ( $user -> datetime , 8	, 2 ) ,
			hour			=> substr ( $user -> datetime , 11	, 2 ) ,
			minute		=> substr ( $user -> datetime , 14	, 2 ) ,
			second		=> substr ( $user -> datetime , 17	, 2 ) ,
			time_zone	=>	'UTC'
		) ;

		my $now = DateTime -> now ;

		my $secret_age =
			$now -> subtract_datetime_absolute ( $secret_created_at ) ;

		$rc = 1 if
			$user -> secret eq $user_secret &&
			$secret_age -> in_units ( 'seconds' ) <= 60 * 60 * 48 ;

		return $rc ;

	}

}

sub user_userid_unchanged {

=head3 user_userid_unchanged

This constraint compares a supplied user_userid field against the userid
associated with the current session. It is useful for account management checks
which only apply if there is an attempt to change the userid, e.g. a new userid
must not exist in the database whereby if the userid is unchanged of course it
will.

=cut

	my $session = shift ;

	return sub {

		my ( $dfv , $value ) = @_ ;

		if ( $value eq $session -> param ( 'userid' ) ) { return 1 }
		else { return 0 } ;

	}

}

sub userid_valid {

=head3 userid_valid

This constaint tests if a userid is a valid format.

=cut

	return sub {

		my ( $dfv , $value ) = @_ ;

		$dfv -> name_this ( 'userid_valid' ) ;

		$value =~ m/[^a-zA-Z0-9]/
			? return undef
			: return 1 ;

	}

}

sub email_taken {

	my $dbh = shift ;

	return sub {

		my ( $dfv , $value ) = @_ ;

		my $user = new SiteFunk::Auth::User ;
		$user -> email ( $value ) ;
		return $user -> fetch ( $dbh ) ;

	}

}

1 ;

__END__
