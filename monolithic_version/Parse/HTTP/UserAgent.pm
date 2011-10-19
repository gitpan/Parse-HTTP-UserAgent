BEGIN { $INC{$_} = 1 for qw(Parse/HTTP/UserAgent.pm Parse/HTTP/UserAgent/Base/Accessors.pm Parse/HTTP/UserAgent/Base/Dumper.pm Parse/HTTP/UserAgent/Base/IS.pm Parse/HTTP/UserAgent/Base/Parsers.pm Parse/HTTP/UserAgent/Constants.pm); }
package Parse::HTTP::UserAgent;
sub ________monolith {}
package Parse::HTTP::UserAgent::Base::Accessors;
sub ________monolith {}
package Parse::HTTP::UserAgent::Base::Dumper;
sub ________monolith {}
package Parse::HTTP::UserAgent::Base::IS;
sub ________monolith {}
package Parse::HTTP::UserAgent::Base::Parsers;
sub ________monolith {}
package Parse::HTTP::UserAgent::Constants;
sub ________monolith {}
package Parse::HTTP::UserAgent::Constants;
use strict;
use warnings;
use vars qw( $VERSION $OID @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

$VERSION = '0.21';

use constant MINUS_ONE           => -1;
use constant NO_IMATCH           => -1; # for index()
use constant LAST_ELEMENT        => -1;

BEGIN { $OID = MINUS_ONE }

use constant UA_STRING           => ++$OID; # just for information
use constant UA_UNKNOWN          => ++$OID; # failed to detect?
use constant UA_GENERIC          => ++$OID; # parsed with a generic parser.
use constant UA_NAME             => ++$OID; # The identifier of the ua
use constant UA_VERSION_RAW      => ++$OID; # the parsed version
use constant UA_VERSION          => ++$OID; # used for numerical ops. via qv()
use constant UA_OS               => ++$OID; # Operating system
use constant UA_LANG             => ++$OID; # the language of the ua interface
use constant UA_TOOLKIT          => ++$OID; # [Opera] ua toolkit
use constant UA_EXTRAS           => ++$OID; # Extra stuff (Toolbars?) non parsable junk
use constant UA_DOTNET           => ++$OID; # [MSIE] List of .NET CLR versions
use constant UA_STRENGTH         => ++$OID; # [MSIE] List of .NET CLR versions
use constant UA_MOZILLA          => ++$OID; # [Firefox] Mozilla revision
use constant UA_ROBOT            => ++$OID; # Is this a robot?
use constant UA_WAP              => ++$OID; # unimplemented
use constant UA_MOBILE           => ++$OID; # unimplemented
use constant UA_PARSER           => ++$OID; # the parser name
use constant UA_DEVICE           => ++$OID; # the name of the mobile device
use constant UA_ORIGINAL_NAME    => ++$OID; # original name if this is some variation
use constant UA_ORIGINAL_VERSION => ++$OID; # original version if this is some variation
use constant IS_PARSED           => ++$OID; # _parse() happened or not
use constant IS_MAXTHON          => ++$OID; # Is this the dumb IE faker?
use constant IS_EXTENDED         => ++$OID;
use constant MAXID               =>   $OID;

use constant TK_NAME             => 0;
use constant TK_ORIGINAL_VERSION => 1;
use constant TK_VERSION          => 2;

use constant INSIDE_UNIT_TEST    => $ENV{PARSE_HTTP_USERAGENT_TEST_SUITE};
use constant INSIDE_VERBOSE_TEST => INSIDE_UNIT_TEST && $ENV{HARNESS_IS_VERBOSE};
use constant RE_FIREFOX_NAMES    => qr{Firefox|Iceweasel|Firebird|Phoenix }xms;
use constant RE_DOTNET           => qr{ \A [.]NET \s+ CLR \s+ (.+?) \z    }xms;
use constant RE_WINDOWS_OS       => qr{ \A Win(dows|NT|[0-9]+)?           }xmsi;
use constant RE_SLASH            => qr{ /                                 }xms;
use constant RE_SPLIT_PARSE      => qr{ \s? [()] \s?                      }xms;
use constant RE_OPERA_MINI       => qr{ \A (Opera \s+ Mini) / (.+?) \z    }xms;
use constant RE_TRIDENT          => qr{ \A (Trident) / (.+?) \z           }xmsi;
use constant RE_EPIPHANY_GECKO   => qr{ \A (Epiphany) / (.+?) \z          }xmsi;
use constant RE_WHITESPACE       => qr{ \s+ }xms;
use constant RE_SC_WS            => qr{;\s?}xms;
use constant RE_SC_WS_MULTI      => qr{;\s+?}xms;
use constant RE_HTTP             => qr{ http:// }xms;
use constant RE_DIGIT            => qr{[0-9]}xms;
use constant RE_IX86             => qr{ \s i\d86 }xms;
use constant RE_OBJECT_ID        => qr{ \A UA_ }xms;
use constant RE_CHAR_SLASH_WS    => qr{[/\s]}xms;
use constant RE_COMMA            => qr{ [,] }xms;
use constant RE_TWO_LETTER_LANG  => qr{ \A [a-z]{2} \z }xms;
use constant RE_DIGIT_DOT_DIGIT  => qr{\d+[.]?\d}xms;

use constant RE_WARN_OVERFLOW => qr{\QInteger overflow in version\E}xms;
use constant RE_WARN_INVALID  => qr{\QVersion string .+? contains invalid data; ignoring:\E}xms;

use constant LIST_ROBOTS         => qw(
    Wget
    curl
    libwww-perl
    GetRight
    Googlebot
    Baiduspider+
    msnbot
    bingbot
), 'Yahoo! Slurp';

use base qw( Exporter );

BEGIN {
    %EXPORT_TAGS = (
        object_ids => [qw(
            IS_PARSED
            IS_MAXTHON
            IS_EXTENDED
            UA_STRING
            UA_UNKNOWN
            UA_GENERIC
            UA_NAME
            UA_VERSION_RAW
            UA_VERSION
            UA_OS
            UA_LANG
            UA_TOOLKIT
            UA_EXTRAS
            UA_DOTNET
            UA_MOZILLA
            UA_STRENGTH
            UA_ROBOT
            UA_WAP
            UA_MOBILE
            UA_PARSER
            UA_DEVICE
            UA_ORIGINAL_NAME
            UA_ORIGINAL_VERSION
            MAXID
        )],
        re => [qw(
            RE_FIREFOX_NAMES
            RE_DOTNET
            RE_WINDOWS_OS
            RE_SLASH
            RE_SPLIT_PARSE
            RE_OPERA_MINI
            RE_TRIDENT
            RE_EPIPHANY_GECKO
            RE_WHITESPACE
            RE_SC_WS
            RE_SC_WS_MULTI
            RE_HTTP
            RE_DIGIT
            RE_IX86
            RE_OBJECT_ID
            RE_CHAR_SLASH_WS
            RE_COMMA
            RE_TWO_LETTER_LANG
            RE_DIGIT_DOT_DIGIT
            RE_WARN_OVERFLOW
            RE_WARN_INVALID
        )],
        list => [qw(
            LIST_ROBOTS
        )],
        tk => [qw(
            TK_NAME
            TK_ORIGINAL_VERSION
            TK_VERSION
        )],
        etc => [qw(
            NO_IMATCH
            LAST_ELEMENT
            INSIDE_UNIT_TEST
            INSIDE_VERBOSE_TEST
        )],
    );

    @EXPORT_OK        = map { @{ $_ } } values %EXPORT_TAGS;
    $EXPORT_TAGS{all} = [ @EXPORT_OK ];
}

package Parse::HTTP::UserAgent::Base::Parsers;
use strict;
use warnings;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);
use constant ERROR_MAXTHON_VERSION => 'Unable to extract Maxthon version from Maxthon UA-string';
use constant ERROR_MAXTHON_MSIE    => 'Unable to extract MSIE from Maxthon UA-string';
use constant OPERA9                => 9;
use constant OPERA_TK_LENGTH       => 5;

$VERSION = '0.21';

sub _extract_dotnet {
    my($self, @args) = @_;
    my @raw  = map { ref($_) eq 'ARRAY' ? @{$_} : $_ } grep { $_ } @args;
    my(@extras,@dotnet);

    foreach my $e ( @raw ) {
        if ( my @match = $e =~ RE_DOTNET ) {
            push @dotnet, $match[0];
            next;
        }
        if ( $e =~ RE_WINDOWS_OS ) {
            if ( $1 && $1 ne '64' ) {
                $self->[UA_OS] = $e;
                next;
            }
        }
        push @extras, $e;
    }

    return [@extras], [@dotnet];
}

sub _fix_opera {
    my $self = shift;
    return 1 if ! $self->[UA_EXTRAS];
    my @buf;
    foreach my $e ( @{ $self->[UA_EXTRAS] } ) {
        if ( $e =~ RE_OPERA_MINI ) {
            $self->[UA_ORIGINAL_NAME]    = $1;
            $self->[UA_ORIGINAL_VERSION] = $2;
            $self->[UA_MOBILE]           = 1;
            next;
        }
        push @buf, $e;
    }
    $self->_fix_os_lang;
    $self->_fix_windows_nt('skip_os');
    $self->[UA_EXTRAS] = [ @buf ];
    return 1;
}

sub _fix_generic {
    my($self, $os_ref, $name_ref, $v_ref, $e_ref) = @_;
    if ( ${$v_ref} && ${$v_ref} !~ RE_DIGIT) {
        ${$name_ref} .= q{ } . ${$v_ref};
        ${$v_ref}     = undef;
    }

    if ( ${$os_ref} && ${$os_ref} =~ RE_HTTP ) {
        ${$os_ref} =~ s{ \A \+ }{}xms;
        push @{ $e_ref }, ${$os_ref};
        ${$os_ref} = undef;
    }
    return;
}

sub _parse_maxthon {
    my($self, $moz, $thing, $extra, @others) = @_;
    my @omap = grep { $_ } map { split RE_SC_WS_MULTI, $_ } @others;
    my($maxthon, $msie, @buf);
    foreach my $e ( @omap, @{$thing} ) { # $extra -> junk
        if ( index(uc $e, 'MAXTHON') != NO_IMATCH ) { $maxthon = $e; next; }
        if ( index(uc $e, 'MSIE'   ) != NO_IMATCH ) { $msie    = $e; next; }
        push @buf, $e;
    }

    if ( ! $maxthon ) {
        warn ERROR_MAXTHON_VERSION . "\n";
        $self->[UA_UNKNOWN] = 1;
        return;
    }

    if ( ! $msie ) {
        warn ERROR_MAXTHON_MSIE . "\n";
        $self->[UA_UNKNOWN] = 1;
        return;
    }

    $self->_parse_msie(
        $moz, [ undef, @buf ], undef, split RE_WHITESPACE, $msie
    );

    my(undef, $mv) = split RE_WHITESPACE, $maxthon;
    my $v = $mv      ? $mv
          : $maxthon ? '1.0'
          :            do { warn ERROR_MAXTHON_VERSION . "\n"; 0 }
          ;

    $self->[UA_ORIGINAL_VERSION] = $v;
    $self->[UA_ORIGINAL_NAME]    = 'Maxthon';
    return 1;
}

sub _parse_msie {
    my($self, $moz, $thing, $extra, $name, $version) = @_;
    my $junk = shift @{ $thing }; # already used
    my($extras,$dotnet) = $self->_extract_dotnet( $thing, $extra );

    if ( @{$extras} == 2 && index( $extras->[1], 'Lunascape' ) != NO_IMATCH ) {
        ($name, $version) = split RE_CHAR_SLASH_WS, pop @{ $extras };
    }

    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version;
    $self->[UA_DOTNET]      = [ @{ $dotnet } ] if @{$dotnet};

    if ( $extras->[0] && $extras->[0] eq 'Mac_PowerPC' ) {
        $self->[UA_OS] = shift @{ $extras };
    }

    my @buf;
    foreach my $e ( @{ $extras } ) {
        if ( $e =~ RE_TRIDENT ) {
            $self->[UA_TOOLKIT] = [ $1, $2 ];
            next;
        }
        push @buf, $e;
    }
    $self->[UA_EXTRAS] = [ @buf ];
    $self->[UA_PARSER] = 'msie';
    return 1;
}

sub _parse_firefox {
    my($self, @args) = @_;
    $self->_parse_mozilla_family( @args );
    $self->[UA_NAME] = 'Firefox';
    return 1;
}

sub _parse_safari {
    my($self, $moz, $thing, $extra, @others) = @_;
    my($version, @junk)     = split RE_WHITESPACE, pop @others;
    my $ep = $version && index( lc($version), 'epiphany' ) != NO_IMATCH;
    (undef, $version)       = split RE_SLASH, $version;
    $self->[UA_NAME]        = $ep ? 'Epiphany' : 'Safari';
    $self->[UA_VERSION_RAW] = $version;
    $self->[UA_TOOLKIT]     = $extra ? [ split RE_SLASH, $extra->[0] ] : [];
    $self->[UA_LANG]        = pop @{ $thing };
    $self->[UA_OS]          = @{$thing} && length $thing->[LAST_ELEMENT] > 1
                            ? pop   @{ $thing }
                            : shift @{ $thing }
                            ;
    if ( $thing->[0] && $thing->[0] eq 'iPhone' ) {
        $self->[UA_DEVICE]  = shift @{$thing};
    }
    $self->[UA_EXTRAS]      = [ @{$thing}, @others ];

    if ( length($self->[UA_OS]) == 1 ) {
        push @{$self->[UA_EXTRAS]}, $self->[UA_EXTRAS];
        $self->[UA_OS] = undef;
    }

    push @{$self->[UA_EXTRAS]}, @junk if @junk;

    return 1;
}

sub _parse_chrome {
    my($self, $moz, $thing, $extra, @others) = @_;
    my $chx                  = pop @others;
    my($chrome, $safari)     = split RE_WHITESPACE, $chx;
    push @others, $safari;
    $self->_parse_safari($moz, $thing, $extra, @others);
    my($name, $version)      = split RE_SLASH, $chrome;
    $self->[UA_NAME]         = $name;
    $self->[UA_VERSION_RAW]  = $version;
    return 1;
}

sub _parse_opera_pre {
    # opera 5,9
    my($self, $moz, $thing, $extra) = @_;
    my $ffaker = @{$thing} && index($thing->[LAST_ELEMENT], 'rv:') != NO_IMATCH
               ? pop @{$thing}
               : 0;
    my($name, $version)     = split RE_SLASH, $moz;
    return if $name ne 'Opera';
    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version;
    my $lang;

    if ( $extra ) {
        # opera changed version string to workaround lame browser sniffers
        # http://dev.opera.com/articles/view/opera-ua-string-changes/
        my $swap = @{$extra}
                   && index($extra->[LAST_ELEMENT], 'Version/') != NO_IMATCH;
        ($lang = $swap ? shift @{$extra} : pop @{$extra}) =~ tr/[]//d;
        if ( $swap ) {
            my $vjunk = pop @{$extra};
            $self->[UA_VERSION_RAW] = ( split RE_SLASH, $vjunk )[1] if $vjunk;
        }
    }

    $lang ||= pop @{$thing} if $ffaker;

    my $tk_parsed_as_lang = ! $self->[UA_TOOLKIT]
                            && $self->_numify( $version ) >= OPERA9
                            && $lang
                            && length( $lang ) > OPERA_TK_LENGTH;

    if ( $tk_parsed_as_lang ) {
        $self->[UA_TOOLKIT] = [ split RE_SLASH, $lang ];
       ($lang = pop @{$thing}) =~ tr/[]//d if $extra;
    }

    $self->[UA_LANG] = $lang;
    $self->[UA_OS]   = @{$thing} && $self->_is_strength( $thing->[LAST_ELEMENT] )
                     ? shift @{$thing}
                     : pop   @{$thing}
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
   ($self->[UA_LANG]        = shift @{$extra} || q{}) =~ tr/[]//d;
    $self->[UA_OS]          = @{$thing} && $self->_is_strength($thing->[LAST_ELEMENT])
                            ? shift @{$thing}
                            : pop   @{$thing}
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
    $self->[UA_TOOLKIT]      = $extra ? [ split RE_SLASH, $extra->[0] ] : [];
    $self->[UA_VERSION_RAW]  = $version;

    if ( @{$thing} && index($thing->[LAST_ELEMENT], 'rv:') != NO_IMATCH ) {
        $self->[UA_MOZILLA]  = pop @{ $thing };
        $self->[UA_LANG]     = pop @{ $thing };
        $self->[UA_OS]       = pop @{ $thing };
    }

    $self->[UA_EXTRAS] = [ @{ $thing }, @extras ];
    return 1;
}

sub _parse_gecko {
    my($self, $moz, $thing, $extra, @others) = @_;
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
            if ( $e =~ RE_IX86 ) {
                my($os,$lang) = split RE_COMMA, $e;
                $self->[UA_OS]   = $os   if $os;
                $self->[UA_LANG] = $self->trim($lang) if $lang;
                next;
            }
            if ( ! $self->[UA_OS] && $e =~ m{ Win(?:NT|dows) }xmsi ) {
                $self->[UA_OS] = $e;
                next;
            }
            if ( $e =~ RE_TWO_LETTER_LANG ) {
                $self->[UA_LANG] = $e;
                next;
            }
            if ( $e =~ RE_EPIPHANY_GECKO ) {
                $self->[UA_NAME]        = $before = $1;
                $self->[UA_VERSION_RAW] = $2;
            }
            push @buf, $e;
        }

        $self->[UA_EXTRAS]        = [ @buf ];
        $self->[UA_ORIGINAL_NAME] = $before if $before ne $self->[UA_NAME];
        $self->_fix_windows_nt;
        return 1 ;
    }

    if ( $self->[UA_TOOLKIT] && $self->[UA_TOOLKIT][TK_NAME] eq 'Gecko' ) {
        ($self->[UA_NAME], $self->[UA_VERSION_RAW]) = split RE_SLASH, $moz;
        if ( $self->[UA_NAME] && $self->[UA_VERSION_RAW] ) {
            $self->[UA_PARSER] = 'mozilla_family:gecko';
            return 1;
        }
    }

    return;
}

