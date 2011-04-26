#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Proc::SignalStack' );
}

diag( "Testing Proc::SignalStack $Proc::SignalStack::VERSION, Perl $], $^X" );
