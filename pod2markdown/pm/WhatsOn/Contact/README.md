### address1

### address2

### address3

### address4

### postcode

### role

The role of a contact in an organisation. Where contacts are fetched for a
single organisation, the role within the organisation is merged in to the
contact object.

### primary\_contact

Whether a contact is the primary contact for an organisation or not. Where
contacts are fetched for a single organisation, this flag is merged in to the
contact object.

### organisations

Sets or returns a reference to an array containing object instances of
DATA::WhatsOn::Contact::Organisation

### add\_org

### as\_hash

Returns the contact as an unblessed hash with lower case keys

### fetch

### representative

Tests if an email address corresponds to a known representative of one or more
member socities. Returs true if it does and false if it doesn't.

### committee\_member

Tests if an email address corresponds to a known DATA committee member.
