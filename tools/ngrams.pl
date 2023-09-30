#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Getopt::Std;
use Pod::Usage;
use Data::Dumper;

use constant DICT_FILE => '/tmp/dict.txt';
use constant DICT_LEARN_FILE => '/tmp/dict_learn.txt';
use constant DICT_TEST_FILE => '/tmp/dict_test.txt';
use constant FREQ_FILE => '/tmp/freq.txt';
use constant NGRAM_SIZE => 3;
use constant MIN_WORD_LENGTH => 4;

=head1 SYNOPSIS

Usage: ngrams.pl <command> [<args>]

Commands:

=over 4

=item prepare_dict

Reads a list of valid email addresses from /tmp/dict.txt and splits it
into /tmp/dict_learn.txt and /tmp/dict_test.txt. The input file can contain full email addresses
or just the local part. The domain part is ignored.

=item calc_freq

Calculates ngram frequency from /tmp/dict_learn.txt and writes it to /tmp/freq.txt

=item test <threshold>

Tests the accuracy of the algorithm using /tmp/dict_test.txt and the given threshold.
The threshold should be a number between 0 and 100.

=item calc_threshold

Calculates the best threshold by calling C<test> repeatedly until accuracy is maximized.

=item is_random <string> [<threshold>]

Returns 1 if the given string is random, 0 otherwise. If threshold is given,
it is used instead of the default value of 0.1

=item random_string <length>

Returns a random string of the given length

=back

=cut

my %opts;
getopts('h', \%opts) or pod2usage(1);
pod2usage(1) if $opts{h};

my %ngrams;
my $ngram_count = 0;
my $command = shift @ARGV or pod2usage(1);
my %dispatch = (
    'prepare_dict' => \&prepare_dict,
    'calc_freq' => \&calc_freq,
    'is_random' => sub {
        my ($str,$threshold) = @_;
        print is_random($str,$threshold,1) ? "1\n" : "0\n";
    },
    'test' => sub {
        my $threshold = shift;
        my ($accuracy,$fp,$fn) = test($threshold);
        print "Accuracy: $accuracy% FP=$fp FN=$fn\n";
    },
    'random_string' => sub {
        my $length = shift;
        print random_string($length),"\n";
    },
    'calc_threshold' => \&calc_threshold,
);

if ( !exists $dispatch{$command} ) {
    pod2usage('Invalid command');
}
$dispatch{$command}->(@ARGV);

sub prepare_dict {

    my $dict_file = DICT_FILE;
    open(my $df, '<', $dict_file) or die "Could not open file '$dict_file' $!";
    my $dict_learn_file = DICT_LEARN_FILE;
    open(my $learn_fh, '>', $dict_learn_file) or die "Could not open file '$dict_learn_file' $!";
    my $dict_test_file = DICT_TEST_FILE;
    open(my $test_fh, '>', $dict_test_file) or die "Could not open file '$dict_test_file' $!";

    my $selector = 1; # determines which file to write to
    while (my $localpart = <$df>) {
        chomp $localpart;
        $localpart =~ s/@.*//;                  # remove domain, if any
        $localpart = lc $localpart;             # lowercase
        $localpart =~ s/^[\d\s]+|[\d\s]+$//g;   # remove leading and trailing spaces & digits
        next if length($localpart) < MIN_WORD_LENGTH;         # skip short addresses
        next if $localpart =~ /\d/;             # skip addresses with digits in the middle
        next if $localpart =~ /=|\+/;           # skip VERP addresses
        next unless $localpart =~ /^[a-z0-9\+\_\=\.\-]+$/; # skip addresses with invalid characters

        if ( $selector == 1) {
            # Write to test file
            print $test_fh "$localpart\n";
            # and generate a random address as well
            my $length = rand(8) + 4; # between 4 and 12 characters
            my $rand = random_string($length);
            print $test_fh "$rand\n";
        } else {
            # Write to learn file
            print $learn_fh "$localpart\n";
        }
        # alternate between learn and test file. This makes sure that the data
        # is distributed evenly in case the input file is sorted
        $selector = 1 - $selector;
    }
    close $df;
    close $learn_fh;
    close $test_fh;

}

