# DATA::Auth::User

Implements the User domain object for the Auth application.

## Accessors

### userid

Userid accessor method

### role

Role accessor method

### email

Email accessor method

### first\_name

First name accessor method

### surname

Surname accessor method

### 

Password accessor method

### status

Status accessor method

### secret

Secret accessor method

### datetime

Datetime accessor method

### rowid

Rowid (person rowid) accessor method

## Persistence

Persistence methods for the user object. These use the database to store
objects.

### as\_hash

Represents the user object as a hash.

### load

Class method that loads users from a file into the database, probably now
redundant.

### fetch

Restores the details of a user from the database. Can do this either via userid
or via email.

### 

Saves a user object in the database using either insert for a new user or update
for an existing user.

### insert

Insert a user to the database, which obviously overlaps with "save". I susepct
that one of these methods is redundant.

### store

Store a user in the database. Performs either an insert or an update. This would
seem to be a direct equivalent of save so I suspect one of these methods is
redundant.

### generate\_password

Class method to generate a password.

### already\_user

Test if there is already a userid registered for the email address. This method
is probably referenced by constraints but is encapsulated here along with all
the other methods that translate between a user object and its database
representation.

### not\_unique

Test if a userid is a duplicate of one already known. Again, probably referenced
by constraints but exists here amongst the methods that map a user object to
its database representation.
