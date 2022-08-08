# DATA::Auth::Constraints

Provides auth related contraints for use in forms.

## Constraints

### credentials\_match

Tests supplied login credentials to see if they match what we have on record.

### not\_a\_robot

Tests that the user interacting with the site is not a robot.

### password\_complex

Checks that a user supplied password is sufficiently complex to be secure.

### representative\_known

Validates that a registering user, who claims to represent one or more socities
is actually known to be a representative of those societies.

### committee\_member

Validates that a registering user is a committee member.

### user\_confirmed

Tests if a user has been confirmed, by which we mean its email address has been
confirmed by clicking on the confirmation link that we send to the email address
in an email. It uses userid if that's provided or email as an alternative if
userid is not present.

### user\_email\_unchanged

This constraint tests the user\_email field supplied against that found in the
database using the userid associated with the current session for the database
lookup. This is used in account management where certain validations are only
applied to the user\_email if it changed, e.g. is it unique, i.e. not found in
the database. Of course if it hasn't changed then it will be found in the
database.

### user\_exists

This constraint tests if the user exists. The user can be identified by userid
or by email.

### user\_secret\_valid

This constraint checks a user\_secret provided in conjunction with an action that
requires a valid user\_secret to authorise it.

### user\_userid\_unchanged

This constraint compares a supplied user\_userid field against the userid
associated with the current session. It is useful for account management checks
which only apply if there is an attempt to change the userid, e.g. a new userid
must not exist in the database whereby if the userid is unchanged of course it
will.

### userid\_valid

This constaint tests if a userid is a valid format.
