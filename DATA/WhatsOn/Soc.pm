package SiteFunk::WhatsOn::Soc;

use strict;
use CGI;
use base qw(SiteFunk::WhatsOn::DBFile::DomainClass);

##########################
### Object constructor ###
##########################

sub new {

   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $self = $class->SUPER::new();

   $self->{DATA}->{CONTACT} = undef;
   $self->{DATA}->{ADDRESS1} = undef;
   $self->{DATA}->{ADDRESS2} = undef;
   $self->{DATA}->{ADDRESS3} = undef;
   $self->{DATA}->{ADDRESS4} = undef;
   $self->{DATA}->{POSTCODE} = undef;
   $self->{DATA}->{E_MAIL} = undef;
   $self->{DATA}->{WEBSITE} = undef;

   bless $self, $class;
   return $self;

}

##################################
### Simple data access methods ###
##################################

sub name {

   # Override inherited method from DomainClass
   # We have a special sort without The and Derby

   my $proto = shift;

   if ( ref $proto ) {

      # Object invocation of this method

      my $self = $proto;

      if (@_) { $self->{DATA}->{NAME} = shift; }
      return $self->{DATA}->{NAME};

   } else {

      # This data access method has a class invocation
      # which sorts the data based on name.

      my $class = $proto;

      my ( $soc1, $soc2 ) = @_;

      ( my $socname1 = $soc1->{DATA}->{NAME} ) =~ s/Derby |The //i;
      ( my $socname2 = $soc2->{DATA}->{NAME} ) =~ s/Derby |The //i;

      return ( $socname1 cmp $socname2 );

   }

}

sub contact {

   my $self = shift;
   if (@_) { $self->{DATA}->{CONTACT} = shift }
   return $self->{DATA}->{CONTACT};

}

sub address1 {

   my $self = shift;
   if (@_) { $self->{DATA}->{ADDRESS1} = shift }
   return $self->{DATA}->{ADDRESS1};

}

sub address2 {

   my $self = shift;
   if (@_) { $self->{DATA}->{ADDRESS2} = shift }
   return $self->{DATA}->{ADDRESS2};

}

sub address3 {

   my $self = shift;
   if (@_) { $self->{DATA}->{ADDRESS3} = shift }
   return $self->{DATA}->{ADDRESS3};

}

sub address4 {

   my $self = shift;
   if (@_) { $self->{DATA}->{ADDRESS4} = shift }
   return $self->{DATA}->{ADDRESS4};

}

sub postcode {

   my $self = shift;
   if (@_) { $self->{DATA}->{POSTCODE} = shift }
   return $self->{DATA}->{POSTCODE}; 
}

sub e_mail {

   my $self = shift;
   if (@_) { $self->{DATA}->{E_MAIL} = shift }
   return $self->{DATA}->{E_MAIL}; 
}

sub website {

   my $self = shift;
   if (@_) { $self->{DATA}->{WEBSITE} = shift }
   return $self->{DATA}->{WEBSITE};
}

#####################################
### Representations of the object ###
#####################################

sub liForRead {

   my $self = shift;

   if ( $self->website() ) {
      print CGI::li( CGI::a( { href=>"http://" . $self->website() }, $self->name() ) );
   } else {
      print CGI::li( $self->name() );
   }

}

sub TrForUpdate	 {

   my $self = shift;
   my $seqno = $self->seqno();

   print CGI::Tr( { valign => "top" },
      [
         CGI::td( { width => "60%" },
                  [ CGI::a( { href=>"/cgi-bin/ddo/soc/form.cgi?seqno=" . $self->seqno() },
                      $self->name()
                    )
                  ]
                ) .
         CGI::td( { width => "40%" }, [ $self->contact() ] )
      ]
   );

}

1;
