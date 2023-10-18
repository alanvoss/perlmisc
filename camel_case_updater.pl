#! /usr/bin/env perl

use strict;
use warnings;

# iterate through all file arguments passed on the command line to the script
# something like `find * -name '*.go' | xargs ./camel_case_updater.pl`
my @input_files = @ARGV;
for my $file_name (@input_files) {
  my $fh;
  my @toupdate;
  chomp $file_name;
  open $fh, '+<', $file_name or die "could not open $file_name: $!";

  # find all snake_cased imports, and manufacture their camelCased equivalent
  for my $line (<$fh>) {
    my ($snake_cased) = $line =~ m#^\s*(\w+_\w+)\s+"[^"]+"\s*#;
    next unless $snake_cased;
    my @snake_parts = split(/_/, $snake_cased);
    @snake_parts[1..$#snake_parts] = map { ucfirst($_) } @snake_parts[1..$#snake_parts];
    my $camelCase = join "", @snake_parts;
    push @toupdate, [$snake_cased, $camelCase]
  }

  # iterate through all the found snake_cased imports, and do a wholesale replacement in the entire
  # file with the camelCased equivalents.
  seek($fh,0,0) or die "Seeking: $!";
  local $/;
  my $slurp = <>;
  for my $update (@toupdate) {
    my ($snake, $camel) = @$update;
    if ($slurp =~ /\b$camel\b/) {
      print "Alert: $file_name already has a reference to a $camel!!!!  Skipping changing $snake for $file_name.\n";
      next;
    }
    print "snake $snake will become -> $camel\n";
    $slurp =~ s/$snake/$camel/g;
  }

  # write the recently replaced camelCased version of the file back to disk.
  seek($fh,0,0) or die "Seeking: $!";;
  print $fh $slurp or die "Printing: $!";
  truncate($fh,tell($fh)) or die "Truncating: $!";
  close($fh) or die "Closing: $!";
}
