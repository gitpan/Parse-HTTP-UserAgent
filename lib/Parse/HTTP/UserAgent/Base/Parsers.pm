package Parse::HTTP::UserAgent::Base::Parsers;
use strict;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);
use version;
use Carp qw(croak);

$VERSION = '0.12';

sub _extract_dotnet {
    my $self = shift;
    my @raw  = map { ref($_) eq 'ARRAY' ? @{$_} : $_ } grep { $_ } @_;
    my(@extras,@dotnet);

    foreach my $e ( @raw ) {
        if ( my @match = $e =~ RE_DOTNET ) {
            push @dotnet, $match[0];
            next;
        }
        if ( $e =~ RE_WINDOWS_OS && $1 ne '64' ) {
            $self->[UA_OS] = $e;
            next;
        }
        push @extras, $e;
    }

    return [@extras], [@dotnet];
}

sub _fix_opera {
    my $self = shift;
    return if ! $self->[UA_EXTRAS];
    my @buf;
    foreach my $e ( @{ $self->[UA_EXTRAS] } ) {
        if ( $e =~ m{ \A (Opera \s+ Mini) / (.+?) \z }xms ) {
            $self->[UA_ORIGINAL_NAME]    = $1;
            $self->[UA_ORIGINAL_VERSION] = $2;
            next;
        }
        push @buf, $e;
    }
    $self->[UA_EXTRAS] = [ @buf ];
    return;
}

