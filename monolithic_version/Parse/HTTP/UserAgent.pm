BEGIN { $INC{$_} = 1 for qw(Parse/HTTP/UserAgent.pm Parse/HTTP/UserAgent/Constants.pm Parse/HTTP/UserAgent/Base/Accessors.pm Parse/HTTP/UserAgent/Base/Dumper.pm Parse/HTTP/UserAgent/Base/IS.pm Parse/HTTP/UserAgent/Base/Parsers.pm); }
package Parse::HTTP::UserAgent;
sub ________monolith {}
package Parse::HTTP::UserAgent::Constants;
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
use strict;
use vars qw( $VERSION $OID @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

$VERSION = '0.14';

BEGIN { $OID = -1 }
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

use constant RE_FIREFOX_NAMES    => qr{Firefox|Iceweasel|Firebird|Phoenix }xms;
use constant RE_DOTNET           => qr{ \A [.]NET \s+ CLR \s+ (.+?) \z    }xms;
use constant RE_WINDOWS_OS       => qr{ \A Win(dows|NT|[0-9]+)?           }xmsi;
use constant RE_SLASH            => qr{ /                                 }xms;
use constant RE_SPLIT_PARSE      => qr{ \s? [()] \s?                      }xms;
use constant RE_OPERA_MINI       => qr{ \A (Opera \s+ Mini) / (.+?) \z    }xms;
use constant RE_TRIDENT          => qr{ \A (Trident) / (.+?) \z           }xmsi;
use constant RE_EPIPHANY_GECKO   => qr{ \A (Epiphany) / (.+?) \z          }xmsi;
use constant RE_WHITESPACE       => qr{ \s+ }xms;

use constant LIST_ROBOTS         => qw(
    Wget
    curl
    libwww-perl
    GetRight
    Googlebot
    Baiduspider+
    msnbot
), 'Yahoo! Slurp';

use Exporter ();

BEGIN {
    @ISA         = qw( Exporter );
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
        )],
        list => [qw(
            LIST_ROBOTS
        )],
    );

    @EXPORT_OK        = map { @{ $_ } } values %EXPORT_TAGS;
    $EXPORT_TAGS{all} = [ @EXPORT_OK ];
}

package Parse::HTTP::UserAgent::Base::Parsers;
use strict;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);
use constant ERROR_MAXTHON_VERSION => "Unable to extract Maxthon version from Maxthon UA-string";
use constant ERROR_MAXTHON_MSIE    => "Unable to extract MSIE from Maxthon UA-string";

$VERSION = '0.14';

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
        if ( $e =~ RE_OPERA_MINI ) {
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
    my($maxthon, $msie, @buf);
    foreach my $e ( @omap, @{$thing} ) { # $extra -> junk
        if ( index(uc $e, 'MAXTHON') != -1 ) { $maxthon = $e; next; }
        if ( index(uc $e, 'MSIE'   ) != -1 ) { $msie    = $e; next; }
        push @buf, $e;
    }

    if ( ! $maxthon ) {
        warn ERROR_MAXTHON_VERSION;
        $self->[UA_UNKNOWN] = 1;
        return;
    }

    if ( ! $msie ) {
        warn ERROR_MAXTHON_MSIE;
        $self->[UA_UNKNOWN] = 1;
        return;
    }

    $self->_parse_msie($moz, [ undef, @buf ], undef, split RE_WHITESPACE, $msie);

    my(undef, $mv) = split RE_WHITESPACE, $maxthon;
    my $v = $mv      ? $mv
          : $maxthon ? '1.0'
          :            do { warn ERROR_MAXTHON_VERSION; 0 }
          ;

    $self->[UA_ORIGINAL_VERSION] = $v;
    $self->[UA_ORIGINAL_NAME]    = 'Maxthon';
    return;
}

