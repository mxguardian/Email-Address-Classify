# NAME

ngrams.pl - Tool to calculate ngram frequency from a list of email addresses and test for accuracy

Before running this script, you need to create a file /tmp/dict.txt containing a list of valid email addresses.
The file can contain full email addresses or just the local part, one per line. The domain part is ignored.
If you use full email addresses, remove duplicates first. If you use local parts, you should leave duplicates
in the file since some addresses are more common than others (e.g. support@, noreply@, etc.)

# SYNOPSIS

Usage: ngrams.pl &lt;command> \[&lt;args>\]

Commands:

- prepare\_dict

    Reads a list of valid email addresses from /tmp/dict.txt and splits it
    into /tmp/dict\_learn.txt and /tmp/dict\_test.txt.

- calc\_freq

    Calculates ngram frequency from /tmp/dict\_learn.txt and writes it to /tmp/freq.txt

- test &lt;threshold>

    Tests the accuracy of the algorithm using /tmp/dict\_test.txt and the given threshold.
    The threshold should be a number between 0 and 100.

- calc\_threshold

    Calculates the best threshold by calling `test` repeatedly until accuracy is maximized.

- dump &lt;threshold>

    Outputs all ngrams with a frequency greater than or equal to the given threshold.
    You can use this to overwrite the default ngrams.txt file with a custom list of ngrams.

- is\_random &lt;string> \[&lt;threshold>\]

    Returns 1 if the given string is random, 0 otherwise. If threshold is given,
    it is used instead of the default value of 0.1

- random\_string &lt;length>

    Returns a random string of the given length