sub _fix_os_lang {
    my $self = shift;
    if ( $self->[UA_OS] && length $self->[UA_OS] == 2 ) {
        $self->[UA_LANG] = $self->[UA_OS];
        $self->[UA_OS]   = undef;
    }
    return;
}

sub _fix_windows_nt {
    my $self    = shift;
    my $skip_os = shift; # ie os can be undef
    my $os      = $self->[UA_OS] || q{};
    return if ( ! $os              && ! $skip_os )
        ||    (   $os ne 'windows' && ! $skip_os )
        ||      ! $self->[UA_EXTRAS][0]
        ||        $self->[UA_EXTRAS][0] !~ m{ NT\s?(\d.*?) \z }xmsi;
    $self->[UA_EXTRAS][0] = $self->[UA_OS]; # restore
    $self->[UA_OS] = "Windows NT $1"; # fix
    return;
}

sub _parse_netscape {
    my($self, $moz, $thing) = @_;
    my($mozx, $junk)    = split RE_WHITESPACE, $moz;
    my(undef, $version) = split RE_SLASH     , $mozx;
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
    my($self, $moz, $t, $extra, $compatible, @others) = @_;
    return if ! @{ $t };
    my($mname, $mversion, @rest) = split RE_CHAR_SLASH_WS, $moz;
    return if $mname eq 'Mozilla' || $mname eq 'Emacs-W3';

    $self->[UA_NAME]        = $mname;
    $self->[UA_VERSION_RAW] = $mversion || ( $mname eq 'Links' ? shift @{$t} : 0 );
    $self->[UA_OS] = @rest                                     ? join(q{ }, @rest)
                   : $t->[0] && $t->[0] !~ RE_DIGIT_DOT_DIGIT  ? shift @{$t}
                   :                                             undef;
    my @extras = (@{$t}, $extra ? @{$extra} : (), @others );

    $self->_fix_generic(
        \$self->[UA_OS], \$self->[UA_NAME], \$self->[UA_VERSION_RAW], \@extras
    );

    $self->[UA_EXTRAS]      = [ @extras ] if @extras;
    $self->[UA_GENERIC]     = 1;
    $self->[UA_PARSER]      = 'generic_moz_thing';

    return 1;
}

