use strict;
use warnings;
use Test::More;

use RPi::BMP180;

# HW-free: _pin_base() is pure Perl, so we bless a bare object to exercise its
# validation without new()'s wiringPi setup(). The module has no DESTROY, so a
# bare object is safe to let fall out of scope.

my $mod = 'RPi::BMP180';

# --- _pin_base() validation ---
{
    my $o = bless {}, $mod;

    for my $bad ('x', -1, 3.5, '12a'){
        eval { $o->_pin_base($bad) };
        like $@, qr/requires an integer/, "_pin_base('$bad'): non-integer croaks";
    }

    my $unset = bless {}, $mod;
    eval { $unset->_pin_base };
    like $@, qr/has not yet been set/, '_pin_base(): unset getter croaks';

    is $o->_pin_base(200), 200, '_pin_base(200): sets and returns';
    is $o->_pin_base, 200, '_pin_base(): getter returns the set value';
    is $o->_pin_base(0), 0, '_pin_base(0): zero is a valid pin base';
}

# --- new() with no pin base croaks before any wiringPi setup ---
{
    my $ok = eval { $mod->new; 1 };
    ok ! $ok, 'new() with no pin_base croaks';
    like $@, qr/has not yet been set/, '  ...via _pin_base, before setup';
}

done_testing();
