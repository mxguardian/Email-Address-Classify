package Email::Address::Classify;
use strict;
use warnings FATAL => 'all';
use File::Basename;

my %ngrams;
our $threshold = 0.21;
our $VERSION = '0.01';

sub _init {

    # read ngrams from Classify/freq.txt
    my $filename = dirname($INC{'Email/Address/Classify.pm'}).'/Classify/freq.txt';
    open(my $fh, '<', $filename) or die "Can't open $filename: $!";
    while (my $line = <$fh>) {
        chomp $line;
        my ($ngram, $freq) = split(/\s+/, $line);
        $ngrams{$ngram} = $freq;
    }
    close($fh);

}

sub new {
    my ($class,$address) = @_;
    my $self = bless {
        address => $address,
    }, $class;
    my $email = _parse_email($address);
    if ( $email ) {
        $self->{localpart} = $email->{localpart};
        $self->{domain} = $email->{domain};
        $self->{valid} = 1;
    } else {
        $self->{valid} = 0;
    }

    return $self;
}

sub is_valid {
    my $self = shift;
    return $self->{valid};
}

sub _find_ngrams {
    my $str = lc($_[0]);
    my @ngrams;
    for (my $i = 0; $i < length($str) - 2; $i++) {
        push @ngrams, substr($str, $i, 3);
    }
    return @ngrams;
}

sub is_random {
    my $self = shift;

    return $self->{random} if exists $self->{random};

    return $self->{random} = 0 unless $self->{valid} && length($self->{localpart}) > 3;

    _init() unless %ngrams;

    my ($common,$uncommon) = (0,0);
    foreach (_find_ngrams($self->{localpart})) {
        if (exists $ngrams{$_} && $ngrams{$_} >= $threshold) {
            $common++;
        } else {
            $uncommon++;
        }
    }
    return $self->{random} = ($uncommon > $common ? 1 : 0);
}

sub _parse_email {
    my $email = shift;
    return undef unless defined($email) &&
        $email =~ /^((?:[a-zA-Z0-9\+\_\=\.\-])+)@((?:[a-zA-Z0-9\-])+(?:\.[a-zA-Z0-9\-]+)+)$/;

    return {
        address => $email,
        localpart => $1,
        domain => $2,
    };

}

1;