sub _generic_name_version {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    my $ok = $moz && ! @{$thing} && ! $extra && ! $compatible && ! @others;
    return if not $ok;

    my @moz = split RE_WHITESPACE, $moz;
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
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    my @orig_thing = @{ $thing }; # see edge case below

    return if ! ( $compatible && @{$thing} );

    my($mname, $mversion) = split RE_CHAR_SLASH_WS, $moz;
    my($name, $version)   = $mname eq 'Mozilla'
                          ? split( RE_CHAR_SLASH_WS, shift @{ $thing } )
                          : ($mname, $mversion)
                          ;
    shift @{$thing} if  $thing->[0] &&
                      ( $thing->[0] eq $name || $thing->[0] eq $moz);
    my $os     = shift @{$thing};
    my $lang   = pop   @{$thing};
    my @extras;

    if ( $name eq 'MSIE') {
        if ( $self->_is_generic_bogus_ie( $extra ) ) {
            # edge case
            my($n, $v) = split RE_WHITESPACE, shift @orig_thing;
            my $e = [ split RE_SC_WS, join q{ }, @{ $extra } ];
            my $t = \@orig_thing;
            push @{ $e }, grep { $_ } map { split RE_SC_WS, $_ } @others;
            $self->_parse_msie( $moz, $thing, $e, $n, $v );
            return 1;
        }
        elsif ( $extra ) { # Sleipnir?
            ($name, $version)   = split RE_SLASH, pop @{$extra};
            my($extras,$dotnet) = $self->_extract_dotnet( $thing, $extra );
            $self->[UA_DOTNET]  = [ @{$dotnet} ] if @{$dotnet};
            @extras = (@{ $extras }, @others);
        }
        else {
            return if index($moz, q{ }) != NO_IMATCH; # WebTV
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

sub _parse_emacs {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    my @moz = split RE_WHITESPACE, $moz;
    my $emacs = shift @moz;
    my($name, $version) = split RE_SLASH, $emacs;
    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version || 0;
    $self->[UA_OS]          = shift @{ $thing };
    my @rest = (  @{ $thing }, @moz );
    push @rest, @{ $extra } if $extra && ref $extra eq 'ARRAY';
    push @rest, ( map { split RE_SC_WS, $_ } @others ) if @others;
    $self->[UA_EXTRAS]      = [ grep { $_ } map { $self->trim( $_ ) } @rest ];
    $self->[UA_PARSER]      = 'emacs';
    return 1;
}

sub _parse_moz_only {
    my($self, $moz) = @_;
    my @parts = split RE_WHITESPACE, $moz;
    my $id = shift @parts;
    my($name, $version) = split RE_SLASH, $id;
    if ( $name eq 'Mozilla' && @parts ) {
        ($name, $version) = split RE_SLASH, shift @parts;
        return if ! $name || ! $version;
    }
    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version || 0;
    $self->[UA_EXTRAS]      = [ @parts ];
    $self->[UA_PARSER]      = 'moz_only';
    return 1;
}

sub _parse_hotjava {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    my $parsable            = shift @{ $thing };
    my($name, $version)     = split RE_SLASH, $moz;
    $self->[UA_NAME]        = 'HotJava';
    $self->[UA_VERSION_RAW] = $version || 0;
    if ( $parsable ) {
        my @parts = split m{[\[\]]}xms, $parsable;
        if ( @parts > 2 ) {
            @parts = map { $self->trim( $_ ) } @parts;
            $self->[UA_OS]     = pop @parts;
            $self->[UA_LANG]   = pop @parts;
            $self->[UA_EXTRAS] = [ @parts ];
        }
    }
    return 1;
}

sub _parse_docomo {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    if ( $thing->[0] && index(lc $thing->[0], 'googlebot-mobile') != NO_IMATCH ) {
        my($name, $version)     = split RE_SLASH, shift @{ $thing };
        $self->[UA_NAME]        = $name;
        $self->[UA_VERSION_RAW] = $version;
        $self->[UA_EXTRAS]      = [ @{ $thing } ];
        $self->[UA_MOBILE]      = 1;
        $self->[UA_ROBOT]       = 1;
        $self->[UA_PARSER]      = 'docomo';
        return 1;
    }
    #$self->[UA_PARSER] = 'docomo';
    #require Data::Dumper;warn "DoCoMo unsupported: ".Data::Dumper::Dumper( [ $moz, $thing, $extra, $compatible, \@others ] );
    return;
}

package Parse::HTTP::UserAgent::Base::IS;
use strict;
use warnings;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);
use constant OPERA_FAKER_EXTRA_SIZE => 4;

$VERSION = '0.21';

sub _is_opera_pre {
    my($self, $moz) = @_;
    return index( $moz, 'Opera') != NO_IMATCH;
}

sub _is_opera_post {
    my($self, $extra) = @_;
    return $extra && $extra->[0] eq 'Opera';
}

sub _is_opera_ff { # opera faking as firefox
    my($self, $extra) = @_;
    return $extra && @{$extra} == OPERA_FAKER_EXTRA_SIZE && $extra->[2] eq 'Opera';
}

sub _is_safari {
    my($self, $extra, $others) = @_;
    my $str = $self->[UA_STRING];
    # epiphany?
    return                index( $str                   , 'Chrome'       ) != NO_IMATCH ? 0 # faker
          :    $extra  && index( $extra->[0]            , 'AppleWebKit'  ) != NO_IMATCH ? 1
          : @{$others} && index( $others->[LAST_ELEMENT], 'Safari'       ) != NO_IMATCH ? 1
          :                                                                     0
          ;
}

sub _is_chrome {
    my($self, $extra, $others) = @_;
    my $chx = $others->[1] || return;
    my($chrome, $safari) = split RE_WHITESPACE, $chx;
    return if ! ( $chrome && $safari);

    return              index( $chrome    , 'Chrome'     ) != NO_IMATCH &&
                        index( $safari    , 'Safari'     ) != NO_IMATCH &&
           ( $extra  && index( $extra->[0], 'AppleWebKit') != NO_IMATCH);
}

sub _is_ff {
    my($self, $extra) = @_;
    return if ! $extra || ! $extra->[1];
    my $moz_with_name = $extra->[1] eq 'Mozilla' && $extra->[2];
    return $moz_with_name
        ? $extra->[2] =~ RE_FIREFOX_NAMES && do { $extra->[1] = $extra->[2] }
        : $extra->[1] =~ RE_FIREFOX_NAMES
    ;
}

sub _is_gecko {
    return index(shift->[UA_STRING], 'Gecko/') != NO_IMATCH;
}

sub _is_generic { #TODO: this is actually a parser
    my($self, @args) = @_;
    return 1 if $self->_generic_name_version( @args ) ||
                $self->_generic_compatible(   @args ) ||
                $self->_generic_moz_thing(    @args );
    return;
}

sub _is_netscape {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;

    my $rv = index($moz, 'Mozilla/') != NO_IMATCH &&
             $moz ne 'Mozilla/4.0'            &&
             ! $compatible                    &&
             ! $extra                         &&
             ! @others                        &&
             ( @{$thing} && $thing->[LAST_ELEMENT] ne 'Sun' )  && # hotjava
             index($thing->[0], 'http://') == NO_IMATCH # robot
             ;
    return $rv;
}

sub _is_docomo {
    my($self, $moz) = @_;
    return index(lc $moz, 'docomo') != NO_IMATCH;
}

sub _is_strength {
    my $self = shift;
    my $s    = shift || return;
       $s    = $self->trim( $s );
    return $s if $s eq 'U' || $s eq 'I' || $s eq 'N';
    return;
}

sub _is_emacs {
    my($self, $moz) = @_;
    return index( $moz, 'Emacs-W3/') != NO_IMATCH;
}

sub _is_moz_only {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    return $moz && ! @{ $thing } && ! $extra && ! @others;
}

sub _is_hotjava {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    my @hot = @{ $thing };
    return @hot == 2 && $hot[1] eq 'Sun';
}

sub _is_generic_bogus_ie {
    my($self, $extra) = @_;
    return $extra
        && $extra->[0]
        && index( $extra->[0], 'compatible' ) != NO_IMATCH
        && $extra->[1]
        && $extra->[1] eq 'MSIE';
}

package Parse::HTTP::UserAgent::Base::Dumper;
use strict;
use warnings;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);
use Carp qw( croak );

$VERSION = '0.21';

sub dumper {
    my($self, @args) = @_;
    my %opt = @args % 2 ? () : (
        type      => 'dumper',
        format    => 'none',
        interpret => 0,
        @args
    );
    my $meth = '_dumper_' . lc $opt{type};
    croak "Don't know how to dump with $opt{type}" if ! $self->can( $meth );
    my $buf = $self->$meth( \%opt );
    return $buf if defined wantarray;
    my $pok = print $buf ."\n";
    return;
}

sub _dump_to_struct {
    my %struct    = shift->as_hash;
    $struct{$_} ||= [] for qw( dotnet mozilla extras tk );
    $struct{$_} ||= 0  for qw( unknown );
    return \%struct;
}

sub _dumper_json {
    my $self = shift;
    my $opt  = shift;
    require JSON;
    return  JSON::to_json(
                $self->_dump_to_struct,
                { pretty => $opt->{format} eq 'pretty' }
            );
}

sub _dumper_xml {
    my $self = shift;
    my $opt  = shift;
    require XML::Simple;
    return  XML::Simple::XMLout(
                $self->_dump_to_struct,
                RootName => 'ua',
                NoIndent => $opt->{format} ne 'pretty',
            );
}

sub _dumper_yaml {
    my $self = shift;
    my $opt  = shift;
    require YAML;
    return  YAML::Dump( $self->_dump_to_struct );
}

sub _dumper_dumper {
    # yeah, I know. Fugly code here
    my $self = shift;
    my $opt  = shift;
    my @ids  = $opt->{args} ?  @{ $opt->{args} } : $self->_object_ids;
    my $args = $opt->{args} ?                  1 : 0;
    my $max  = 0;
    map { $max = length $_ if length $_ > $max; } @ids;
    my @titles = qw( FIELD VALUE );
    my $buf    = sprintf "%s%s%s\n%s%s%s\n",
                        $titles[0],
                        (q{ } x (2 + $max - length $titles[0])),
                        $titles[1],
                        q{-} x $max, q{ } x 2, q{-} x ($max*2);
    require Data::Dumper;
    my @buf;
    foreach my $id ( @ids ) {
        my $name = $args ? $id->{name} : $id;
        my $val  = $args ? $id->{value} : $self->[ $self->$id() ];
        $val = do {
                    my $d = Data::Dumper->new([$val]);
                    $d->Indent(0);
                    my $rv = $d->Dump;
                    $rv =~ s{ \$VAR1 \s+ = \s+ }{}xms;
                    $rv =~ s{ ; }{}xms;
                    $rv eq '[]' ? q{} : $rv;
                } if $val && ref $val;
        push @buf, [
                        $name,
                        (q{ } x (2 + $max - length $name)),
                        defined $val ? $val : q{}
                    ];
    }
    foreach my $row ( sort { lc $a->[0] cmp lc $b->[0] } @buf ) {
        $buf .= sprintf "%s%s%s\n", @{ $row };
    }
    return $buf;
}

package Parse::HTTP::UserAgent::Base::Accessors;
use strict;
use warnings;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);

