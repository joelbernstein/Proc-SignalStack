#!env perl
package Test::Proc::SignalStack::Install;
use strict;
use warnings;
use Test::More tests => 3;
use Proc::SignalStack;

sub dummy {}
sub setup {
    my $ss = Proc::SignalStack->new;
    $ss->add( USR1 => \&dummy );
    $ss->add( USR1 => \&dummy );
    $ss->add( USR1 => \&dummy );
    $ss;
}

my $ss = setup();
ok($ss->uninstall, "uninstall before install succeeds");
ok($ss->uninstall_permanently, "uninstall_permanently before install succeeds");
ok($ss->install, "install after uninstall_permanently succeeds");

$ss = setup();


