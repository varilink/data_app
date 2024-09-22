# DATA::WhatsOn

Extends the DATA::Main class to provide public actions,event management and
organisation management run modes, all of which are action run modes.

## Public Actions

These are public actions, i.e. they can be invoked without having to be
authenticated or have specific authorisation.

### join\_us

Make an enquiry for a performing arts society that isn't yet a member of DATA to
join. The enquiry gets emailed to the webmin.

### membership

Register an individual member.

### notify\_event

Process an event notification via the event notification form. The details are
sent via eamil to the webmin.

### printed\_listing

Produce a one page PDF listing of coming events on either an A4 or A5 page for
printing.

## Event Management

Run modes that support the management of events

### event\_programme

Handle the addition of event programme details or a change to existing event
programme details.

### event\_online

Handle the addition of an event online listing or changes to an existing event
online listing.

### rep\_event\_display

Display the details of an event or a society for a rep to update. This would be
handled by the auto run mode in the Main module except that we need an
application specific, data based authorisation check. So, the relevent run modes
are directed to here in this module instead.

## Organisation Management

Run modes that support the management of organisations

### organisation

Adds or updates a member society record.

### rep\_society\_display

Display the details of a society for a rep to view or update. This would be
handled by the auto run mode in the Main module except that we need an
application specific, data based authorisation check. So, the relevent run modes
are directed to here in this module instead.
