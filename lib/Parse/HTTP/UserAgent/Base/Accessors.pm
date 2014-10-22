package Parse::HTTP::UserAgent::Base::Accessors;
use strict;
use warnings;
use Parse::HTTP::UserAgent::Constants qw(:all);

our $VERSION = '0.40_01';

BEGIN {
    my @simple = qw(
        device
        generic
        lang
        mobile
        name
        original_name
        original_version
        os
        parser
        robot
        strength
        tablet
        touch
        unknown
        wap
    );

    my @multi = qw(
        mozilla
        extras
        dotnet
    );

    no strict qw(refs); ## no critic (TestingAndDebugging::ProhibitNoStrict)
    foreach my $name ( @simple ) {
        my $id = 'UA_' . uc $name;
        $id = __PACKAGE__->$id();
        *{ $name } = sub { return shift->[$id] || q{} };
    }

    foreach my $name ( @multi ) {
        my $id = 'UA_' . uc $name;
        $id = __PACKAGE__->$id();
        *{ $name } = sub {
            my $self = shift;
            return +() if ! $self->[ $id ];
            my @rv = @{ $self->[ $id ] };
            return wantarray ? @rv : $rv[0];
        };
    }
}

sub version {
    my $self = shift;
    my $type = shift || q{};
    return $self->[ $type eq 'raw' ? UA_VERSION_RAW : UA_VERSION ] || 0;
}

sub toolkit {
    my $self = shift;
    return Parse::HTTP::UserAgent::Base::Accessors::toolkit->new(
                $self->[UA_TOOLKIT]
            );
}

package
Parse::HTTP::UserAgent::Base::Accessors::toolkit;
use strict;
use warnings;
use overload '""',    => 'name',
             '0+',    => 'version',
             fallback => 1,
;
use constant ID_NAME        => 0;
use constant ID_VERSION_RAW => 1;
use constant ID_VERSION     => 2;

sub new {
    my($class, $tk) = @_;
    return bless [ $tk ? @{ $tk } : (undef) x 3 ], $class;
}

sub name {
    return shift->[ID_NAME];
}

sub version {
    my $self = shift;
    my $type = shift || q{};
    return $self->[ $type eq 'raw' ? ID_VERSION_RAW : ID_VERSION ] || 0;
}

1;

__END__

=pod

=head1 NAME

Parse::HTTP::UserAgent::Base::Accessors - Available accessors

=head1 SYNOPSIS

   use Parse::HTTP::UserAgent;
   my $ua = Parse::HTTP::UserAgent->new( $str );
   die "Unable to parse!" if $ua->unknown;
   print $ua->name;
   print $ua->version;
   print $ua->os;

=head1 DESCRIPTION

This document describes version C<0.40_01> of C<Parse::HTTP::UserAgent::Base::Accessors>
released on C<20 January 2014>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.
Ther methods can be used to access the various parts of the parsed structure.

=head1 ACCESSORS

The parts of the parsed structure can be accessed using these methods:

=head2 device

=head2 dotnet

=head2 extras

=head2 generic

=head2 lang

=head2 mobile

=head2 mozilla

=head2 name

=head2 original_name

=head2 original_version

=head2 os

=head2 parser

=head2 robot

=head2 strength

=head2 tablet

=head2 touch

=head2 toolkit

=head2 unknown

=head2 version

=head2 wap

=head1 SEE ALSO

L<Parse::HTTP::UserAgent>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 - 2014 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.
=cut
