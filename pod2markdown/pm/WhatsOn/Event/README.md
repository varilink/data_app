# DATA::WhatsOn::Event

## new

## Accessor Methods

### rowid

### name

### dates

### dates\_derived

Derives the dates range from the start\_date and end\_date

### dates\_valid

Checks if the dates field is consistent with start\_date and end\_date

### start\_date

### start\_day

A read-only method that returns to day name associated with the start date. This
method was added after the post method. Possibly the post method can use this
method to simplify its own logic. We could convert more logic in post to
methods; for example to derive rel\_who\_where, etc.

### end\_date

### end\_day

A read-only method that returns to day name associated with the end date. This
method was added after the post method. Possibly the post method can use this
method to simplify its own logic. We could convert more logic in post to
methods; for example to derive rel\_who\_where, etc.

### times

### venue\_name

### venue\_rowid

### society\_name

### society\_rowid

### presented\_by

### box\_office

### status

### use\_desc

### description

### image

### temp

Provides the ability to set and retrieve temporary values for an event object.
Temporary values are not persisted in the database. It can be useful for
programs to be able to associate values temporarily with an event object for
working purposes.

### as\_hash

## Data Persistence Methods

### save

Save an event to the database either as an update to an existing event or an
insert of a new event.

### delete

Delete an event from the database.

## Other methods

### post

Produce a shortened description of an event (lacking the full detail) suitable
for a post that includes the full detail via a link to the event page.
