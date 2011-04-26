package Test::Proc::SignalStack::MixedAdd;
use strict;
use warnings;
use Test::More 'no_plan';
$|++;
my $pkg = "Proc::SignalStack";
use_ok $pkg;

my $signals = 
[   {TERM => sub {warn "term1"}}, 
    {TERM => sub {warn "term2"}},
    {USR1 => sub {die  "usr1-1"}},
    {USR1 => sub {warn "usr1-2"}}   ];

ok(my $ss = $pkg->new($signals), "constructor (with signals) succeeds");
ok($ss->install, "install signal handlers");

ok($ss->add(USR1 => sub { qw(a b c) }), "add another sighandler");
ok($ss->install, " ... and install it");
is($ss->signals->{USR1}, 3, " ... maintaining previously added signals");

