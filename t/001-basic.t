#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Encode qw(encode_utf8);
use DateTime;
use DateTime::Format::ISO8601;
use DBD::SQLite;

BEGIN {
    use_ok('DateTime::Format::EraLegis');
}

binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my $ephem = DateTime::Format::EraLegis::Ephem->new(
    ephem_db => './t/test.sqlite3' );

my $dtf;
$dtf = DateTime::Format::EraLegis->new(
    ephem => $ephem,
    style => DateTime::Format::EraLegis::Style->new(lang=>'symbol'),
);
is scalar @{$dtf->style->signs}, 12, 'Have twelve signs';

my $tstamp = '2012-12-03T23:00:00';

my $iso = DateTime::Format::ISO8601->new;
my $dt = $iso->parse_datetime($tstamp);
$dt->set_formatter( $dtf );
my $out = ''.$dt;
is $out, '☉ in 12° ♐ : ☽ in 10° ♌ : ☽ : ⅠⅤⅹⅹ',
    'Basic rendering';

$dtf = DateTime::Format::EraLegis->new(
    ephem => $ephem,
    style => DateTime::Format::EraLegis::Style->new(
        lang=>'latin', show_dow=>0, show_year=>1) );
is $dtf->format_datetime($dt),
    '☉ in 12° Sagittarii : ☽ in 10° Leonis : Anno ⅠⅤⅹⅹ æræ legis',
    'Basic rendering';

$dtf = DateTime::Format::EraLegis->new(
    ephem => $ephem,
    style => DateTime::Format::EraLegis::Style->new(
        lang=>'latin', show_terse=>1, show_dow=>1, show_year=>0) );
is $dtf->format_datetime($dt),
    '☉ 12° Sagittarii : ☽ 10° Leonis : dies Lunae',
    'Basic rendering';

done_testing;