sub calc_freq {
    my $dict_file = DICT_LEARN_FILE;
    open(my $df, '<', $dict_file) or die "Could not open file '$dict_file' $!";
    while (my $word = <$df>) {
        foreach (find_ngrams($word)) {
            if ( !exists $ngrams{$_} ) {
                $ngrams{$_} = 1;
            } else {
                $ngrams{$_}++;
            }
            $ngram_count++;
        }
    }
    close $df;

    my ($min,$max) = (1,0);
    foreach (keys %ngrams) {
        my $freq = $ngrams{$_} / $ngram_count;
        $min = $freq if $freq < $min;
        $max = $freq if $freq > $max;
        $ngrams{$_} = $freq;
    }
    foreach (keys %ngrams) {
        my $freq = $ngrams{$_};
        $ngrams{$_} = ($freq - $min) / ($max - $min) * 100;
    }

    my $freq_file = FREQ_FILE;
    open(my $ff, '>', $freq_file) or die "Could not open file '$freq_file' $!";
    foreach (sort { $ngrams{$b} <=> $ngrams{$a} } keys %ngrams) {
        printf $ff "%s %.8f\n", $_, $ngrams{$_};
    }
    close $ff;

    undef;
}

sub find_ngrams {
    my $word = lc($_[0]);
    chomp $word;

    my @ngrams;
    if ( length($word) >= NGRAM_SIZE ) {
        for (my $i = 0; $i < length($word) - (NGRAM_SIZE-1); $i++) {
            my $ngram = substr($word, $i, NGRAM_SIZE);
            push @ngrams, $ngram;
        }
    }
    return @ngrams;
}


sub is_random {
    my $str = lc(shift);
    my $threshold = shift || 0.1;
    my $verbose = shift || 0;

    if ( !%ngrams ) {
        my $ngram_file = FREQ_FILE;
        open(my $bf, '<', $ngram_file) or die "Could not open file '$ngram_file' $!";
        while (my $line = <$bf>) {
            chomp $line;
            my ($ngram,$freq) = split(/\s+/, $line);
            $ngrams{$ngram} = $freq;
        }
        close $bf;
    }

    my ($common,$uncommon) = (0,0);
    foreach (find_ngrams($str)) {
        if (exists $ngrams{$_} && $ngrams{$_} >= $threshold) {
            $common++;
            print "$_ common\n" if $verbose;
        } else {
            $uncommon++;
            print "$_ uncommon\n" if $verbose;
        }
    }
    return $uncommon > $common;

}

sub test {
    my $threshold = shift;
    die "Threshold must be between 0 and 100" if $threshold < 0 || $threshold > 100;

    my ($count,$correct,$fp,$fn) = (0,0,0,0);
    my $dict_file = DICT_TEST_FILE;
    my $is_random = 1;
    open(my $df, '<', $dict_file) or die "Could not open file '$dict_file' $!";
    while (my $word = <$df>) {
        chomp $word;
        $is_random = 1-$is_random;  # in the test file, every other address is random
        next if length($word) < MIN_WORD_LENGTH;
        $count++;
        if ( !is_random($word, $threshold) == !$is_random ) {
            $correct++;
        } else {
            # printf("failed test: %s is %s\n",$word, $expected ? 'random' : 'not random');
            if ($is_random) {
                $fn++;
            } else {
                $fp++;
            }
        }
    }
    close $df;

    my $accuracy = $correct / $count * 100;
    return ($accuracy,$fp/$count*100,$fn/$count*100);
}

sub calc_threshold {

    my ($lower,$upper) = (0,100);
    my $max_accuracy;
    my $best;
    my @thresholds;
    my @accuracies;

    while ( 1 ) {
        $max_accuracy = 0;
        undef $best;
        undef @thresholds;
        undef @accuracies;
        my $step = ($upper - $lower) / 5;
        printf "Testing thresholds from %f to %f with step %f\n",$lower,$upper,$step;
        for (my $threshold = $lower; $threshold <= $upper; $threshold += $step) {
            my ($accuracy) = test($threshold);
            push(@thresholds,$threshold);
            push(@accuracies,$accuracy);
            if ( $accuracy >= $max_accuracy ) {
                $max_accuracy = $accuracy;
                $best = @thresholds-1;
            }
            printf "  %4f %8f \n",$threshold,$accuracy;
        }
        return unless defined($best);

        if ($best == 0) {
            $upper = $thresholds[1];
        } elsif ($best == $#thresholds) {
            $lower = $thresholds[$#thresholds - 1];
        } elsif ( $accuracies[$best - 1] > $accuracies[$best + 1] ) {
            last if $accuracies[$best - 1] == $accuracies[$best];
            $lower = $thresholds[$best - 1];
            $upper = $thresholds[$best];
        } else {
            last if $accuracies[$best + 1] == $accuracies[$best];
            $lower = $thresholds[$best];
            $upper = $thresholds[$best + 1];
        }

        last if $upper - $lower < 0.0001;
    }
    printf "Best threshold: %f (Accuracy %f)\n",$thresholds[$best],$max_accuracy;

}

sub random_string {
    my $length = shift;
    my $alpha = 'abcdefghijklmnopqrstuvwxyz';
    my $str = '';
    for (my $x=0;$x < $length;$x++) {
        $str .= substr($alpha,rand(length($alpha)),1);
    }
    return $str;
}
