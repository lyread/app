#!/usr/bin/perl

open (FILE,$ARGV[0]) or die "File not found";

while (<FILE>) {
	s/[\x80-\xff]/"&#".ord($&).";"/ge;
	print $_;
}
