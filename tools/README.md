# SYNOPSIS

Usage: ngrams.pl &lt;command> \[&lt;args>\]

Commands:

- prepare\_dict

    Reads a list of email addresses from /tmp/dict.txt and splits it
    into /tmp/dict\_learn.txt and /tmp/dict\_test.txt.

- calc\_freq

    Calculates ngram frequency from /tmp/dict\_learn.txt and writes it to /tmp/freq.txt

- test &lt;threshold>

    Tests the accuracy of the algorithm using /tmp/dict\_test.txt and the given threshold.
    The threshold should be a number between 0 and 100.

- calc\_threshold

    Calculates the best threshold by calling `test` repeatedly until the best value is found

- is\_random &lt;string> \[&lt;threshold>\]

    Returns 1 if the given string is random, 0 otherwise. If threshold is given,
    it is used instead of the default value of 0.1

- random\_string &lt;length>

    Returns a random string of the given length