$VERSION = '0.21';

#TODO: new accessors
#wap
#mobile
#device

sub name             { return shift->[UA_NAME]             || q{} }
sub unknown          { return shift->[UA_UNKNOWN]          || q{} }
sub generic          { return shift->[UA_GENERIC]          || q{} }
sub os               { return shift->[UA_OS]               || q{} }
sub lang             { return shift->[UA_LANG]             || q{} }
sub strength         { return shift->[UA_STRENGTH]         || q{} }
sub parser           { return shift->[UA_PARSER]           || q{} }
sub original_name    { return shift->[UA_ORIGINAL_NAME]    || q{} }
sub original_version { return shift->[UA_ORIGINAL_VERSION] || q{} }
sub robot            { return shift->[UA_ROBOT]            ||   0 }

sub version {
    my $self = shift;
    my $type = shift || q{};
    return $self->[ $type eq 'raw' ? UA_VERSION_RAW : UA_VERSION ] || 0;
}

sub mozilla {
    my $self = shift;
    return +() if ! $self->[UA_MOZILLA];
    my @rv = @{ $self->[UA_MOZILLA] };
    return wantarray ? @rv : $rv[0];
}

sub toolkit {
    my $self = shift;
    return +() if ! $self->[UA_TOOLKIT];
    return @{ $self->[UA_TOOLKIT] };
}

