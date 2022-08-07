package DATA::Dispatch ;

=head1 DATA::Dispatch

=cut

use base 'CGI::Application::Dispatch::PSGI' ;

sub dispatch_args {

   my $table ;

   return {

      prefix => 'DATA' ,

      table => [

###
### The authentication handlers
###

         'auth/login' => {

            app => 'Auth'  ,
            rm  => 'login' ,

         } ,

         'auth/logout' => {

            app => 'Auth'   ,
            rm  => 'logout' ,

         } ,

         'auth/request' => {

            app => 'Auth'    ,
            rm  => 'request' ,

         } ,

###
### The public area of the site
###

         'coming_events' => {

            # Display the list coming events

            app => 'Main'      ,
            rm =>  'coming_events' ,

         } ,

         'the_diary_scheme' => {

            # Display some narrative about the diary scheme

            app => 'Main'             ,
            rm  => 'the_diary_scheme' ,

         } ,

         'member_societies' => {

            # Display a list of the member socities

            app => 'Main'                 ,
            rm  => 'member_societies' ,

         } ,

         'society_details/:rowid' => {

            # Display the coming events for a society

            app => 'Main'           ,
            rm  => 'society_details' ,

         } ,

###
### Unadvertised public run modes for the administrator
###

         'login' => {

            # Display a form to login

            app => 'Main'  ,
            rm  => 'login' ,

         } ,

  'userid_reminder' => {

     # Request a reminder of your userid via email

     app => 'Main' ,
     rm => 'userid_reminder' ,

  } ,


  'userid_reminder_sent' => {

     # Confirmation that a userid reminder has been sent

     app => 'Main' ,
     rm => 'userid_reminder_sent' ,

  } ,

  'request_password' => {

     # Request a reminder of your userid via email

     app => 'Main' ,
     rm => 'request_password' ,

  } ,


  'password_sent' => {

     # Confirmation that a userid reminder has been sent

     app => 'Main' ,
     rm => 'password_sent' ,

  } ,

###
### The administration area pages
###

         'admin/maintain_events' => {

            app => 'Main' ,
            rm  => 'maintain_events' ,

         } ,

         'admin/programme' => {

            # Download a programme listing in .doc format
            # for monthly distribution via email

            app => 'WhatsOn' ,
            rm => 'programme' ,

         } ,

         'admin/maintain_societies' => {

            app => 'Main' ,
            rm  => 'maintain_societies' ,

         } ,

         'admin/maintain_contacts' => {

            app => 'Main' ,
            rm  => 'maintain_contacts' ,

         } ,

         'admin/distribution_list' => {

            # Download a distribution list of email addresses for
            # for the monthly mailing of the events list

            app => 'WhatsOn' ,
            rm => 'distribution_list' ,

         } ,

         'admin/update_event/:rowid' => {

            # Display a form to update (or delete) an event

            app => 'Main'  ,
            rm  => 'update_event' ,

         } ,

         'admin/update_society/:rowid' => {

            # Display a form to update (or delete) a society

            app => 'Main' ,
            rm  => 'update_society' ,

         } ,

         'admin/update_contact/:rowid' => {

            # Display a form to update (or delete) a contact

            app => 'Main' ,
            rm  => 'update_contact' ,

         } ,

         'admin/add_event' => {

            # Display a form to add an event

            app => 'Main'  ,
            rm  => 'add_event' ,

         } ,

         'admin/add_society' => {

            # Display a form to add an event

            app => 'Main'  ,
            rm  => 'add_society' ,

         } ,

         'admin/add_contact' => {

            # Display a form to add an event

            app => 'Main'  ,
            rm  => 'add_contact' ,

         } ,

###
### The administration area actions
###

         'admin/action/add_event' => {

            # Add an event

            app => 'WhatsOn'     ,
            rm  => 'add_event' ,

         } ,

         'admin/action/update_event' => {

            # Update or delete an event

            app => 'WhatsOn'     ,
            rm  => 'update_event' ,

         } ,

         'admin/action/add_society' => {

            # Add a society

            app => 'WhatsOn'     ,
            rm  => 'add_society' ,

         } ,

         'admin/action/update_society' => {

            # Update or delete a society

            app => 'WhatsOn'     ,
            rm  => 'update_society' ,

         } ,

         'admin/action/add_contact' => {

            # Add a contact

            app => 'WhatsOn'     ,
            rm  => 'add_contact' ,

         } ,

         'admin/action/update_contact' => {

            # Update or delete a contact

            app => 'WhatsOn'     ,
            rm  => 'update_contact' ,

         } ,

###
### The user maintenance pages
###

         'user/update_user' => {

            app => 'Main' ,
            rm  => 'update_user' ,

         } ,

###
### The user actions
###

         'user/action/update_user' => {

            # Add an event

            app => 'Auth' ,
            rm  => 'update_password' ,

         } ,

         '/action/userid_reminder' => {

            # Add an event

            app => 'Auth' ,
            rm  => 'userid_reminder' ,

         } ,

         '/action/request_password' => {

            # Add an event

            app => 'Auth' ,
            rm  => 'request_password' ,

         } ,

      ] ,

   } ;

}

1 ;

__END__