sub _parse_msie {
    my($self, $moz, $thing, $extra, $name, $version) = @_;
    my $junk = shift @{ $thing }; # already used
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
        if ( $e =~ RE_TRIDENT ) {
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
    my($version, @junk)     = split RE_WHITESPACE, pop @others;
    my $ep = $version && index( lc($version), 'epiphany' ) != -1;
    (undef, $version)       = split RE_SLASH, $version;
    $self->[UA_NAME]        = $ep ? 'Epiphany' : 'Safari';
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
   (my $lang                = pop @{$extra}) =~ tr/[]//d if $extra;
    $lang                 ||= pop @{$thing} if $faking_ff;

    if ( $self->_numify( $version ) >= 9 && $lang && length( $lang ) > 5 ) {
        $self->[UA_TOOLKIT] = [ split RE_SLASH, $lang ];
       ($lang = pop @{$thing}) =~ tr/[]//d if $extra;
    }

    $self->[UA_LANG] = $lang;
    $self->[UA_OS]   = $self->_is_strength($thing->[-1]) ? shift @{$thing}
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
            if ( $e =~ RE_EPIPHANY_GECKO ) {
                $self->[UA_NAME]        = $before = $1;
                $self->[UA_VERSION_RAW] = $2;
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

package Parse::HTTP::UserAgent::Base::IS;
use strict;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);

$VERSION = '0.14';

sub _is_opera_pre {
    my($self, $moz) = @_;
    return index( $moz, 'Opera') != -1;
}

sub _is_opera_post {
    my($self, $extra) = @_;
    return $extra && $extra->[0] eq 'Opera';
}

sub _is_opera_ff { # opera faking as firefox
    my($self, $extra) = @_;
    return $extra && @{$extra} == 4 && $extra->[2] eq 'Opera';
}

sub _is_safari {
    my($self, $extra, $others) = @_;
    my $str = $self->[UA_STRING];
    # epiphany?
    return                index( $str         , 'Chrome'     ) != -1 ? 0 # faker
          :    $extra  && index( $extra->[0]  , 'AppleWebKit') != -1 ? 1
          : @{$others} && index( $others->[-1], 'Safari'     ) != -1 ? 1
          :                                                            0
          ;
}

sub _is_chrome {
    my($self, $extra, $others) = @_;
    my $chx = $others->[1] || return;
    my($chrome, $safari) = split RE_WHITESPACE, $chx;
    return if ! ( $chrome && $safari);

    return              index( $chrome    , 'Chrome'     ) != -1 &&
                        index( $safari    , 'Safari'     ) != -1 &&
           ( $extra  && index( $extra->[0], 'AppleWebKit') != -1);
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
    return index(shift->[UA_STRING], 'Gecko/') != -1;
}

sub _is_generic { #TODO: this is actually a parser
    my $self = shift;
    return 1 if $self->_generic_name_version( @_ ) ||
                $self->_generic_compatible(   @_ )   ||
                $self->_generic_moz_thing(    @_ );
    return;
}

sub _is_netscape {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;

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

package Parse::HTTP::UserAgent::Base::Dumper;
use strict;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);
use Carp qw( croak );

$VERSION = '0.14';

sub dumper {
    my $self = shift;
    my %opt  = @_ % 2 ? () : (
        type      => 'dumper',
        format    => 'none',
        interpret => 0,
        @_
    );
    my $meth = '_dumper_' . lc($opt{type});
    croak "Don't know how to dump with $opt{type}" if ! $self->can( $meth );
    my $buf = $self->$meth( \%opt );
    return $buf if defined wantarray;
    print $buf ."\n";
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
    map { my $l = length $_; $max = $l if $l > $max; } @ids;
    my @titles = qw( FIELD VALUE );
    my $buf    = sprintf "%s%s%s\n%s%s%s\n",
                        $titles[0],
                        (' ' x (2 + $max - length $titles[0])),
                        $titles[1],
                        '-' x $max, ' ' x 2, '-' x ($max*2);
    require Data::Dumper;
    foreach my $id ( @ids ) {
        my $name = $args ? $id->{name} : $id;
        my $val  = $args ? $id->{value} : $self->[ $self->$id() ];
        $val = do {
                    my $d = Data::Dumper->new([$val]);
                    $d->Indent(0);
                    my $rv = $d->Dump;
                    $rv =~ s{ \$VAR1 \s+ = \s+ }{}xms;
                    $rv =~ s{ ; }{}xms;
                    $rv eq '[]' ? '' : $rv;
                } if $val && ref $val;
        $buf .= sprintf "%s%s%s\n",
                        $name,
                        (' ' x (2 + $max - length $name)),
                        defined $val ? $val : ''
                        ;
    }
    return $buf;
}

package Parse::HTTP::UserAgent::Base::Accessors;
use strict;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);

$VERSION = '0.14';

#TODO: new accessors
#wap
#mobile
#device

sub name             { shift->[UA_NAME]             || '' }
sub unknown          { shift->[UA_UNKNOWN]          || '' }
sub generic          { shift->[UA_GENERIC]          || '' }
sub os               { shift->[UA_OS]               || '' }
sub lang             { shift->[UA_LANG]             || '' }
sub strength         { shift->[UA_STRENGTH]         || '' }
sub parser           { shift->[UA_PARSER]           || '' }
sub original_name    { shift->[UA_ORIGINAL_NAME]    || '' }
sub original_version { shift->[UA_ORIGINAL_VERSION] || '' }
sub robot            { shift->[UA_ROBOT]            || 0  }

sub version {
    my $self = shift;
    my $type = shift || '';
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
use vars qw( $VERSION );

$VERSION = '0.14';

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
use Parse::HTTP::UserAgent::Constants qw(:all);
use Carp qw( croak );

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
    my $ua    = shift || croak "No user agent string specified";
    my $opt   = shift || {};
    croak "Options must be a hash reference" if ref $opt ne 'HASH';
    my $self  = [ map { undef } 0..MAXID ];
    bless $self, $class;
    $self->[UA_STRING]   = $ua;
    $self->[IS_EXTENDED] = exists $opt->{extended} ? $opt->{extended} : 1;
    $self->_parse;
    return $self;
}

sub as_hash {
    my $self   = shift;
    my @ids    = $self->_object_ids;
    my %struct = map {
                    my $id = $_;
                    $id =~ s{ \A UA_ }{}xms;
                    lc $id, $self->[ $self->$_() ]
                 } @ids;
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
    $self->[IS_MAXTHON] = index(uc $self->[UA_STRING], 'MAXTHON') != -1;
    my $ua = $self->[UA_STRING];
    my($moz, $thing, $extra, @others) = split RE_SPLIT_PARSE, $ua;
    $thing = $thing ? [ split m{;\s?}xms, $thing ] : [];
    $extra = [ split RE_WHITESPACE, $extra ] if $extra;
    $self->_debug_pre_parse( $moz, $thing, $extra, @others ) if DEBUG;
    return $moz, $thing, $extra, @others;
}

sub _do_parse {
    my $self = shift;
    my($m, $t, $e, @o) = @_;
    my $c = $t->[0] && $t->[0] eq 'compatible';

    if ( $c && shift @{$t} && ! $e && ! $self->[IS_MAXTHON] ) {
        my($n, $v) = split RE_WHITESPACE, $t->[0];
        if ( $n eq 'MSIE' && index($m, ' ') == -1 ) {
            $self->[UA_PARSER] = 'msie';
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
        my $pname  = shift( @{ $rv } );
        my $method = '_parse_' . $pname;
        $self->[UA_PARSER] = $pname;
        return $self->$method( @{ $rv } );
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
        push @{ $self->[UA_TOOLKIT] }, $self->_numify( $self->[UA_TOOLKIT][1] );
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
    my $self = shift;
    my($moz, $thing, $extra, $compatible, @others) = @_;

    return if $self->_is_gecko        && $self->_parse_gecko( @_ );
    return if $self->_is_netscape(@_) && $self->_parse_netscape( @_ );
    return if $self->_is_generic(@_);

    $self->[UA_UNKNOWN] = 1;
    return;
}

sub _object_ids {
    return grep { m{ \A UA_ }xms } keys %Parse::HTTP::UserAgent::;
}

sub _numify {
    my $self = shift;
    my $v    = shift || return 0;
    $v    =~ s{
                pre      |
                \-stable |
                gold     |
                [ab]\d+  |
                \+
                }{}xmsig;
    # Gecko revisions like: "20080915000512" will cause an
    #   integer overflow warning. use bigint?
    local $SIG{__WARN__} = sub {
        my $w = shift;
        my $ok = $w !~ m{Integer overflow in version} &&
                 $w !~ m{Version string .+? contains invalid data; ignoring:};
        warn $w if $ok;
    };
    my $rv = version->new("$v")->numify;
    return $rv;
}

sub _debug_pre_parse {
    my $self = shift;
    my($moz, $thing, $extra, @others) = @_;

    my $raw = [
                { qw/ name moz    value / => $moz     },
                { qw/ name thing  value / => $thing   },
                { qw/ name extra  value / => $extra   },
                { qw/ name others value / => \@others },
            ];
    print "-------------- PRE PARSE DUMP --------------\n"
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

This document describes version C<0.14> of C<Parse::HTTP::UserAgent>
released on C<29 August 2009>.

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

Constructor. Takes the user agent string as the only parameter and returns
an object based on the parsed structure.

The optional C<OPTIONS> parameter (must be a hashref) can be used to pass
several parameters:

=over 4

=item *

C<extended>: controls if the extended probe qill be used or not. Default
is true. Set this to false to disable:

   $ua = Parse::HTTP::UserAgent->new( $str, { extended => 0 } );

Can be used to speed up the parser by disabling detection of non-major browsers.

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

L<HTTP::BrowserDetect>, L<HTML::ParseBrowser>, L<HTTP::DetectUserAgent>.

=head2 Resources

L<http://en.wikipedia.org/wiki/User_agent>,
L<http://www.zytrax.com/tech/web/browser_ids.htm>,
L<http://www.zytrax.com/tech/web/mobile_ids.html>,
L<http://www.webaim.org/blog/user-agent-string-history/>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.10.0 or, 
at your option, any later version of Perl 5 you may have available.

=cut