sub extras {
    my $self = shift;
    return +() if ! $self->[UA_EXTRAS];
    return @{ $self->[UA_EXTRAS] };
}

sub dotnet {
    my $self = shift;
    return +() if ! $self->[UA_DOTNET];
    return @{ $self->[UA_DOTNET] };
}

package Parse::HTTP::UserAgent;
use strict;
use warnings;
use vars qw( $VERSION );

$VERSION = '0.21';

use base qw(
    Parse::HTTP::UserAgent::Base::IS
    Parse::HTTP::UserAgent::Base::Parsers
    Parse::HTTP::UserAgent::Base::Dumper
    Parse::HTTP::UserAgent::Base::Accessors
);
use overload '""',    => 'name',
             '0+',    => 'version',
             fallback => 1,
;
use version;
use Carp qw( croak );
use Parse::HTTP::UserAgent::Constants qw(:all);

BEGIN {
    constant->import( DEBUG => 0 ) if not defined &DEBUG;
}

my %OSFIX = (
    'WinNT4.0'       => 'Windows NT 4.0',
    'WinNT'          => 'Windows NT',
    'Windows 4.0'    => 'Windows 95',
    'Win95'          => 'Windows 95',
    'Win98'          => 'Windows 98',
    'Windows 4.10'   => 'Windows 98',
    'Win 9x 4.90'    => 'Windows Me',
    'Windows NT 5.0' => 'Windows 2000',
    'Windows NT 5.1' => 'Windows XP',
    'Windows NT 5.2' => 'Windows Server 2003',
    'Windows NT 6.0' => 'Windows Vista / Server 2008',
    'Windows NT 6.1' => 'Windows 7',
);

