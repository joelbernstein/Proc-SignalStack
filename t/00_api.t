package Test::Proc::SignalStack::API;
use strict;
use warnings;
use Test::More 'no_plan';
$|++;
my $pkg = "Proc::SignalStack";
use_ok $pkg;

for my $method (qw( new install add uninstall uninstall_permanently 
                    signals _sig _make_handler)) 
{
    can_ok($pkg, $method);
}

ok(my $ss = $pkg->new, "constructor succeeds");
isa_ok($ss, $pkg);
