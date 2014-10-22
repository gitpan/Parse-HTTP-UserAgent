package Parse::HTTP::UserAgent::IS;
use strict;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);

$VERSION = '0.10';

sub _is_opera_pre {
    my $self = shift;
    my $moz = shift;
    return index( $moz, "Opera") != -1;
}

sub _is_opera_post {
    my $self = shift;
    my $extra = shift;
    return $extra && $extra->[0] eq 'Opera';
}

sub _is_opera_ff { # opera faking as firefox
    my $self = shift;
    my $extra = shift;
    return $extra && @{$extra} == 4 && $extra->[2] eq 'Opera';
}

sub _is_safari {
    my $self   = shift;
    my $extra  = shift;
    my $others = shift;
    return index($self->[UA_STRING],'Chrome') == -1 && (
                    ( $extra  && index( $extra->[0], "AppleWebKit")  != -1 ) ||
                    ( @{$others} && index( $others->[-1], "Safari" ) != -1 )
                   );
}

sub _is_chrome {
    my $self   = shift;
    my $extra  = shift;
    my $others = shift;
    my $chx    = $others->[1] || return;
    my($chrome, $safari) = split m{\s}xms, $chx;
    return if ! ( $chrome && $safari);

    return index($chrome,'Chrome') != -1 &&
           index($safari,'Safari') != -1 &&
           ( $extra  && index( $extra->[0], "AppleWebKit") != -1);
}

sub _is_ff {
    my $self = shift;
    my $extra = shift;
    return $extra && $extra->[1] && (
                    ($extra->[1] eq 'Mozilla' && $extra->[2])
                        ? $extra->[2] =~ RE_FIREFOX_NAMES
                                && do { $extra->[1] = $extra->[2] }
                        : $extra->[1] =~ RE_FIREFOX_NAMES
                 );
}

sub _is_gecko {
    return index(shift->[UA_STRING], 'Gecko/') != -1;
}

sub _is_generic {
    my $self = shift;
    return 1 if $self->_generic_name_version(@_) ||
                $self->_generic_compatible(@_)   ||
                $self->_generic_moz_thing(@_);
    return;
}

sub _is_netscape {
    my $self = shift;
    my($moz, $thing, $extra, $compatible, @others) = @_;

    my $rv = index($moz, 'Mozilla/') != -1 &&
             $moz ne 'Mozilla/4.0'         &&
             ! $compatible                 &&
             ! $extra                      &&
             ! @others                     &&
             $thing->[-1] ne 'Sun'         && # hotjava
             index($thing->[0], 'http://') == -1 # robot
             ;
    return $rv;
}

sub _is_strength {
    my $self = shift;
    my $s    = shift || return;
       $s    = $self->trim( $s );
    return $s if $s eq 'U' || $s eq 'I' || $s eq 'N';
}

1;

__END__

=pod

=head1 NAME

Parse::HTTP::UserAgent::IS - Base class

=head1 DESCRIPTION

This document describes version C<0.10> of C<Parse::HTTP::UserAgent::IS>
released on C<25 August 2009>.

Internal module.

=head1 SEE ALSO

L<Parse::HTTP::UserAgent>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.10.0 or, 
at your option, any later version of Perl 5 you may have available.

=cut