sub new {
    my $class = shift;
    my $ua    = shift || croak 'No user agent string specified';
    my $opt   = shift || {};
    croak 'Options must be a hash reference' if ref $opt ne 'HASH';
    my $self  = [ map { undef } 0..MAXID ];
    bless $self, $class;
    $self->[UA_STRING]   = $ua;
    $self->[IS_EXTENDED] = exists $opt->{extended} ? $opt->{extended} : 1;
    $self->_parse;
    return $self;
}

sub as_hash {
    my $self = shift;
    my %struct;
    foreach my $id ( $self->_object_ids ) {
        (my $name = $id) =~ s{ \A UA_ }{}xms;
        $struct{ lc $name } = $self->[ $self->$id() ];
    }
    return %struct;
}

sub trim {
    my $self = shift;
    my $s    = shift;
    return $s if ! $s;
    $s =~ s{ \A \s+    }{}xms;
    $s =~ s{    \s+ \z }{}xms;
    return $s;
}

sub _parse {
    my $self = shift;
    return $self if $self->[IS_PARSED];
    $self->_do_parse( $self->_pre_parse );
    $self->[IS_PARSED] = 1;
    $self->_post_parse if ! $self->[UA_UNKNOWN];
    return;
}

sub _pre_parse {
    my $self = shift;
    $self->[IS_MAXTHON] = index(uc $self->[UA_STRING], 'MAXTHON') != NO_IMATCH;
    my $ua = $self->[UA_STRING];
    my($moz, $thing, $extra, @others) = split RE_SPLIT_PARSE, $ua;
    $thing = $thing ? [ split RE_SC_WS, $thing ] : [];
    $extra = [ split RE_WHITESPACE, $extra ] if $extra;
    $self->_debug_pre_parse( $moz, $thing, $extra, @others ) if DEBUG;
    return $moz, $thing, $extra, @others;
}

