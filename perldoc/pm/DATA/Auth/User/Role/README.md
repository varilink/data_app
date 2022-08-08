# DATA::Auth::User::Role

Implements the user role domain object for the auth application.

## Accessors

### userid

Of course, this is the userid associated with a user role as opposed to the
accessor for the userid associated with a user, which is implemented in the user
domain object.

### role

## Persistence

Persistence methods for the user role object. These use the database to store
objects.

### fetch

Class method that instantiates the user role objects for a user from the
database.

### save

Saves a user role object to the database, either as an insert or update
depending on whether that user role is new to the database or not.
