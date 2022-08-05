package DATA::Project::Source::Parser ;

=head1 DATA::Project::Source Parser

This module exports a parse method that can be applied to Gulp page, partial and
layout template files to convert them in to Templage Toolkit page and include
template files.

=cut

use strict ;
use YAML ;

use Exporter qw / import / ;

our @EXPORT = qw / parse / ;

sub parse {

=head2 parse

The parse method. This is provided with a Gulp template file, which can be a
page, partial or layout file and it returns the equivalent Template Toolkit
file.

=cut

	my $source = shift ; # Source object (either page or partial) passed in

	my ( $name , $content ) = ( $source -> name , $source -> content) ;

	# At this stage we do not know whether we are dealing with a GULP Page,
	# Partial or Layout. We posit that it is a Partial. We will admit Page or
	# Layout later if/when we discover that our posit was wrong.
	my $type = 'Partial' ;

	# We are about to split the content in to YAML and the following body (HTML)
	my $yaml = '' ; # Contains any extracted YAML
	my $body = '' ; # Contains the body, excluding any YAML

SPLIT:
	{

		# If the file contains YAML, which is only the case for Page files, then
		# split the file in to its YAML and body that follows the YAML.

		my $isYAML = undef ; # Tells us whether a line is YAML or not

		foreach my $line ( @{ $content } ) {

			if ( $line eq "---\n" ) {

				if ( $isYAML ) {

					# End of any YAML
					$isYAML = undef ;
					$line = '' ; # Don't want the second '---' in the body

				} else {

					# Start of any YAML
					$isYAML = 1 ;
					$type = 'Page' ; # Admit type Page, it has to be if there's YAML

				} # End of if $isYAML

			} ; # End of if $line eq "---\n"

		$yaml .= $line if $isYAML ;
		$body .= $line if !$isYAML

		} # End of foreach my $line

		$type = 'Layout' if $body =~ /\{\{>\s*body\s*\}\}/m ; # Admit type Layout

		# We have:
		# 1. Split the input in to YAML ($yaml) and HTML ($body)
		# 2. Established the type of the file - page, partial or layout

	} # End of the SPLIT phase

# The output (initially empty) that we will start to build now

	my $vars ;
	my $output = '' ;

PREPARSE:
	{

# Before we start parsing the body of the file, there is some pre-processing

		if ( $type eq 'Page' ) {
	
# The YAML at the top of a page file contains variables that either need to be
# translated in to Template Toolkit SET statements of Template Toolkit INCLUDE
# statements for layout header and footer files

			$vars = Load $yaml if $yaml ;

			use Data::Dumper ;
			$Data::Dumper::Pair = ' = ' ;
			$Data::Dumper::Quotekeys = 0 ;
			$Data::Dumper::Terse = 1 ;

			$output .="[% SET\n\n" ;

			foreach my $parm ( keys %{ $vars } ) {

				if ( $parm eq 'buttons' ) {

					print Dumper $vars -> { $parm } ;

				}

				unless ( $parm eq 'layout' ) {

					my $val ;
					if ( $parm eq 'buttons' ) {
						$val = Dumper $vars -> { $parm } -> { button } ;
					} else {
						$val = Dumper $vars -> { $parm } ;
					}
					$output .= "$parm = $val\n" ;

				}

			}

			$output .= "%]\n\n" ;

#			sub recurse_vars {

#				my $parms = shift ;

#				my @keys ;
#				if ( ref $parms eq 'HASH' ) { @keys = keys %{ $parms } }
#				elsif ( ref $parms eq 'ARRAY' ) { @keys = @{ $parms } }

#				foreach my $parm ( @keys ) {

#					if ( ref $parms -> { $parm } eq 'HASH' ) {

#						&recurse_vars ( $parms -> { $parm } ) ;

#					} elsif ( ref $parms -> { $parm } eq 'ARRAY' ) {

#						&recurse_vars ( $parms -> { $parm } ) ;

#					} elsif ( $parm eq 'layout' ) {

						# Ignore layout

#					} else {

#						my $val = $parms -> { $parm } ;
#						$output .= "\$parm=\'$val\' %]\n\n" ;

#					}
#				}

#			}

#			&recurse_vars ( $vars ) ;

			unless ( $vars -> { layout } ) {

# No layout has been specified, so include the default header and footer.

				$output .= "[% INCLUDE header.tt %]\n\n" ;
				$output .= $body ;
				$output .= "\n[% INCLUDE footer.tt %]" ;

			} else {

# A layout has been specified, so include the header and footer associated with
# that layout.

				my $header = $vars -> { layout } . '_header' ;
				my $footer = $vars -> { layout } . '_footer' ;
				$output .= "[% INCLUDE $header.tt %]\n\n" ;
				$output .= $body ;
				$output .= "\n[% INCLUDE footer.tt %]" ;

			}

		} elsif ( $type eq 'Partial' && $name =~ /(header|footer)$/ ) {

# It is either a header or a footer, so add layout content. First select the
# layout file that we need.

			my $needed = $name =~ /^(\w+)_(header|footer)$/ ? $1 : 'default' ;

			my $project = new DATA::Project ( $source -> sitename ) ;

			my @layouts = $project -> layouts ;

			my $selected ;

			foreach my $layout ( @layouts ) {

				if ( $layout -> name eq $needed ) { $selected = $layout } ;

			}

# Now include the layout content in the output. This is achieved by appending
# copying the layout content that falls before a body statement in the layout
# file in to a header. That's unecessary for the footer currently because there
# is nothing that falls after the body statment other than the footer embed
# itself.

			my $addon = $selected -> template ; # Load AND PARSE the layout

			if ( $name =~ /header$/ ) {

# Strip everything from the layout from the header INCLUDE onwards

				$addon =~ s/\[\%\s+PROCESS\s+\w*_?+header\.tt\s+\%\].*//ms ;
				$output = $addon . $body ; # Append to the start of the header

			} elsif ( $name =~ /footer$/ ) {

# Strip everything from the layout up to and including the footer INCLUDE

				$addon =~ s/.*\[\%\s+PROCESS\s+\w*_?+footer\.tt\s+\%\]//ms ;
				$output = $body . $addon ; # Append to the end of the footer

			}

		} else {

			$output = $body ;

		} # End of if ( $type eq 'Page' )

	} # End of the PREPARSE phase

PARSE:
	{

# We parse the output is mutiple passes, looking for and translating content in
# each pass as follows:
# 1. Panini handlebars helpers;
# 2. Instructions to embed CGI applications, indicated via a HTML comment;
#
# Firstly, copy the output from either the preparse or the previous parse pass
# to be the input to this parse pass and truncate the output ready for
# rebuilding via this parse pass.

HANDLEBARS:
		{

			my $input = $output ; $output = '' ;
			my $posn = 0 ; 			# Starting position for each match search
			my $ignore = 0 ; my $sethis = undef ;
			my $context = undef ; 	# Context is set by handlebar with commands
			my $foreach = undef ; 	# Variable name set by a handlebar each command

			while ( $input =~ /
				\{{2,3}			# Opening brackets
				[>#\/!]?			# Optional partial, command, terminator or comment
				.+?            # What falls within the handlbars
				\}{2,3}			# Closing brackets
			/mgsx ) {

# Gather information about the match; start and end positions, what falls before
# the match (and after the previous match) and the content of the match itself.

				my ( $start , $end ) = ( $-[0] , $+[0] ) ;
				my $before = substr $input , $posn , $start - $posn ;
				my $match = substr $input , $start , $end - $start ;

				$output .= $before ;

				if ( $ignore ) {

					$ignore = 0 ;

					if ( $match =~ /^\{\{#\s*each\s+([\w\.'\/]*)/ ) {
						$foreach = $1 ;
					}

					goto MATCH_END ;

				}

				if ( substr ( $match , 0 , 3 ) eq '{{>' ) {

# Convert Panini '>' to Template Toolkit INCLUDE
# ACTUALLY RENAME A LOT OF THIS STUFF TO REFER TO PANINI RATHER THAN GULP

					$match =~ /^\{\{>\s*(\w+).*\}\}$/s ;

					if ( $context ) {

						$output .= '[% PROCESS ' . $1 . '.tt' ;

#						foreach my $parm ( keys %{ $vars -> { $context } } ) {

#							my $val = $vars -> { $context } -> { $parm } ;
#							$output .= "\n   $parm = \"$val\"" ;

#						}

#						$output .= "\n%]" ;

						$output .= " context = $context %]" ;

					} else {

						$output .= '[% PROCESS ' . $1 . '.tt %]' ;

					}

				} elsif ( substr ( $match , 0 , 3 ) eq '{{#' ) {

# Convert Panini helper command to Template Toolkit equivalent
# Panini commands can be one of 'each' 'if', 'ifequal', 'ifpage' or 'with'

					$match =~ /
						^\{\{\#			# Helper opening with # indicating a command
						\s*				# Zero or more spaces
						(\w*)				# The command itself
						\s*				# Zero or more spaces
						([\w\.'\/]*)	# Parameter 1 (always present)
						\s*				# Zero or more spaces
						([\w\.'\/]*)	# Parameter 2 (may be present)
						\s*				# Zero or more spaces
						\}\}$				# Helper terminator
					/x ;

					my $command = $1 ;
					my $parm1 = $2 ;
					my $parm2 = $3 if $3 ;
					$parm1 =~ s/..\/// ;
					$parm2 =~ s/..\/// ;

					if ( $command eq 'each' ) {

						if ( $sethis ) { $foreach = $sethis ; $sethis = undef }
						else { $foreach = $parm1 } ;
						my $plural ;
						if ( $foreach =~ /(\w+)y$/ ) { $plural = $1 . 'ies' }
						else { $plural = $foreach . 's' } ;

						$output .= "[% FOREACH $foreach IN $plural %]"

					} elsif ( $command eq 'if' ) {

						$parm1 =~ s/this\./$foreach\./ ; # Could be a this var

						if ( $type eq 'Partial' &&  # This is a partial
						     $parm1 !~ /\./ ) {     # var does not contain a .

							$parm1 = 'context.' . $parm1
								unless grep /^$parm1$/ , ( 'title' , 'root' ) ;

						}

						$output .= '[% IF ' . $parm1 . ' %]' ;

					} elsif ( $command eq 'unless' ) {

						$parm1 =~ s/this\./$foreach\./ ; # Could be a this var

						$output .= '[% UNLESS ' . $parm1 . ' %]' ;

					} elsif ( $command eq 'ifequal' ) {

# parm1 is always the name of a variable. parm2 could multiple things

						if ( $type eq 'Partial' &&  # This is a partial
						     $parm1 !~ /\./ ) {     # var does not contain a .

							$parm1 = 'context.' . $parm1
								unless grep /^$parm1$/ , ( 'title' , 'root' ) ;

						}

						if ( $parm2 =~ /^constant.(\w+)$/ ) {

# I am not sure that I need this case any more?

						} elsif ( $parm2 =~ /^\'(\w+)\'$/ ) {

# Parm2 is a constant

							$output .=
								'[% IF ' . $parm1 . ' == ' . '"' . $1 . '"' . ' %]' ;

						} else {

							$output .=
								'[% IF ' . $parm1 . ' == ' . $parm2 . ' %]' ;

						}


					} elsif ( $command eq 'ifpage' ) {

						$output .= '[% IF page_run_mode == ' . $parm1 . ' %]'	;			

					} elsif ( $command eq 'unlesspage' ) {

						$output .= '[% UNLESS page_run_mode == ' . $parm1 . ' %]'	;			

					} elsif ( $command eq 'with' ) {

						$context = $parm1 ; # Note the context set by the with block

					} # End if ( $command eq 'each' )

				} elsif ( substr ( $match , 0 , 3 ) eq '{{/' ) {

# End of a Panini each or with block. Convert to a TT END statement.

					$match =~ /^\{\{\/\s*(\w*)\s*\}\}$/ ;

					if ( $1 eq 'each' ) {

						$foreach = undef ; # The each block has ended so unset foreach

						$output .= '[% END %]'

					} elsif ( $1 eq 'with' ) {

						$context = undef ; # The with block has ended so unset context

					} else {

						$output .= '[% END %]'

					} ;

				} elsif ( substr ( $match , 0 , 3 ) eq '{{!' ) {

# This is a handlbars comment. Either ignore it or output the TT content within

					if ( $match =~ /
							^\{\{!		# Comment opening
							\s*			# Zero or more spaces
							TT				# Literal "TT" - output manipulation command
							\s+			# One or more spaces
							(\w+)			# The command itself
							\s+			# One or more spaces
							(.*)			# Command content
							\}\}$			# The end
						/sx ) {

# This is a direct instruction to manipulate the output embedded in a
# Handlebars comment

						my $command = $1 ; my $content = $2 ;

						if ( $command eq 'insert' ) {

# Directly insert the TT content embedded in the Handlebars command

							$output .= $content ;

						} elsif ( $command eq 'ignore' ) {

# Ignore next Handlebars helper that you see

							$ignore = 1 ;

						} elsif ( $command eq 'sethis' ) {

							$content =~ /^(\w+)/ ;
							$sethis = $1 ;

						}

					} else {

# Just ignore the comment and it won't get written to the TT template

					}

				} else {

# This is a variable or possible and else statement

					$match =~ /^\{{2,3}\s*([\w\.\/]+)\s*\}{2,3}$/ ;

					if ( $1 eq 'else' ) {

						$output .= '[% ELSE %]' ;

					} else {

						my $var = $1 ;

						$var =~ s/this\./$foreach\./ ;
						$var =~ s/..\/// ;

						if ( $type eq 'Partial' && # This is a partial
						     $var !~ /\./ ) {     # var does not contain a .

							$var = 'context.' . $var
								unless grep /^$var$/ , ( 'title' , 'root' ) ;

						}

						$output .= '[% GET ' . $var . ' %]' ;

					}

				}

MATCH_END:

				$posn = $end ;

			}

			$output .= substr $input , $posn ;

		} # End of HANDLEBARS pass

LINKS:
if ( $source -> mode eq 'deploy' )
		{

# Convert .html links to their run mode equivalents

			my $input = $output ; $output = '' ;
			my $posn = 0 ; 			# Starting position for each match search

			while ( $input =~ /(\<a.*?\<\/a\>)/msg )
			{

# Gather information about the match; start and end positions, what falls before
# the match (and after the previous match) and the content of the match itself.

				my ( $start , $end ) = ( $-[0] , $+[0] ) ;
				my $before = substr $input , $posn , $start - $posn ;
				my $match = substr $input , $start , $end - $start ;

				my $content = $1 ;

				$output .= $before ;

				# Drop index.html or .html for internal links
				$content =~ s/(\[% GET root %\](?:[\w|_|\d|\/])*)index\.html/$1/ ||
				$content =~ s/(\[% GET root %\](?:[\w|_|\d|\/])*)\.html/$1/ ;

				$output .= $content ;

				$posn = $end ;

			}

			$output .= substr $input , $posn ;

		} # End of LINKS pass

LABELS:
		{

			my $input = $output ; $output = '' ;
			my $posn = 0 ; 			# Starting position for each match search

			while ( $input =~ /
				\<label\>		# Start of a label tag
				(.*?)			# What falls within the label		
				\<\/label\>		# End of a label tag
			/msgx ) {

# Gather information about the match; start and end positions, what falls before
# the match (and after the previous match) and the content of the match itself.

				my ( $start , $end ) = ( $-[0] , $+[0] ) ;
				my $before = substr $input , $posn , $start - $posn ;
				my $match = substr $input , $start , $end - $start ;

# $match includes the <label> and </label> tags so capture $1 to isolate the
# $content that falls between those tags.

				my $content = $1 ;

# If there is any white space at the end of what falls $before the $match then
# strip that from the end of $before and capture what has been $stripped for
# it to be re-added to the $output again.

				my $stripped = '' ;
				if ( $before =~ s/(\s+$)//s ) { $stripped = $1 } ;

# We need the name of the input field in order to test if the error condition
# associated with that specific input has been set.

				( my $name ) = $content =~ /name\=\"(\w+?)\"/ ;

				$output .= $before ;

				$output .= "[% UNLESS error_$name # Initial State %]\n\n" ;
				$output .= $stripped . $match ;

				$output .= "\n\n[% ELSE # Error State %]\n\n" ;
				$output .= $stripped . '<label class="is-invalid-label">' ;

				$content =~
					s/class\=\"form\-error\"/class\=\"form\-error\ is\-visible\"/ ;

# Note multiple substitutions via the /g because we might be using constructs
# such as ifpage to support different variations on the input and select tags

				$content =~
					s /\<(input|select)/\<$1 class\=\"is-invalid-input\"/g ;

				$output .= "$content</label>\n\n[% END # error_$name %]" ;
				$posn = $end ;

			}

			$output .= substr $input , $posn ;

		} # End of LABELS pass

EMBEDS:
		{

			my $input = $output ; $output = '' ;
			my $posn = 0 ; 			# Starting position for each match search

			while ( $input =~ /
				\<\!\-\-			# Comment start
				\s+				# One or more spaces
				embed				# The embed command
				\s+				# One or more spaces
				([\w_]+)			# The application component to embed
				\s+				# One or more spaces
				\-\-\>			# Comment end
				(.+?)				# The content that forms the macro
				\<\!\-\-			# Comment start
				\s+				# One or more spaces
				\/embed			# The embed terminator
				\s+				# One or more spaces
				\-\-\>			# Comment end
			/mgsx ) {

# Gather information about the match; start and end positions, what falls before
# the match (and after the previous match) and the content of the match itself.

				my ( $start , $end ) = ( $-[0] , $+[0] ) ;
				my $before = substr $input , $posn , $start - $posn ;
				my $match = substr $input , $start , $end - $start ;

				$output .= $before ;

				my $app = $1 ;
				my $block = $2 ;

				$output .= '[% MACRO ' . $app . ' BLOCK %]' ;
				$output .= $block ;
				$output .= '[% END # MACRO ' . $app . ' BLOCK %]' . "\n\n" ;
   	  		$output .= "[% CGIAPP.embed ( \'" . $app . "\') %]" ;

				$posn = $end ;

			}

			$output .= substr $input , $posn ;

		} # End of EMBEDS pass

ERRORDIV:
		{

			my $input = $output ; $output = '' ;
			my $posn = 0 ; 			# Starting position for each match search

			while ( $input =~ /
				\<div\ data\-abide\-error	# Start of data-abide-error div
				(.*)								# The content of the data-abide-error div
				\<\/div\>						# End of data-abide-error div
			/mgsx ) {

# Gather information about the match; start and end positions, what falls before
# the match (and after the previous match) and the content of the match itself.

				my ( $start , $end ) = ( $-[0] , $+[0] ) ;
				my $before = substr $input , $posn , $start - $posn ;
				my $match = substr $input , $start , $end - $start ;

				my $content = $1 ;
				$before =~ s/(\s+$)// ;
				my $stripped = $1 ;

				$output .= $before ;

				$output .= "\n\n[% UNLESS error # Initial State %]" ;
				$output .= $stripped . $match ;

				$output .= "\n\n[% ELSE # Error State %]" ;
				$content =~ s/display\:\ none/display\:\ block/ ;
				$output .= $stripped . '<div data-abide-error role="alert"' ;
				$output .= $content . '</div>' ;

				$output .= "\n\n[% END %]" ;

				$posn = $end ;

			}

			$output .= substr $input , $posn ;

		} # End of ERRORDIV pass

	} # End of the PARSE phase

	return $output ;

} # End of the parse subroutine

1 ;

__END__
