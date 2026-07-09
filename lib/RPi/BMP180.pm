package RPi::BMP180;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '3.1802';

use WiringPi::API qw(:all);

sub new {
    my ($class, $pin_base) = @_;
    my $self = bless {}, $class;
    $self->_pin_base($pin_base);
   
    setup_gpio(); 
    bmp180_setup($pin_base);

    return $self;
}
sub temp {
    my ($self, $want) = @_;
    return bmp180_temp($self->_pin_base + 0, $want);
}
sub pressure {
    my ($self) = @_;
    return bmp180_pressure($self->_pin_base + 1);
}
sub _pin_base {
    my ($self, $base) = @_;

    if (defined $base){
        if ($base !~ /^\d+$/){
            croak "_pin_base() requires an integer";
        }
        $self->{bmp_pin_base} = $base;
    }

    if (! defined $self->{bmp_pin_base}){
        croak "_pin_base() has not yet been set...";
    }
    return $self->{bmp_pin_base};
}
sub _vim{};

1;
__END__

=head1 NAME

RPi::BMP180 - Interface to the BMP180 barometric pressure sensor

=head1 SYNOPSIS

    use RPi::BMP180;

    my $base = 300;

    my $bmp = RPi::BMP180->new($base);

    my $f = $bmp->temp;
    my $c = $bmp->temp('c');
    my $p = $bmp->pressure; # kPa

=head1 DESCRIPTION

This module allows you to interface with a BMP180 barometric and temperature
sensor. 

=head1 METHODS

=head2 new($pin_base)

Returns a new C<RPi::BMP180> object.

Parameters:

    $pin_base

Mandatory: Integer, the number at which to start the 'pseudo' GPIO pins for
communication to the sensor. Anything above the highest numbered GPIO pin will
do. For example, C<100> or C<200>.

=head2 temp

Fetches the temperature from the sensor.

Parameters:

    $want

Optional: String. By default, we return Fahrenheit. To get Celsius, pass in
C<'c'>.

Returns a floating point number.

=head2 pressure

Fetches the barometric pressure in kPa.

Takes no parameters, returns a floating point number.

=head1 TECHNICAL INFORMATION

Everything this module does on the bus happens inside wiringPi's devLib
(C<bmp180.c>) - the Perl layer maps L</temp> and L</pressure> onto pseudo
analog pins at C<$pin_base>, and the C layer below runs the I2C
conversation documented here.

=head2 DEVICE SPECIFICS

    - Bosch piezo-resistive barometric pressure + temperature sensor
    - Pressure range 300-1100hPa; relative accuracy +/-0.12hPa typical
      at 3.3V, absolute +/-1.0hPa (0-65C)
    - Operating range -40 to +85C; full accuracy 0 to +65C
    - Runs at 1.8-3.6V; power it from the Pi's 3.3V rail, NOT 5V (many
      breakout boards regulate and level-shift, bare modules don't)
    - Raw pressure carries up to 19 significant bits at the highest
      oversampling; wiringPi's devLib uses ultra-low-power mode (oss 0,
      16-bit)
    - I2C up to 3.4MHz; the 7-bit address is fixed at 0x77, so one
      BMP180 per bus
    - 176-bit factory-trimmed calibration EEPROM, individual per device

Wiring a typical breakout: VIN to 3.3V, GND to ground, SDA to GPIO 2
(pin 3), SCL to GPIO 3 (pin 5). C<i2cdetect -y 1> shows the chip at
C<0x77>.

=head2 REGISTER MAP

    0xAA-0xBF   calib        11 x 16-bit factory calibration words
                             (AC1-AC6, B1, B2, MB, MC, MD; MSB first)
    0xD0        id           Chip identifier, always reads 0x55
    0xE0        soft reset   Write 0xB6 for a power-on-style reset
    0xF4        ctrl_meas    Measurement control (see below)
    0xF6        out_msb      Result MSB
    0xF7        out_lsb      Result LSB
    0xF8        out_xlsb     Extra low bits, oversampled modes only

C<ctrl_meas> breaks down as C<oss> in bits 7-6 (pressure oversampling,
0-3 = 1/2/4/8 internal samples), C<sco> in bit 5 (start of conversion -
reads 1 while a conversion runs, 0 once the data registers are ready),
and the measurement command in bits 4-0:

    0x2E    Temperature          4.5ms max conversion
    0x34    Pressure, oss 0      4.5ms   (what the devLib uses)
    0x74    Pressure, oss 1      7.5ms
    0xB4    Pressure, oss 2     13.5ms
    0xF4    Pressure, oss 3     25.5ms

=head2 ON THE WIRE

The devLib talks SMBus register-style transactions through the kernel's
C</dev/i2c-1>: a register write is one START-to-STOP frame, and a
register read is a write of the register number, a repeated START, then
the data phase. The chip's 7-bit address C<0x77> appears on the wire as
C<0xEE> for writes and C<0xEF> for reads:

    S = START    Sr = repeated START    P = STOP
    A = ACK (receiver pulls SDA low)    N = NACK (master, "no more bytes")

Starting a temperature conversion - C<ctrl_meas> (0xF4) is written
C<0x2E>, then the C code sleeps 5ms while C<sco> runs:

    +---+------+---+------+---+------+---+---+
    | S | 0xEE | A | 0xF4 | A | 0x2E | A | P |
    +---+------+---+------+---+------+---+---+
         addr+W     ctrl_meas  Temperature
         (0x77)                command

Reading the 16-bit result - two single-byte register reads, 0xF6 then
0xF7. Each is a pointer write, a repeated START, and one data byte the
chip drives:

    +---+------+---+------+---+----+------+---+-----+---+---+
    | S | 0xEE | A | 0xF6 | A | Sr | 0xEF | A | MSB | N | P |
    +---+------+---+------+---+----+------+---+-----+---+---+
         addr+W     out_msb          addr+R     Chip
                    pointer          (read)     drives

    UT = MSB * 256 + LSB

The pressure conversion is the same shape: C<0xF4> is written C<0x34>
(oss 0), another 5ms sleep, then 0xF6, 0xF7 and 0xF8 are read and
combined as

    UP = MSB * 256 + LSB + XLSB / 256

Both raw values then run through the calibration math on the Pi - the
chip itself never outputs degrees or pascals.

Two more shapes worth knowing. At C<new()> time (C<bmp180_setup>), the
devLib slurps the calibration EEPROM as eleven 16-bit words - twenty-two
of the pointer-write/repeated-START/read frames above, covering 0xAA
through 0xBF. And every L</temp> or L</pressure> call runs the
I<complete> temperature-plus-pressure cycle shown here (two commands,
two 5ms sleeps, five result-byte reads - roughly 10ms per call), because
the compensation math needs a fresh temperature either way.

=head2 DATASHEET

The Bosch Sensortec BMP180 datasheet (BST-BMP180-DS000-09, rev 2.5) is
distributed with this software as F<docs/datasheet/BMP180.pdf>. It covers
the register map, the timing, and the compensation algorithm this module's
stack implements.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
