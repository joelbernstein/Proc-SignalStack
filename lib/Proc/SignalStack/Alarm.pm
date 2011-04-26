package Proc::SignalStack::Alarm;
use strict;
use warnings;
use Time::HiRes qw(time alarm ualarm tv_interval gettimeofday);
use Proc::SignalStack;
use Proc::SignalStack::Alarm::DoneRef;
use base 'Exporter';
our @EXPORT_OK = qw(loop alarm set_tick tick_time_remaining );

our ($NEXT_TICK, $TICK);
$TICK = 0.02;

sub set_tick {
    my $tick = shift;
    return unless defined $tick && $tick;
    $TICK = $tick;
}

sub alarm () {
    $NEXT_TICK = time + $TICK;
    Time::HiRes::alarm $TICK;
}

sub tick_time_remaining { $NEXT_TICK - time; }

sub loop {
    my ($actions) = @_;
    my $ss = Proc::SignalStack->new;
    MAINLOOP:
    do {
        my $a = shift @{ $actions };
        my $sub = make_closure($a);
        $ss->add(ALRM => $sub };
        $ss->install;
        kill ALRM => $$;
    } while (1);
}

sub make_closure {
    my $action = shift;
    my ($function, $done_callback, $done_ref) = @{ $action };
    return sub {
        if (defined $done_ref && $done_ref->ready) {
            return $done_callback->($done_ref);
        }
       
        alarm;
        $function->($done_ref);
    };
}

1;
