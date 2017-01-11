use warnings;
use strict;
use feature 'say';

use RPi::BMP180;

my $bmp = RPi::BMP180::bmp180_init(0x77, "/dev/i2c-1");

# bmp180_dump_eprom($bmp);

RPi::BMP180::bmp180_set_oss($bmp, 1);

while (1){
    say "baro: " . RPi::BMP180::bmp180_pressure($bmp) / 1000;
    say "alt   " . RPi::BMP180::bmp180_altitude($bmp);
    sleep 1;
}