sub _do_parse {
    my($self, $m, $t, $e, @o) = @_;
    my $c = $t->[0] && $t->[0] eq 'compatible';

    if ( $c && shift @{$t} && ! $e && ! $self->[IS_MAXTHON] ) {
        my($n, $v) = split RE_WHITESPACE, $t->[0];
        if ( $n eq 'MSIE' && index($m, q{ }) == NO_IMATCH ) {
            return $self->_parse_msie($m, $t, $e, $n, $v);
        }
    }

    my $rv =  $self->_is_opera_pre($m)   ? [opera_pre  => $m, $t, $e           ]
            : $self->_is_opera_post($e)  ? [opera_post => $m, $t, $e, $c       ]
            : $self->_is_opera_ff($e)    ? [opera_pre  => "$e->[2]/$e->[3]", $t]
            : $self->_is_ff($e)          ? [firefox    => $m, $t, $e, @o       ]
            : $self->_is_safari($e, \@o) ? [safari     => $m, $t, $e, @o       ]
            : $self->_is_chrome($e, \@o) ? [chrome     => $m, $t, $e, @o       ]
            : $self->[IS_MAXTHON]        ? [maxthon    => $m, $t, $e, @o       ]
            : undef;

    if ( $rv ) {
        my $pname  = shift @{ $rv };
        my $method = '_parse_' . $pname;
        my $rvx    = $self->$method( @{ $rv } );
        if ( $rvx ) {
            $self->[UA_PARSER] = $pname;
            return $rvx;
        }
    }

    return $self->_extended_probe($m, $t, $e, $c, @o) if $self->[IS_EXTENDED];

    $self->[UA_UNKNOWN] = 1; # give up
    return;
}

sub _post_parse {
    my $self = shift;
    $self->[UA_VERSION] = $self->_numify( $self->[UA_VERSION_RAW] )
        if $self->[UA_VERSION_RAW];

    my @buf;
    foreach my $e ( @{ $self->[UA_EXTRAS] } ) {
        if ( $self->_is_strength( $e ) ) {
            $self->[UA_STRENGTH] = $e ;
            next;
        }
        push @buf, $e;
    }

    $self->[UA_EXTRAS] = [ @buf ];

    if ( $self->[UA_TOOLKIT] ) {
        push @{ $self->[UA_TOOLKIT] },
             $self->_numify( $self->[UA_TOOLKIT][TK_ORIGINAL_VERSION] );
    }

    if( $self->[UA_MOZILLA] ) {
        $self->[UA_MOZILLA] =~ tr/a-z://d;
        $self->[UA_MOZILLA] = [ $self->[UA_MOZILLA],
                                $self->_numify( $self->[UA_MOZILLA] ) ];
    }

    if ( $self->[UA_OS] ) {
        $self->[UA_OS] = $OSFIX{ $self->[UA_OS] } || $self->[UA_OS];
    }

    foreach my $robo ( LIST_ROBOTS ) { # regex???
        next if lc $robo ne lc $self->[UA_NAME];
        $self->[UA_ROBOT] = 1;
        last;
    }
    return;
}

sub _extended_probe {
    my($self, @args) = @_;

    return if $self->_is_gecko             && $self->_parse_gecko(    @args );
    return if $self->_is_netscape( @args ) && $self->_parse_netscape( @args );
    return if $self->_is_docomo(   @args ) && $self->_parse_docomo(   @args );
    return if $self->_is_generic(  @args );
    return if $self->_is_emacs(    @args ) && $self->_parse_emacs(    @args );
    return if $self->_is_moz_only( @args ) && $self->_parse_moz_only( @args );
    return if $self->_is_hotjava(  @args ) && $self->_parse_hotjava(  @args );

    $self->[UA_UNKNOWN] = 1;
    return;
}

sub _object_ids {
    return grep { $_ =~ RE_OBJECT_ID } keys %Parse::HTTP::UserAgent::;
}

