package Test::Proc::SignalStack::DynamicAdd;
use strict;
use warnings;
use Test::More tests => 13;
$|++;
my $pkg = "Proc::SignalStack";
use_ok $pkg;

ok(my $ss = $pkg->new, "constructor without signals succeeds");
ok($ss->install, "NOOP install succeeds");

ok($ss->add(USR1 => sub { die "usr1-1" }), "add a sighandler (hash arg)");
ok($ss->install, " ... and install it");

ok($ss->add({USR1 => sub { die "usr1-2" }}), "add another sighandler (hashref arg)");
ok($ss->install, " ... and install it");

my $sigs = $ss->signals;
is_deeply($sigs, {USR1 => 2}, "correct sighandler count");

kill USR1 => $$;

ok($ss->add(USR1 => sub { die "usr1-1" }), "add a sighandler (hash arg)");
ok($ss->install, " ... and install it");
ok($ss->uninstall_permanently,  " ... and remove it");
is_deeply($ss->signals, {}, "correct sighandler count in sigstack object");

use Data::Dumper;
warn Dumper \%SIG;
ok(exists $SIG{USR1} ? $SIG{USR1} eq 'DEFAULT' : 1, "ensure sighandler is freed");
