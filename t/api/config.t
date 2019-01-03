use strict;
use warnings;
use RT;

use RT::Test nodb => 1, tests => undef, config => <<'CONFIG';
Set(%PriorityAsString, Green => 1, Yellow => 50, Red => 100);
CONFIG

use Test::Warn;

ok(
    RT::Config->AddOption(
        Name    => 'foo',
        Section => 'bar',
    ),
    'added option foo'
);

my $meta = RT::Config->Meta('foo');
is( $meta->{Section}, 'bar', 'Section is bar' );
is( $meta->{Widget}, '/Widgets/Form/String', 'default Widget is string' );
is_deeply( $meta->{WidgetArguments},
    {},, 'default WidgetArguments is empty hashref' );

ok(
    RT::Config->UpdateOption(
        Name    => 'foo',
        Section => 'baz',
        Widget => '/Widgets/Form/Boolean',
    ),
    'updated option foo to section baz'
);
is( $meta->{Section}, 'baz', 'section is updated to baz' );
is( $meta->{Widget}, '/Widgets/Form/Boolean', 'widget is updated to boolean' );

ok( RT::Config->DeleteOption( Name => 'foo' ), 'removed option foo' );
is( RT::Config->Meta('foo'), undef, 'foo is indeed deleted' );

# Test EmailInputEncodings PostLoadCheck code
RT::Config->Set('EmailInputEncodings', qw(utf-8 iso-8859-1 us-ascii foo));
my @encodings = qw(utf-8-strict iso-8859-1 ascii);

warning_is {RT::Config->PostLoadCheck} "Unknown encoding 'foo' in \@EmailInputEncodings option",
  'Correct warning for encoding foo';

RT::Config->Set( WebDefaultStylesheet => 'non-existent-skin-name' );
warning_like {RT::Config->PostLoadCheck} qr{rudder},
    'Correct warning for default stylesheet';

my @canonical_encodings = RT::Config->Get('EmailInputEncodings');
is_deeply(\@encodings, \@canonical_encodings, 'Got correct encoding list');

my %PriorityAsString = RT::Config->Get('PriorityAsString');

foreach (qw/Low Medium High/) {
    is $PriorityAsString{$_}, undef , 'Does not have default config values for PriorityAsString';
}
foreach (qw/Green Yellow Red/) {
    ok $PriorityAsString{$_} ,'SiteConfig value for PriorityAsString overrode default value completly';
}

done_testing;
