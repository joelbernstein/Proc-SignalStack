package Proc::SignalStack;
use strictures;
use true;
use Scalar::Util qw(blessed);
use English '-no_match_vars';
use Lingua::EN::Numbers::Ordinate ();
require Carp;
use overload ();
use Proc::SignalStack::Handler;
our $VERSION = '0.01';


=head1 NAME

Proc::SignalStack - Stacked signal handlers

=head1 SYNOPSIS

use Proc::SignalStack;
my $ss = Proc::SignalStack->new;
$ss->add(INT  => \&handle_sigint1);
$ss->add(INT  => \&handle_sigint2);
$ss->add(ALRM => \&handle_timeout);
$ss->install; # set these handlers active, saving any signals
# ... do stuff with signals ...
$ss->uninstall;             # deactivate our signal handlers, replace originals
# ... do some other stuff with your own signal handlers
$ss->install;               # reactivate our signal stack
# ... do stuff with signals ...
$ss->uninstall_permanently; # deactivate and clear signal handlers, replace originals

=head1 DESCRIPTION

This module provides a mechanism for stacked signal handlers. That means you can install multiple handlers
for any signal (even user-defined signal names - see L<perlipc>#Signals).

Perl's standard C<%SIG> signal-handling framework does not provide for multiple pieces of code to be 
informed that a signal event is raised - the purpose of this module is to provide this functionality.

Signals may be stacked, installed, and uninstalled such that any signals installed previously are replaced.
That is to say, for each signal you configure in the signal stack, if a handler for that signal is already
installed when the signal stack object is installed, the existing signal handler will be stored in order to 
replace it when the signal stack is uninstalled - it will NOT be added to the signal stack.

=head1 CONSTRUCTOR

=head2 new
    
    my $ss = Proc::SignalStack->new;
    my $ss_with_signals = Proc::SignalStack->new([ {USR1=>\&foo}, {USR1=>\&bar} ]);
    my $mortal_ss = Proc::SignalStack->new([], mortal=>1); # Proc::SignalStack::Mortal

Constructs a C<Proc::SignalStack> or C<Proc::SignalStack::Mortal> object. 

The first argument may be an C<ARRAY>ref of C<HASH>refs (AoH) of C<{SIGNAL=>\&handler}>.

An optional C<mortal=>1> may be specified to denote whether to build a mortal object
which uninstalls itself when it goes out of scope. See L<Proc::SignalStack::Mortal|Proc::SignalStack::Mortal>.

=head1 METHODS

=head2 add

    $ss->add( SIGNAL => \&handler );

Store the specified handler subroutine into the signal stack for signal SIGNAL.

=head2 install

    $ss->install;

Install the signal stack's sighandlers, saving any existing handlers to be restored later.

=head2 signals

    my $sig_counts = $ss->signals;
    my $USR1_count = $sig_counts->{USR1};

Returns a C<HASH>ref mapping signal names to the number of stacked handlers for them.

=head2 uninstall

    $ss->uninstall;

Uninstalls the handlers configured in the signal handler object, replacing any handlers
set previously, before installation. The handlers remain configured in the object and
can be reinstalled at any time.

=head2 uninstall_permanently

    $ss->uninstall_permanently;

Uninstalls the handlers configured in the signal handler object, replacing any handlers
set previously, before installation. The handlers are deleted from the object and can 
not be reinstalled.

=head1 SEE ALSO

L<perlipc|perlipc>
L<sigtrap|sigtrap>
L<Proc::SignalStack::Mortal|Proc::SignalStack::Mortal>

=head1 LICENSE

This module is available under the same terms as Perl itself.

=head1 AUTHOR

Joel Bernstein C<<rataxis@cpan.org>>.

=head1 COPYRIGHT

(C)opyright Joel Bernstein 2007

=cut


$OUTPUT_AUTOFLUSH++;

sub new {
    my ($class, $sig_data, %options) = @_;

    $sig_data = [] unless defined $sig_data;
    %options  = () unless         %options;

    # do we want a Mortal object?
    if ($class eq __PACKAGE__) { # superclass only
        return Proc::SignalStack::Mortal->new($sig_data, %options)
            if defined $options{mortal} && $options{mortal};
    }

    Carp::croak "Signal stack definition must be an array reference" 
        unless ref $sig_data eq 'ARRAY';

    my $self = { SIG => {}, OLD => {}, _installed => 0 };
    bless $self, $class;

    for my $sig_ref (@{ $sig_data }) {
        $self->add($sig_ref);
    }

    $self;
}

sub install {
    my $self = shift;
    return 1 unless keys %{ $self->{SIG} }; # shortcircuit NOOP install

    while (my ($sig, $subs) = each %{ $self->{SIG} }) {
        if (exists $SIG{$sig}) {
            my $oldsig = $SIG{$sig};
            my $isa = blessed $oldsig;
            unless ( defined $isa 
                &&  $isa eq 'Proc::SignalStack::Handler'
                &&  $oldsig->parent == $self ) 
            {   
                $self->{OLD}{$sig} = $SIG{$sig};
                warn "saved $sig";
            }
        } 
        else { warn "no old sig for $sig, so not saving" }
        
        my $sig_handler = $self->_make_handler($sig, $subs);
        warn "about to install handler $sig_handler for $sig";
        $SIG{$sig} = $sig_handler;
        warn "completed install handler $sig_handler for $sig";
    }   

    $self->_installed(1);
}

sub add {
    my $self = shift;
    my $signals = ref $_[0] ? shift : {@_};

    my ($sig, $sub) = %{ $signals };
    Carp::croak "Cannot handle signal '$sig' without a CODEref (or something which quacks like one)"
        unless Proc::SignalStack::Util::works_like_coderef($sub);

    warn "adding $sig";
    push @{ $self->{SIG}{$sig} ||= [] }, $sub;
}

sub signals {
    my $self = shift;
    return { map { $_ => scalar @{ $self->{SIG}{$_} } } keys %{ $self->{SIG} } };
}

sub uninstall {
    my $self = shift;
    return unless defined $self;

    #my $must_reinstall = 0;
    while (my ($sig, $subs) = each %{ $self->{SIG} }) {
        warn "sig: $sig\n";
        delete $self->_sig->{$sig}; # is this right? how can we reinstall this stack now??
        if ($self->_installed) {
            warn "SIG $sig = $SIG{$sig}\n";
            $SIG{$sig} = 'DEFAULT'; # restore default handler, per perlvar
        }

        warn "sig: $sig\n";
        # reinstall old signal handler
        my $oldsig = delete $self->{OLD}{$sig};
        if (defined $oldsig) {
    warn "reinstalling $oldsig for $sig\n";
            $SIG{$sig} = $oldsig;
        }

#        if (exists $self->{OLD}{$sig}) {
#            warn "found old handler for $sig\n";
#            my $oldsig = delete $self->{OLD}{$sig};
#            if (ref $oldsig ne 'Proc::SignalStack::Handler') {
#                warn "and it's not a handler, mapping and preparing to reinstall\n";
#                $self->_sig->{$sig} = [$oldsig];
#                $must_reinstall = 1;
#            }
#        }
#        else { warn "no OLD sigs" }
    }

    #$self->install if $must_reinstall;
    $self->_installed(0);
    1;
}

sub uninstall_permanently {
    my $self = shift;
    $self->uninstall;
    $self->_sig( {} );
    1;
}

sub _installed {
    my $self = shift;
    if (@_) {
        $self->{_installed} = shift;
    }
    return $self->{_installed};
}


sub _sig {
    my $self = shift;
    if (@_) {
        my $sigs = ref $_[0] ? shift : {@_};
        $self->{SIG} = $sigs;
    }
    $self->{SIG};
}

sub _make_handler {
    my ($self, $sig_name, $subs) = @_;
    warn "signame $sig_name subs $subs";
    return unless $subs;
    return Proc::SignalStack::Handler->new(signal=>$sig_name, coderefs=>$subs, parent=>$self) 
        if defined $sig_name;
}

package Proc::SignalStack::Mortal;
use base qw(Proc::SignalStack);
=head1 NAME

    Proc::SignalStack::Mortal - Block-scoped signal handlers

=head1 SYNOPSIS

    {
        use Proc::SignalStack::Mortal;
        my $ss = Proc::SignalStack::Mortal->new;
        $ss->add( ... );
        # some other work
    } # Mortal signalstack uninstalls when it goes out of scope

=head1 DESCRIPTION

This module offers the same interface as C<Proc::SignalStack>, of which it is a subclass.

The only difference is that when objects of this class are C<DESTROY>ed, e.g. by garbage collection after going out
of scope or due to the reference count reaching zero, the signals it controls will be uninstalled.

=head1 SEE ALSO

L<Proc::SignalStack|Proc::SignalStack>.

=cut

sub DESTROY {
    shift->uninstall_permanently;
}

1;


package Proc::SignalStack::Util;

=head2 works_like_coderef( $thingy )

Returns 1 if C<$thingy> can be used as a C<CODE>ref.

=cut

sub works_like_coderef {
    my $thingy = shift;
    return unless defined $thingy;
    my $isa = ref $thingy;
    return unless defined $isa;
    Carp::croak "_works_like_coderef is not a method on ".__PACKAGE__  
        if $isa eq __PACKAGE__;
    return 1 if $isa eq 'CODE' || defined overload::Method($thingy, '&{}');
}