sub _numify {
    my $self = shift;
    my $v    = shift || return 0;
    $v    =~ s{(
                pre      |
                rel      |
                alpha    |
                beta     |
                \-stable |
                gold     |
                [ab]\d+  |
                a\-XXXX  |
                \+
               )}{}xmsig;

    if ( INSIDE_VERBOSE_TEST ) {
        if ( $1 ) {
            Test::More::diag("[DEBUG] _numify: removed '$1' from version string");
        }
    }

    # Gecko revisions like: "20080915000512" will cause an
    #   integer overflow warning. use bigint?
    local $SIG{__WARN__} = sub {
        my $msg = shift;
        warn "$msg\n" if $msg !~ RE_WARN_OVERFLOW && $msg !~ RE_WARN_INVALID;
    };
    # if version::vpp is used it'll identify 420 as a v-string
    # add a floating point to fool it
    $v .= q{.0} if index($v, q{.}) == NO_IMATCH;
    my $rv;
    eval {
        $rv = version->new("$v")->numify; 1
    } or do {
        my $error = $@ || '[unknown error while parsing version]';
        if ( INSIDE_UNIT_TEST ) {
            chomp $error;
            if ( INSIDE_VERBOSE_TEST ) {
                Test::More::diag( "[FATAL] _numify: version said: $error" );
                Test::More::diag(
                    sprintf "[FATAL] _numify: UA with bogus version (%s) is: %s",
                                $v, $self->[UA_STRING]
                );
                Test::More::diag( '[FATAL] _numify: ' . $self->dumper );
            }
            die $error;
        }
        else {
            die $error;
        }
    };
    return $rv;
}

sub _debug_pre_parse {
    my($self, $moz, $thing, $extra, @others) = @_;

    my $raw = [
                { qw/ name moz    value / => $moz     },
                { qw/ name thing  value / => $thing   },
                { qw/ name extra  value / => $extra   },
                { qw/ name others value / => \@others },
            ];
    my $pok = print "-------------- PRE PARSE DUMP --------------\n"
                  . $self->dumper(args => $raw)
                  . "--------------------------------------------\n";
    return;
}

1;

__END__

=pod

=head1 NAME

Parse::HTTP::UserAgent - Parser for the User Agent string

=head1 SYNOPSIS

   use Parse::HTTP::UserAgent;
   my $ua = Parse::HTTP::UserAgent->new( $str );
   die "Unable to parse!" if $ua->unknown;
   print $ua->name;
   print $ua->version;
   print $ua->os;
   # or just dump for debugging:
   print $ua->dumper;

=head1 DESCRIPTION

B<WARNING>! This is the monolithic version of Parse::HTTP::UserAgent
generated with an automatic build tool. If you experience problems
with this version, please install and use the supported standard
version. This version is B<NOT SUPPORTED>.

This document describes version C<0.21> of C<Parse::HTTP::UserAgent>
released on C<19 October 2011>.

Quoting L<http://www.webaim.org/blog/user-agent-string-history/>:

   " ... and then Google built Chrome, and Chrome used Webkit, and it was like
   Safari, and wanted pages built for Safari, and so pretended to be Safari.
   And thus Chrome used WebKit, and pretended to be Safari, and WebKit pretended
   to be KHTML, and KHTML pretended to be Gecko, and all browsers pretended to
   be Mozilla, (...) , and the user agent string was a complete mess, and near
   useless, and everyone pretended to be everyone else, and confusion
   abounded."

User agent strings are a complete mess since there is no standard format for
them. They can be in various formats and can include more or less information
depending on the vendor's (or the user's) choice. Also, it is not dependable
since it is some arbitrary identification string. Any user agent can fake
another. So, why deal with such a useless mess? You may want to see the choice
of your visitors and can get some reliable data (even if some are fake) and
generate some nice charts out of them or just want to send a C<HttpOnly> cookie
if the user agent seem to support it (and send a normal one if this is not the
case). However, browser sniffing for client-side coding is considered a bad
habit.

This module implements a rules-based parser and tries to identify
MSIE, FireFox, Opera, Safari & Chrome first. It then tries to identify Mozilla,
Netscape, Robots and the rest will be tried with a generic parser. There is
also a structure dumper, useful for debugging.

=head1 METHODS

=head2 new STRING [, OPTIONS ]

Constructor. Takes the user agent string as the first parameter and returns
an object based on the parsed structure.

The optional C<OPTIONS> parameter (must be a hashref) can be used to pass
several parameters:

=over 4

=item *

C<extended>: controls if the extended probe will be used or not. Default
is true. Set this to false to disable:

   $ua = Parse::HTTP::UserAgent->new( $str, { extended => 0 } );

Can be used to speed up the parser by disabling detection of non-major browsers,
robots and most mobile agents.

=back

=head2 trim STRING

Trims the string.

=head2 as_hash

Returns a hash representation of the parsed structure.

=head2 dumper

See L<Parse::HTTP::UserAgent::Base::Dumper>.

=head2 accessors

See L<Parse::HTTP::UserAgent::Base::Accessors> for the available accessors you can
use on the parsed object.

=head1 OVERLOADED INTERFACE

The object returned, overloads stringification (C<name>) and numification
(C<version>) operators. So that you can write this:

    print 42 if $ua eq 'Opera' && $ua >= 9;

instead of this

    print 42 if $ua->name eq 'Opera' && $ua->version >= 9;

=head1 ERROR HANDLING

=over 4

=item *

If you pass a false value to the constructor, it'll croak.

=item *

If you pass a non-hashref option to the constructor, it'll croak.

=item *

If you pass a wrong parameter to the dumper, it'll croak.

=back

=head1 SEE ALSO

=head2 Similar Functionality

=over 4

=item *

L<HTTP::BrowserDetect>

=item *

L<HTML::ParseBrowser>

=item *

L<HTTP::DetectUserAgent>

=item *

L<HTTP::MobileAgent>

=back

=head2 Resources

=over 4

=item *

L<http://en.wikipedia.org/wiki/User_agent>,

=item *

L<http://www.zytrax.com/tech/web/browser_ids.htm>,

=item *

L<http://www.zytrax.com/tech/web/mobile_ids.html>,

=item *

L<http://www.webaim.org/blog/user-agent-string-history/>.

=back

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.3 or, 
at your option, any later version of Perl 5 you may have available.

=cut
