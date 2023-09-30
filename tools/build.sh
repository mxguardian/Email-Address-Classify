#!/usr/bin/env bash
# Update the README.md file
pod2markdown lib/Email/Address/Classify.pm >README.md
pod2markdown tools/ngrams.pl >tools/README.md
# Run the tests
prove -l t/*.t
# Build the distribution
perl Makefile.PL
make manifest
make
make dist
# Clean up
make clean
rm -f MANIFEST *.old *.bak
echo "Build complete. Upload to CPAN with:"
echo "  cpan-upload -u USERNAME Email-Address-Classify-VERSION.tar.gz"
