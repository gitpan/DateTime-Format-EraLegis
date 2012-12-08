
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "DateTime formatter for Era Legis (http://oto-usa.org/calendar.html)",
  "AUTHOR" => "Clay Fouts <cfouts\@khephera.net>",
  "BUILD_REQUIRES" => {
    "DateTime" => 0,
    "DateTime::Format::ISO8601" => 0,
    "Encode" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DateTime-Format-EraLegis",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DateTime::Format::EraLegis",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DBI" => 0,
    "JSON" => 0,
    "Method::Signatures" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Attribute::Chained" => 0,
    "Roman::Unicode" => 0,
    "utf8" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);


