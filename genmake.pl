#!/usr/bin/perl -W
#
# genmake.pl written by Ramo
#
# ------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <ramo@goodvikings.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return - Ramo
# ------------------------------------------------------------------------------
#
# In it's current state, extra libs need to be added to the sub for generating
# the lib hash for the linker options.
# Also, if you want to change the compiler and flags you will need to do that
# manually here by altering the $output variable (say change to clang++ for C++
# compilation)

use strict;
use warnings;

my $prog = "prog";
my $output="# Makefile generated by genmake.pl\n# Written by Ramo\n\n";

$output .= "CC=" . (shift || 'gcc') . "\n";
$output .= "BUILD=build\n";
$output .= "DIST=dist\n";
$output .= "OUTPUT=prog\n";
$output .= "CCFLAGS=-c -g -Wall -ansi\n";
$output .= "LDFLAGS=-o \$(DIST)/\$(OUTPUT) PLACEHOLDER\n\n";
$output .= "all:\t\$(DIST)/\$(OUTPUT)\n";

my $dir = "";
my @cFiles;
my @oFiles;
my $links = "";
my %linksHash = genLinksHash();

if ($#ARGV == -1) {
	$dir = "./";
} else {
	$dir = $ARGV[0];
}

opendir(DIR, $dir) or die $!;

while (my $file = readdir(DIR)) {
	next unless (-f "$dir/$file");
	next unless ($file =~ m/\.(c|cpp)$/);

	push(@cFiles, $file);
	
	my $bar = $file;
	$bar =~ s/\.(c|cpp)$/.o/;

	push(@oFiles, $bar);
}

closedir(DIR);

my $derp;
open my $fh, '>', \$derp or die $!;
print $fh map { "\$(BUILD)/" . $_ . " " } @oFiles;

#$output .= "\$(DIST)/$prog:\t\$(DIR) \$(DIST) $derp\n\t\$(CC) \$(DIR)/" . join(" \$(DIR)/", @oFiles) . " \$(LDFLAGS)\n";
$output .= "\$(DIST)/\$(OUTPUT):\t\$(BUILD) \$(DIST) $derp\n\t\$(CC) \$(BUILD)/*.o \$(LDFLAGS)\n";

foreach my $file (@cFiles) {
	open(FILE, $dir . $file) or die $!;	
	my @lines = <FILE>;
	my @headers;
	
	foreach (@lines) {
		if ($_ =~ m/^#include "/) {
			chomp($_);
			my $include = $_;
			$include =~ s/^#include "//;
			$include =~ s/"$//;
			
			push(@headers, $include);
		}
		if ($_ =~ m/^#include </) {
			chomp($_);
			my $include = $_;
			$include =~ s/^#include <//;
			$include =~ s/>$//;
			$include =~ s/\/.+$//;

			next unless exists $linksHash{$include};

			my $linkOption = $linksHash{$include};
			my $searchString = quotemeta($linkOption);

			if (!($links =~ m/$searchString/)) {
				$links .= "$linkOption ";
			}
		}
	}

	my $object = $file;
	$object =~ s/\.(c|cpp)$/.o/;
	$output .= "\$(BUILD)/$object:\t$file @headers\n\t\$(CC) $file \$(CCFLAGS) -o \$(BUILD)/$object\n";
	
	close(FILE);
}

$output =~ s/PLACEHOLDER/$links/;
$output .= "\$(BUILD):\n\t\@mkdir \$(BUILD)\n\$(DIST):\n\t\@mkdir \$(DIST)\nclean:\n\trm -rf \$(BUILD) \$(DIST); clear\ninstall:\n\tinstall \$(DIST)/\$(OUTPUT) /usr/local/bin/\nlove:\n\t\@echo Not war\n";

print($output);

exit 0;

sub genLinksHash {
	return (
		"pthread.h" => "-lpthread",
		"libtasn1.h" => "-ltasn1",
		"openssl" => "-lssl -lcrypto",
		"mysql" => "`mysql_config --libs`",
		"math.h" => "-lm",
		"cmath" => "-lm",
		"curl" => "-lcurl",
		"sqlite3.h" => "-lsqlite3",
		"mpd" => "-lmpdclient"
	);
}
