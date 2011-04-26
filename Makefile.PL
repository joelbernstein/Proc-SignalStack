use inc::Module::Install;

# Define metadata
name           'Proc-SignalStack';
all_from       'lib/Proc/SignalStack.pm';

# Specific dependencies
requires 'strictures';
requires 'true';
requires 'English';
requires 'Lingua::EN::Numbers::Ordinate';

test_requires  'Test::More';
test_requires  'Test::Exception';

WriteAll;