sub _fix_generic {
    my($self, $os_ref, $name_ref, $v_ref, $e_ref) = @_;
    if ( $$v_ref && $$v_ref !~ m{[0-9]}xms) {
        $$name_ref .= ' ' . $$v_ref;
        $$v_ref = undef;
    }

    if ( $$os_ref && $$os_ref =~ m{ http:// }xms ) {
        $$os_ref =~ s{ \A \+ }{}xms;
        push @{ $e_ref }, $$os_ref;
        $$os_ref = undef;
    }
    return;
}

sub _parse_maxthon {
    my($self, $moz, $thing, $extra, @others) = @_;
    my @omap = grep { $_ } map { split m{;\s+?}xms, $_ } @others;
    my($maxthon, $msie);

    my @buf;
    foreach my $e ( @omap, @{$thing} ) { # $extra -> junk
        if ( index(uc $e, 'MAXTHON') != -1 ) { $maxthon = $e; next; }
        if ( index(uc $e, 'MSIE'   ) != -1 ) { $msie    = $e; next; }
        push @buf, $e;
    }

    # make this a warning after development?
    croak "Unable to extract Maxthon version from Maxthon UA-string" if ! $maxthon;
    croak "Unable to extract MSIE from Maxthon UA-string" if ! $msie;

    $self->_parse_msie($moz, [ undef, @buf ], undef, split /\s+/, $msie);

    my(undef, $mv) = split m{ \s+ }xms, $maxthon;
    $self->[UA_ORIGINAL_VERSION] = $mv || (
        $maxthon ? '1.0' : croak "Unable to extract Maxthon version?"
    );
    $self->[UA_ORIGINAL_NAME] = 'Maxthon';
    return;
}

sub _parse_msie {
    my($self, $moz, $thing, $extra, $name, $version) = @_;
    my $junk = shift @{ $thing }; # already used
    # "Microsoft Internet Explorer";

    my($extras,$dotnet) = $self->_extract_dotnet( $thing, $extra );

    if ( @{$extras} == 2 && index( $extras->[1], 'Lunascape' ) != -1 ) {
        ($name, $version) = split m{[/\s]}xms, pop @{ $extras };
    }

    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version;
    $self->[UA_DOTNET]      = [ @{ $dotnet } ] if @{$dotnet};

    if ( $extras->[0] && $extras->[0] eq 'Mac_PowerPC' ) {
        $self->[UA_OS] = shift @{ $extras };
    }

    my @buf;
    foreach my $e ( @{ $extras } ) {
        if ( $e =~ m{ \A (Trident) / (.+?) \z }xmsi ) {
            $self->[UA_TOOLKIT] = [ $1, $2 ];
            next;
        }
        push @buf, $e;
    }
    $self->[UA_EXTRAS] = [ @buf ];
    return;
}

sub _parse_firefox {
    my $self = shift;
    $self->_parse_mozilla_family( @_ );
    $self->[UA_NAME] = 'Firefox';
    return;
}

sub _parse_safari {
    my $self = shift;
    my($moz, $thing, $extra, @others) = @_;
    $self->[UA_NAME]        = 'Safari';
    my($version, @junk)     = split m{\s+}xms, pop @others;
    (undef, $version)       = split RE_SLASH, $version;
    $self->[UA_NAME]        = 'Safari';
    $self->[UA_VERSION_RAW] = $version;
    $self->[UA_TOOLKIT]     = [ split RE_SLASH, $extra->[0] ];
    $self->[UA_LANG]        = pop @{ $thing };
    $self->[UA_OS]          = length $thing->[-1] > 1 ? pop @{ $thing }
                                                      : shift @{$thing}
                            ;
    $self->[UA_DEVICE]      = shift @{$thing} if $thing->[0] eq 'iPhone';
    $self->[UA_EXTRAS]      = [ @{$thing}, @others ];

    if ( length($self->[UA_OS]) == 1 ) {
        push @{$self->[UA_EXTRAS]}, $self->[UA_EXTRAS];
        $self->[UA_OS] = undef;
    }

    push @{$self->[UA_EXTRAS]}, @junk if @junk;

    return;
}

sub _parse_chrome {
    my $self = shift;
    my($moz, $thing, $extra, @others) = @_;
    my $chx = pop @others;
    my($chrome, $safari)     = split m{\s}xms, $chx;
    push @others, $safari;
    $self->_parse_safari($moz, $thing, $extra, @others);
    my($name, $version)      = split RE_SLASH, $chrome;
    $self->[UA_NAME]         = $name;
    $self->[UA_VERSION_RAW]  = $version;
    return;
}

sub _parse_opera_pre {
    # opera 5,9
    my($self, $moz, $thing, $extra) = @_;
    my($name, $version)     = split RE_SLASH, $moz;
    my $faking_ff           = index($thing->[-1], "rv:") != -1 ? pop @{$thing} : 0;
    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version;
   ($self->[UA_LANG]        = pop @{$extra}) =~ tr/[]//d if $extra;
    $self->[UA_LANG]      ||= pop @{$thing} if $faking_ff;

    if ( version->parse($version) >= 9 && $self->[UA_LANG] && length($self->[UA_LANG]) > 5 ) {
        $self->[UA_TOOLKIT] = [ split RE_SLASH, $self->[UA_LANG] ];
       ($self->[UA_LANG]    = pop @{$thing}) =~ tr/[]//d if $extra;
    }

    $self->[UA_OS]     = $self->_is_strength($thing->[-1]) ? shift @{$thing}
                       :                                     pop   @{$thing}
                       ;

    $self->[UA_EXTRAS] = [ @{ $thing }, ( $extra ? @{$extra} : () ) ];
    return $self->_fix_opera;
}

sub _parse_opera_post {
    # opera 5,6,7
    my($self, $moz, $thing, $extra, $compatible) = @_;
    shift @{ $thing } if $compatible;
    $self->[UA_NAME]        = shift @{$extra};
    $self->[UA_VERSION_RAW] = shift @{$extra};
   ($self->[UA_LANG]        = shift @{$extra} || '') =~ tr/[]//d;
    $self->[UA_OS]          = $self->_is_strength($thing->[-1]) ? shift @{$thing}
                            :                                     pop   @{$thing}
                            ;
    $self->[UA_EXTRAS]      = [ @{ $thing }, ( $extra ? @{$extra} : () ) ];
    return $self->_fix_opera;
}

sub _parse_mozilla_family {
    my($self, $moz, $thing, $extra, @extras) = @_;
    # firefox variation or just mozilla itself
    my($name, $version)      = split RE_SLASH, defined $extra->[1] ? $extra->[1]
                             :                                       $moz
                             ;
    $self->[UA_NAME]         = $name;
    $self->[UA_TOOLKIT]      = [ split RE_SLASH, $extra->[0] ];
    $self->[UA_VERSION_RAW]  = $version;

    if ( index($thing->[-1], 'rv:') != -1 ) {
        $self->[UA_MOZILLA]  = pop @{ $thing };
        $self->[UA_LANG]     = pop @{ $thing };
        $self->[UA_OS]       = pop @{ $thing };
    }

    $self->[UA_EXTRAS] = [ @{ $thing }, @extras ];
    return;
}

sub _parse_gecko {
    my $self = shift;
    my($moz, $thing, $extra, @others) = @_;
    $self->_parse_mozilla_family($moz, $thing, $extra, @others);

    # we got some name & version
    if ( $self->[UA_NAME] && $self->[UA_VERSION_RAW] ) {
        # Change SeaMonkey too?
        my $before = $self->[UA_NAME];
        $self->[UA_NAME]   = 'Netscape' if $self->[UA_NAME] eq 'Netscape6';
        $self->[UA_NAME]   = 'Mozilla'  if $self->[UA_NAME] eq 'Beonex';
        $self->[UA_PARSER] = 'mozilla_family:generic';
        my @buf;

        foreach my $e ( @{ $self->[UA_EXTRAS] } ) {
            next if ! $e;
            if ( my $s = $self->_is_strength($e) ) {
                $self->[UA_STRENGTH] = $s;
                next;
            }
            if ( $e =~ m{ \s i\d86 }xms ) {
                my($os,$lang) = split m{[,]}xms, $e;
                $self->[UA_OS]   = $os   if $os;
                $self->[UA_LANG] = $self->trim($lang) if $lang;
                next;
            }
            if ( $e =~ m{ \A [a-z]{2} \z }xms ) {
                $self->[UA_LANG] = $e;
                next;
            }
            push @buf, $e;
        }

        $self->[UA_EXTRAS]        = [ @buf ];
        $self->[UA_ORIGINAL_NAME] = $before if $before ne $self->[UA_NAME];
        return 1 ;
    }

    if ( $self->[UA_TOOLKIT] && $self->[UA_TOOLKIT][0] eq 'Gecko' ) {
        ($self->[UA_NAME], $self->[UA_VERSION_RAW]) = split RE_SLASH, $moz;
        if ( $self->[UA_NAME] && $self->[UA_VERSION_RAW] ) {
            $self->[UA_PARSER] = 'mozilla_family:gecko';
            return 1;
        }
    }

    return;
}

sub _parse_netscape {
    my $self            = shift;
    my($moz, $thing)    = @_;
    my($mozx, $junk)    = split m{ \s+ }xms, $moz;
    my(undef, $version) = split RE_SLASH, $mozx;
    my @buf;
    foreach my $e ( @{ $thing } ) {
        if ( my $s = $self->_is_strength($e) ) {
            $self->[UA_STRENGTH] = $s;
            next;
        }
        push @buf, $e;
    }
    $self->[UA_VERSION_RAW] = $version;
    $self->[UA_OS]          = $buf[0] eq 'X11' ? pop @buf : shift @buf;
    $self->[UA_NAME]        = 'Netscape';
    $self->[UA_EXTRAS]      = [ @buf ];
    if ( $junk ) {
        $junk =~ s{ \[ (.+?) \] .* \z}{$1}xms;
        $self->[UA_LANG] = $junk if $junk;
    }
    $self->[UA_PARSER] = 'netscape';
    return 1;
}


sub _generic_moz_thing {
    my $self = shift;
    my($moz, $thing, $extra, $compatible, @others) = @_;
    return if ! @{ $thing };
    my($mname, $mversion, @remainder) = split m{[/\s]}xms, $moz;
    return if $mname eq 'Mozilla';

    $self->[UA_NAME]        = $mname;
    $self->[UA_VERSION_RAW] = $mversion || ( $mname eq 'Links' ? shift @{$thing} : 0 );
    $self->[UA_OS]          = @remainder ? join(' ', @remainder)
                            : $thing->[0] && $thing->[0] !~ m{\d+[.]?\d} ? shift @{$thing}
                            :              undef;
    my @extras = (@{$thing}, $extra ? @{$extra} : (), @others );


    $self->_fix_generic(
        \$self->[UA_OS], \$self->[UA_NAME], \$self->[UA_VERSION_RAW], \@extras
    );

    $self->[UA_EXTRAS]      = [ @extras ] if @extras;
    $self->[UA_GENERIC]     = 1;
    $self->[UA_PARSER]      = 'generic_moz_thing';

    return 1;
}

sub _generic_name_version {
    my $self = shift;
    my($moz, $thing, $extra, $compatible, @others) = @_;
    my $ok = $moz && ! @{$thing} && ! $extra && ! $compatible && ! @others;
    return if not $ok;

    my @moz = split m{\s}xms, $moz;
    if ( @moz == 1 ) {
        my($name, $version) = split RE_SLASH, $moz;
        if ($name && $version) {
            $self->[UA_NAME]        = $name;
            $self->[UA_VERSION_RAW] = $version;
            $self->[UA_GENERIC]     = 1;
            $self->[UA_PARSER]      = 'generic_name_version';
            return 1;
        }
    }
    return;
}

sub _generic_compatible {
    my $self = shift;
    my($moz, $thing, $extra, $compatible, @others) = @_;

    return if ! ( $compatible && @{$thing} );

    my($mname, $mversion) = split m{[/\s]}xms, $moz;
    my($name, $version)   = $mname eq 'Mozilla'
                          ? split( m{[/\s]}xms, shift @{ $thing } )
                          : ($mname, $mversion)
                          ;
    my $junk   = shift @{$thing}
                    if  $thing->[0] &&
                      ( $thing->[0] eq $name || $thing->[0] eq $moz);
    my $os     = shift @{$thing};
    my $lang   = pop   @{$thing};
    my @extras;

    if ( $name eq 'MSIE') {
        if ( $extra ) { # Sleipnir?
            ($name, $version) = split RE_SLASH, pop @{$extra};
            my($extras,$dotnet) = $self->_extract_dotnet( $thing, $extra );
            $self->[UA_DOTNET] = [ @{$dotnet} ] if @{$dotnet};
            @extras = (@{ $extras }, @others);
        }
        else {
            return if index($moz, ' ') != -1; # WebTV
        }
    }

    @extras = (@{$thing}, $extra ? @{$extra} : (), @others ) if ! @extras;

    $self->_fix_generic( \$os, \$name, \$version, \@extras );

    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version || 0;
    $self->[UA_OS]          = $os;
    $self->[UA_LANG]        = $lang;
    $self->[UA_EXTRAS]      = [ @extras ] if @extras;
    $self->[UA_GENERIC]     = 1;
    $self->[UA_PARSER]      = 'generic_compatible';

    return 1;
}

1;

__END__

=pod

=head1 NAME

Parse::HTTP::UserAgent::Parsers - Base class

=head1 DESCRIPTION

This document describes version C<0.12> of C<Parse::HTTP::UserAgent::Base::Parsers>
released on C<27 August 2009>.

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
