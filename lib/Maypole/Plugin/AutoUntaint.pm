package Maypole::Plugin::AutoUntaint;

use warnings;
use strict;

use NEXT;

Class::DBI::Plugin::AutoUntaint->require;

=head1 NAME

Maypole::Plugin::AutoUntaint - CDBI::AutoUntaint for Maypole

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    package BeerDB;
    use Maypole::Application qw( AutoUntaint );
    
    BeerDB->auto_untaint;

=over 4

=item setup

If the C<-Setup> flag is passed in the call to L<Maypole::Application|Maypole::Application>,
C<auto_untaint> will be called automatically, with no arguments. [not tested]

=cut

sub setup 
{
    my $r = shift;
    
    $r->NEXT::DISTINCT::setup( @_ );

    $r->auto_untaint;
}

=item auto_untaint( %args )

Takes the same arguments as C<Class::DBI::AutoUntaint::auto_untaint()>, but 
the C<untaint_columns> and C<skip_columns> hashrefs must be further keyed by table:
    
    untaint_columns => { $table => { $untaint_as => [ qw( col1 col2 ) ], 
                                     ...,
                                     },
                         ...,
                         },
   
    skip_columns => { $table => [ qw( colx coly ) ],
                      ...,
                      },
                      
Accepts two additional arguments. C<match_cols_by_table> is the same as the 
C<match_cols> argument, but only applies to specific tables: 

    match_cols_by_table => { $table => { $col_regex => $untaint_as,
                                         ...,
                                         },
                             ...,
                             },
                             
Column regexes in <match_cols_by_table> that are the same as any in <match_cols>
will take precedence.

C<untaint_tables> specifies the tables to untaint as an arrayref. Defaults to 
C<$r->config->{display_tables}>.

=cut

sub auto_untaint {
    my ( $r, %args ) = @_;
    
    # insert CDBI::Plugin::AutoUntaint into the model class
    {
        my $model = $r->config->model ||
            warn "Please configure a model in $r before calling auto_untaint()";
        no strict 'refs';
        *{"$model\::auto_untaint"} = \&Class::DBI::Plugin::AutoUntaint::auto_untaint;
    }
    
    my $untaint_tables = $args{untaint_tables} || $r->config->{display_tables};

    foreach my $table ( @$untaint_tables )
    {
        eval {
            my %targs = map { $_ => $args{ $_ } } qw( untaint_types match_types );
            
            $targs{untaint_columns} = $args{untaint_columns}->{ $table };
            $targs{skip_columns}    = $args{skip_columns}->{ $table };
            
            $targs{match_columns} = $args{match_columns};
            
            if ( my $more_match_cols = $args{match_columns_by_table}->{ $table } )
            {
                $targs{match_columns}->{ $_ } = $more_match_cols->{ $_ } 
                    for keys %$more_match_cols;
            }
                                        
            $targs{debug} = $r->debug;
            $targs{maypole} = 1;
            
            my $class = $r->config->loader->find_class( $table );
        
            $class->auto_untaint( %targs );
        };
        
        warn $@ if $@;
    }
}

=back

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-maypole-plugin-autountaint@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Maypole-Plugin-AutoUntaint>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

=cut

1; # End of Maypole::Plugin::AutoUntaint
