package Proc::SignalStack::Alarm::DoneRef;
use strict;
use warnings;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors($_) for qw(data ready);
sub new { bless { data => undef, ready => 0 }, shift; }
sub def { defined shift()->data }

1;
