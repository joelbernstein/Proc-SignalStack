#!env perl
package Test::Proc::SignalStack::ConstructorBranches;
use strict;
use warnings;
use Test::More tests => 9;
$|++;
use Test::Exception;
use Proc::SignalStack;

ok(my $ss=Proc::SignalStack->new([], mortal => 1), "construct mortal sigstack");

dies_ok{my $fails = Proc::SignalStack->new({})} "HASHref of signals dies";

dies_ok{$ss->add(USR1 => []) } "non-coderef sighandler dies";


my $dummy = sub { 1 };
warn "\ndummy $dummy\n";
$SIG{USR1} = $dummy;
is($SIG{USR1}, $dummy, "original sighandler");

my $ss2 = Proc::SignalStack->new;
my $dummy2 = sub {};
warn "dummy2 $dummy2\n";
$ss2->add(USR1=> $dummy2);

ok($ss2->install, "install new handler over pre-existing one");
ok(defined $SIG{USR1}, "USR1 sighandler is defined");
#this test is wrong - the handler stack closing around ALL handlers
#is installed, not $dummy2
#is($SIG{USR1}, $dummy2, "original sighandler replaced with dummy2");

ok($ss2->uninstall, "uninstall handlers, should replace with old");
ok(defined $SIG{USR1}, "USR1 sighandler is defined");

use Data::Dumper;
warn Dumper \%SIG;
is($SIG{USR1}, $dummy, "previous sighandler replaced after uninstall");
