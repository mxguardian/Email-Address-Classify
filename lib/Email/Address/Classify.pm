package Email::Address::Classify;
use strict;
use warnings FATAL => 'all';
use File::Basename;

=head1 NAME

Email::Address::Classify - Classify email addresses

=head1 SYNOPSIS

    use Email::Address::Classify;

    $email = Email::Address::Classify->new('a.johnson@example.com');

    print "Is valid:  " . $email->is_valid() ? "Y\n" : "N\n";    # Y
    print "Is random: " . $email->is_random() ? "Y\n" : "N\n";   # N

=head1 DESCRIPTION

This module provides a simple way to classify email addresses. At the moment, it only
provides two classifications:

=over 4

=item is_valid()

Returns true if the address conforms to the RFC 5322 specification. Returns false otherwise.
If this method returns false, all other methods will return false as well.

=item is_random()

Returns true if the localpart is likely to be randomly generated, false otherwise.
Note that randomness is subjective and depends on the user's locale and other factors.
This method uses a list of common trigrams to determine if the localpart is random. The trigrams
were generated from a corpus of 30,000 email messages, mostly in English.



=back


=head1 METHODS

=head2 new($address)

Creates a new Email::Address::Classify object. The only argument is the email address

=head2 is_valid()

Returns true if the address is valid, false otherwise.

=head2 is_random()

Returns true if the address is random, false otherwise.

=head1 TODO

=over 4

=item * Add more classifications

Ideas for other classifications include: disposable, role-based, etc.

=back

=head1 AUTHOR

Kent Oyer <kent@mxguardian.net>

# LICENSE AND COPYRIGHT

Copyright (C) 2023 MXGuardian LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the LICENSE
file included with this distribution for more information.

You should have received a copy of the GNU General Public License
along with this program.  If not, see https://www.gnu.org/licenses/.



my %ngrams;
our $threshold = 0.8; # empirically determined
our $min_length = 4;
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

    return $self->{random} = 0 unless $self->{valid} && length($self->{localpart}) >= $min_length;

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