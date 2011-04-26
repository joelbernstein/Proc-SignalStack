package Test::Proc::SignalStack::OneShot;
use strict;
use warnings;
use Test::More 'no_plan';

my $pkg = "Proc::SignalStack";
use_ok($pkg);

my $signals = 
[   {TERM => sub {warn "term1"}}, 
    {TERM => sub {warn "term2"}},
    {USR1 => sub {die  "usr1-1"}},
    {USR1 => sub {warn "usr1-2"}}   ];

ok(my $ss = $pkg->new($signals), "constructor succeeds");
ok($ss->install, "install signal handlers");

ok(my $sigs = $ss->signals, "->signals");
is(ref $sigs, "HASH", " .. returns a hashref");
is_deeply($sigs, {TERM=>2, USR1=>2}, " .. with correct sig handler counts");

kill USR1 => $$;
kill TERM => $$;
