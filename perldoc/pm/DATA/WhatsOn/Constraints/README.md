# DATA::WhatsOn::Constraints

## contact\_is\_subscribed

## event\_description\_valid

Tests if the event description has non HTML content in it, i.e. it does contain
descriptive text and not just markup tags.

## event\_image\_provided

## event\_image\_valid

This constraint is called in two circumstances:
1.	When a save is executed and we're validating the contents of a tinymce
		editor instance;
2.	When we're attempting to copy an image from an external URL after that URL
		has been entered in to the tincymce image dialog box.

## user\_is\_authorised

This constraint tests that the user is authorised to undertake an action on a
WhatsOn Event or Society. It enforces the following:
1\. An admin can add or update any event or a society;
2\. A rep can add or update events for the society or societies that they
   represent;
3\. A rep can update a society or societies that they represent but they can not
   add a society.

## user\_is\_rep\_for\_event

Given a userid and the rowid for an event this constraint verifies that the user
is a representative for the event, which is the same as saying that the user is
a representative for the society that is presenting the event.

## venue\_exists

Tests if an organisation exists.
