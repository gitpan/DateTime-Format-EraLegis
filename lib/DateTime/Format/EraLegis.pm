package DateTime::Format::EraLegis;
{
  $DateTime::Format::EraLegis::VERSION = '0.001';
}

# ABSTRACT: DateTime formatter for Era Legis (http://oto-usa.org/calendar.html)

use 5.010;
use Moose;
use MooseX::Attribute::Chained;
use JSON;
use Method::Signatures;

has 'format' => (
    traits => ['Chained'],
    is => 'rw',
    isa => 'Str',
    default => '',
    );

has 'ephem' => (
    is => 'ro',
    isa => 'DateTime::Format::EraLegis::Ephem',
    lazy_build => 1,
    );

has 'style' => (
    is => 'rw',
    isa => 'DateTime::Format::EraLegis::Style',
    lazy_build => 1,
    );

method _build_ephem {
    return DateTime::Format::EraLegis::Ephem->new();
}

method _build_style {
    return DateTime::Format::EraLegis::Style->new();
}


method format_datetime(DateTime $dt) {
    $dt = $dt->clone;

    ### Day of week should match existing time zone
    my $dow = $dt->day_of_week;

    ### But pull ephemeris data based on UTC
    $dt->set_time_zone('UTC');

    my %tdate = (
        evdate => $dt->ymd . ' ' . $dt->hms,
        year => [ int(($dt->year - 1904)/22), ($dt->year - 1904)%22 ],
        dow => $dow,
        );

    for ( qw(sol luna) ) {
        my $deg = $self->ephem->lookup( $_, $dt );
        $tdate{$_}{sign} = int($deg / 30);
        $tdate{$_}{deg} = $deg % 30;
    }

    $tdate{plain} = $self->style->express( \%tdate );

    if ($self->format eq 'json') {
        return JSON->new->pretty->encode(\%tdate);
    }
    elsif ($self->format eq 'raw') {
        return \%tdate;
    }
    else {
        return $tdate{plain};
    }
}


__PACKAGE__->meta->make_immutable;
no Moose;

######################################################
package DateTime::Format::EraLegis::Ephem;
{
  $DateTime::Format::EraLegis::Ephem::VERSION = '0.001';
}

use 5.010;
use Moose;
use Carp;
use DBI;
use Method::Signatures;

has 'ephem_db' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
    );

has 'dbh' => (
    is => 'ro',
    isa => 'DBI::db',
    lazy_build => 1,
    );

method _build_ephem_db {
    return $ENV{ERALEGIS_EPHEMDB}
        // croak 'No ephemeris database defined';
}

method _build_dbh {
    return DBI->connect( 'dbi:SQLite:dbname='.$self->ephem_db );
}

method lookup(Str $body, DateTime $dt) {
    my $time = $dt->ymd . ' ' . $dt->hms;
    croak 'Date is before era legis' if $time lt '1904-03-20';
    my $rows = $self->dbh->selectcol_arrayref(
        q{SELECT degree FROM ephem
          WHERE body = ? AND time < ?
          ORDER BY time DESC LIMIT 1},
        undef, $body, $time );
    croak "Cannot find date entry for $time." unless $rows;

    return $rows->[0];
}

__PACKAGE__->meta->make_immutable;
no Moose;

######################################################

package DateTime::Format::EraLegis::Style;
{
  $DateTime::Format::EraLegis::Style::VERSION = '0.001';
}

use 5.010;
use Moose;
use utf8;
use Roman::Unicode qw(to_roman);
use Moose::Util::TypeConstraints;
use Method::Signatures;

enum 'Language', [qw( latin symbol english poor-latin )];

has 'lang' => (
    is => 'ro',
    isa => 'Language',
    default => 'latin',
    required => 1,
    );

has 'dow' => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
    );

has 'signs' => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
    );

has 'years' => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
    );

has 'show_terse' => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    );

has [ qw( show_deg show_dow show_year roman_year ) ] => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
    );

has 'template' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
    );

method _build_dow {
    return
        ($self->lang eq 'symbol')
        ? [qw( ☉ ☽ ♂ ☿ ♃ ♀ ♄ ☉ )]
        : ($self->lang eq 'english')
        ? [qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday Sunday)]
        : [qw(Solis Lunae Martis Mercurii Iovis Veneris Saturni Solis)];
}

method _build_signs {
    return [qw( ♈ ♉ ♊ ♋ ♌ ♍ ♎ ♏ ♐ ♑ ♒ ♓ )]
        if $self->lang eq 'symbol';

    return [qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces)]
        if $self->lang eq 'english';

    return [qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces)]
        if $self->lang eq 'poor-latin';

    return [qw(Arietis Tauri Geminorum Cancri Leonis Virginis Librae Scorpii Sagittarii Capricorni Aquarii Piscis)]
        if $self->lang eq 'latin' && $self->show_deg;

    return [qw(Ariete Tauro Geminis Cancro Leone Virginie Libra Scorpio Sagittario Capricorno Aquario Pisci)];
}

method _build_years {
    return
        ($self->roman_year)
        ? [ 0, map { to_roman($_) } 1..21 ]
        : [ 0..21 ];
}

method _build_template {
    my $template = '';
    if ($self->show_deg) {
        $template = '☉ in {sdeg}° {ssign} : ☽ in {ldeg}° {lsign}';
    }
    else {
        $template = '☉ in {ssign} : ☽ in {lsign}';
    }
    if ($self->show_terse) {
        $template =~ s/ in / /g;
    }
    if ($self->show_dow) {
        $template .= ' : ';
        $template .= ($self->lang eq 'latin')
            ? 'dies '
            : '';
        $template .= '{dow}';
    }
    if ($self->show_year) {
        $template .= ' : ';
        $template .= ($self->lang eq 'symbol')
            ? '{year1}{year2}'
            : ($self->lang eq 'english')
            ? 'Year {year1}.{year2} of the New Aeon'
            : 'Anno {year1}{year2} æræ legis';
    }

    return $template;
}

method express( HashRef $tdate ) {
    my $datestr = $self->template;

    $datestr =~ s/{sdeg}/$tdate->{sol}{deg}/ge;
    $datestr =~ s/{ssign}/$self->signs->[$tdate->{sol}{sign}]/ge;
    $datestr =~ s/{ldeg}/$tdate->{luna}{deg}/ge;
    $datestr =~ s/{lsign}/$self->signs->[$tdate->{luna}{sign}]/ge;
    $datestr =~ s/{dow}/$self->dow->[$tdate->{dow}]/ge;
    $datestr =~ s/{year1}/$self->years->[$tdate->{year}[0]]/ge;
    $datestr =~ s/{year2}/lc($self->years->[$tdate->{year}[1]])/ge;

    return $datestr;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
