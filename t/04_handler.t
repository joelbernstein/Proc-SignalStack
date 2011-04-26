package Test::Proc::SignalStack::Handler;
use strict;
use warnings;
use Test::More 'no_plan';
$|++;

my $parent_pkg = "Proc::SignalStack";
my $pkg = "${parent_pkg}::Handler";
use_ok($pkg);
use_ok($parent_pkg);
for (qw(new handler)) {
    can_ok($pkg, $_);
}

my $ss = Proc::SignalStack->new;
my $thingy;
ok(my $h = $pkg->new(signal=>"foo", coderefs=>sub { $thingy = "foo" }, parent=>$ss ), "constructor");
is(ref $h, $pkg, " ... returns a $pkg");
ok(defined overload::Method($h, '&{}'), " ... which overloads CODE derefs..good");
ok($SIG{USR1} = $h, "install it as a sighandler");
ok(kill(USR1 => $$), " ... and trip it");
is($thingy, "foo", "handler ran properly");
