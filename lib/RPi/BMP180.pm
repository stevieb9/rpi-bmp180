package RPi::BMP180;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('RPi::BMP180', $VERSION);

1;
__END__

=head1 NAME

RPi::BMP180 - Interface to the BMP180 barometric/altimeter sensor on Raspberry
Pi

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use RPi::BMP180;

    my $foo = RPi::BMP180->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rpi-bmp180 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RPi-BMP180>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RPi::BMP180


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RPi-BMP180>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RPi-BMP180>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RPi-BMP180>

=item * Search CPAN

L<http://search.cpan.org/dist/RPi-BMP180/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of RPi::BMP180
