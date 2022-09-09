# DATA::Auth

This module implements DATA's user authentication and account mangement
functionality. The run modes provided by this module fall into the following
categories; authentication, account creation and account management (post
creation).

## Authentication

Controls the authentication of a session via login and logout methods.

### login

Process an attempt to authenticate.

### logout

Unauthenticate a session via a logout method.

## Account Creation

The various account creation process steps in the DATA website.

### begin\_registration

The first step of account registration is a test that the email that the account
is to be associated with is valid for an account.

### complete\_registration

Register a user account. As well as success for failure outcomes there is a
warning outcome for which confirmation to proceed with account registration is
required.

### confirm\_registration

Confirm a registration when the email address isn't recognised as belonging to
either a member of the DATA committee or a known representative of a DATA member
society.

### confirm\_email

Confirm a registration by clicking on the link in the email sent.

### resend\_confirmation\_email

Resend the confirmation email following user account creation.

## Account Managment (Post Creation)

Various account management actions that are available after the account creation
process has completed.

### userid\_reminder

Send the user a reminder of their userid.

### request\_password\_reset

Request a password reset.

### request\_password\_reset

Show the password reset page when somebody that has requested a password reset
clicks on the link with the password reset email that is sent to them.

### reset\_password

Action the password reset entered via the password reset page.

### request\_password

Request a new, randomly generated password.

### update\_account

Make a change to any of the details associated with a user account.

### update\_password

Updates the password of the currently logged on user.
