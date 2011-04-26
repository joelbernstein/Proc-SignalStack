package Proc::SignalStack::Handler;
use strict;
use warnings;
use Carp;
use English '-no_match_vars';
use Scalar::Util qw(weaken);

use overload 
    '&{}' => \&handler,
    '""'  => \&handler,
;

sub new {
    my $class = shift;
    my %args = @_;
    my ($sig_name, $subs, $parent) = @args{qw(signal coderefs parent)};
    weaken $parent;

    if (defined $subs) {
        $subs = [ $subs ] unless ref $subs eq 'ARRAY';
    }

    Carp::croak "cannot create a handler without a sig_name and sig_handlers"
        unless defined $sig_name && defined @{ $subs };

    my $handler = sub { 
        for (0..$#$subs) {
            eval {
                $subs->[$_]->();
            };
            if ($EVAL_ERROR) {
                chomp $EVAL_ERROR;
                my $num = Lingua::EN::Numbers::Ordinate::ordinate(1 + $_); 
                warn <<"EOT"
The following exception was raised while running the $num signal in the 
signal stack for signal '$sig_name':
$EVAL_ERROR
EOT
;
            }
        }
    };


    my $self = bless { handler => $handler, parent => $parent }, $class;
    $self;
}

sub handler { shift->{handler} }
sub parent  { shift->{parent}  }

1;
