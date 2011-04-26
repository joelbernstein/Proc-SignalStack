#!perl -T

use Test::More;

plan skip_all => "Set TEST_POD_COVERAGE=1 to run Pod::Coverage tests"
	unless $ENV{TEST_POD_COVERAGE};

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
