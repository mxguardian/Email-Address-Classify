# Email-Address-Classify

Classify email addresses

## Usage

```
use Email::Address::Classify;

my $email = Email::Address::Classify->new('a.johnson@example.com');

print "Is valid:  " . $email->is_valid() ? "Y\n" : "N\n";
print "Is random: " . $email->is_random() ? "Y\n" : "N\n";

```


