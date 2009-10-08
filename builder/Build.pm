package Build;
use strict;
use vars qw( $VERSION );
use constant TAINT_SHEBANG => "#!perl -Tw\nuse constant TAINTMODE => 1;\n";

# since this is a builder we don't care about warnings.pm to support older perl
## no critic (RequireUseWarnings)

$VERSION = '0.63';

use File::Find;
use File::Spec;
use File::Path;
use Carp qw( croak );
use Build::Spec;
use base qw( Module::Build );
use constant RE_VERSION_LINE => qr{
   \A \$VERSION \s+ = \s+ ["'] (.+?) ['"] ; (.+?) \z
}xms;
use constant RE_POD_LINE => qr{
\A =head1 \s+ DESCRIPTION \s+ \z
}xms;
use constant VTEMP  => q{$VERSION = '%s';};
use constant MONTHS => qw(
   January February March     April   May      June
   July    August   September October November December
);
use constant MONOLITH_TEST_FAIL =>
   "\nFAILED! Building the monolithic version failed during unit testing\n\n";

use constant NO_INDEX => qw( monolithic_version builder t );
use constant DEFAULTS => qw(
   license          perl
   create_license   1
   sign             0
);

__PACKAGE__->add_property( build_monolith      => 0  );
__PACKAGE__->add_property( change_versions     => 0  );
__PACKAGE__->add_property( vanilla_makefile_pl => 1  );
__PACKAGE__->add_property( monolith_add_to_top => [] );
__PACKAGE__->add_property( taint_mode_tests    => 0  );
__PACKAGE__->add_property( add_pod_author_copyright_license => 0 );
__PACKAGE__->add_property( copyright_first_year => 0 );

sub new {
   my $class = shift;
   my %opt   = spec;
   my %def   = DEFAULTS;
   foreach my $key ( keys %def ) {
      $opt{ $key } = $def{ $key } if ! defined $opt{ $key };
   }
   $opt{no_index}            ||= {};
   $opt{no_index}{directory} ||= [];
   push @{ $opt{no_index}{directory} }, NO_INDEX;
   return $class->SUPER::new( %opt );
}

sub create_build_script {
   my $self = shift;
   $self->_add_vanilla_makefile_pl if $self->vanilla_makefile_pl;
   return $self->SUPER::create_build_script( @_ );
}

sub mytrim {
   my $self = shift;
   my $s = shift;
   return $s if ! $s; # false or undef
   my $extra = shift || q{};
      $s =~ s{\A \s+   }{$extra}xms;
      $s =~ s{   \s+ \z}{$extra}xms;
   return $s;
}

sub ACTION_dist {
   my $self = shift;
   my $msg  = sprintf q{RUNNING 'dist' Action from subclass %s v%s},
                      ref($self),
                      $VERSION;
   warn "$msg\n";
   my @modules;
   find {
      wanted => sub {
         my $file = $_;
         return if $file !~ m{ \. pm \z }xms;
         $file = File::Spec->catfile( $file );
         push @modules, $file;
         warn "FOUND Module: $file\n";
      },
      no_chdir => 1,
   }, 'lib';
   $self->_create_taint_mode_tests      if $self->taint_mode_tests;
   $self->_change_versions( \@modules ) if $self->change_versions;
   $self->_build_monolith(  \@modules ) if $self->build_monolith;
   $self->SUPER::ACTION_dist( @_ );
}

sub _create_taint_mode_tests {
   my $self   = shift;
   require File::Basename;
   my @tests  = glob 't/*.t';
   my @taints = map {
                  my $t = File::Basename::basename( $_ );
                  my($num,$rest) = split /\-/xms, $t, 2;
                  "t/$num-taint-mode-$rest";
               }  @tests;

   for my $i ( 0..$#tests ) {
      next if $tests[$i] =~ m{ pod[.]t           \z }xms;
      next if $tests[$i] =~ m{ pod\-coverage[.]t \z }xms;
      next if $tests[$i] =~ m{ all\-modules\-have\-the\-same\-version[.]t \z }xms;

      next if -e $taints[$i]; # already created!

      open my $ORIG, '<:raw', $tests[$i]  or croak "Can not open file($tests[$i]): $!";
      open my $DEST, '>:raw', $taints[$i] or croak "Can not open file($taints[$i]): $!";
      print {$DEST} TAINT_SHEBANG or croak "Can not print to destination: $!";
      while ( my $line = readline $ORIG ) {
         print {$DEST} $line or croak "Can not print to destination: $!";
      }
      close $ORIG or croak "Can not close original: $!";
      close $DEST or croak "Can not close destination: $!";
      $self->_write_file( '>>', 'MANIFEST', "$taints[$i]\n");
   }
   return;
}

sub _change_versions {
   my $self  = shift;
   my $files = shift;
   my $dver  = $self->dist_version;

   my(undef, undef, undef, $mday, $mon, $year) = localtime time;
   my $date = join q{ }, $mday, [MONTHS]->[$mon], $year + 1900;

   warn "CHANGING VERSIONS\n";
   warn "\tDISTRO Version: $dver\n";

   foreach my $mod ( @{ $files } ) {
      warn "\tPROCESSING $mod\n";
      my $new = $mod . '.new';
      open my $RO_FH, '<:raw', $mod or croak "Can not open file($mod): $!";
      open my $W_FH , '>:raw', $new or croak "Can not open file($new): $!";

      CHANGE_VERSION: while ( my $line = readline $RO_FH ) {
         if ( $line =~ RE_VERSION_LINE ) {
            my $oldv      = $1;
            my $remainder = $2;
            warn "\tCHANGED Version from $oldv to $dver\n";
            printf {$W_FH} VTEMP . $remainder, $dver;
            last CHANGE_VERSION;
         }
         print $W_FH $line;
      }

      my $ns  = $mod;
         $ns  =~ s{ [\\/]     }{::}xmsg;
         $ns  =~ s{ \A lib :: }{}xms;
         $ns  =~ s{ \. pm \z  }{}xms;
      my $pod = "\nThis document describes version C<$dver> of C<$ns>\n"
              . "released on C<$date>.\n"
              ;

      if ( $dver =~ m{[_]}xms ) {
         $pod .= "\nB<WARNING>: This version of the module is part of a\n"
              .  "developer (beta) release of the distribution and it is\n"
              .  "not suitable for production use.\n";
      }

      my $acl = $self->add_pod_author_copyright_license;
      my $acl_buf;

      CHANGE_POD: while ( my $line = readline $RO_FH ) {
         if ( $acl && $line =~ m{ \A =cut }xms ) {
            $acl_buf = $line; # buffer the last line
            last;
         }
         print $W_FH $line;
         print $W_FH $pod if $line =~ RE_POD_LINE;
      }

      if ( $acl && defined $acl_buf ) {
         warn "\tADDING AUTHOR COPYRIGHT LICENSE TO POD\n";
         print $W_FH $self->_pod_author_copyright_license, $acl_buf;
         while ( my $line = readline $RO_FH ) {
            print $W_FH $line;
         }
      }

      close $RO_FH or croak "Can not close file($mod): $!";
      close $W_FH  or croak "Can not close file($new): $!";

      unlink($mod) || croak "Can not remove original module($mod): $!";
      rename( $new, $mod ) || croak "Can not rename( $new, $mod ): $!";
      warn "\tRENAME Successful!\n";
   }

   return;
}

sub _build_monolith {
   my $self   = shift;
   my $files  = shift;
   my @mono_dir = ( monolithic_version => split /::/xms, $self->module_name );
   my $mono_file = pop(@mono_dir) . '.pm';
   my $dir    = File::Spec->catdir( @mono_dir );
   my $mono   = File::Spec->catfile( $dir, $mono_file );
   my $buffer = File::Spec->catfile( $dir, 'buffer.txt' );
   my $readme = File::Spec->catfile( qw( monolithic_version README ) );
   my $copy   = $mono . '.tmp';

   mkpath $dir;

   warn "STARTING TO BUILD MONOLITH\n";
   open my $MONO  , '>:raw', $mono   or die "Can not open file($mono): $!";
   open my $BUFFER, '>:raw', $buffer or die "Can not open file($buffer): $!";

   my %add_pod;
   my $POD = '';

   my @files;
   my $c;
   foreach my $f ( @{ $files }) {
      my(undef, undef, $base) = File::Spec->splitpath($f);
      if ( $base eq 'Constants.pm' ) {
         $c = $f;
         next;
      }
      push @files, $f;
   }
   push @files, $c;

   MONO_FILES: foreach my $mod ( reverse @files ) {
      my(undef, undef, $base) = File::Spec->splitpath($mod);
      warn "\tMERGE $mod\n";
      my $is_eof = 0;
      my $is_pre = $self->_monolith_add_to_top( $base );
      open my $RO_FH, '<:raw', $mod or die "Can not open file($mod): $!";
      MONO_MERGE: while ( my $line = readline $RO_FH ) {
         #print $MONO "{\n" if ! $curly_top{ $mod }++;
         my $chomped  = $line;
         chomp $chomped;
         $is_eof++ if $chomped eq '1;';
         my $no_pod   = $is_eof && $base ne $mono_file;
         $no_pod ? last MONO_MERGE
                 : do {
                     warn "\tADD POD FROM $mod\n"
                        if $is_eof && ! $add_pod{ $mod }++;
                  };
         $is_eof ? do { $POD .= $line; }
                 : do {
                     print { $is_pre ? $BUFFER : $MONO } $line;
                  };
      }
      close $RO_FH;
      #print $MONO "}\n";
   }
   close $MONO;
   close $BUFFER;

   ADD_PRE: {
      require File::Copy;
      File::Copy::copy( $mono, $copy ) or croak "Copy failed: $!";
      my @inc_files = map {
                        my $f = $_;
                        $f =~ s{    \\   }{/}xmsg;
                        $f =~ s{ \A lib/ }{}xms;
                        $f;
                     } @{ $files };

      my @packages = map {
                        my $m = $_;
                        $m =~ s{ [.]pm \z }{}xms;
                        $m =~ s{  /       }{::}xmsg;
                        $m;
                     } @inc_files;

      open my $W,    '>:raw', $mono or croak "Can not open file($mono): $!";

      printf {$W} q/BEGIN { $INC{$_} = 1 for qw(%s); }/, join q{ }, @inc_files
              or croak "Can not print to MONO file: $!";
      print  {$W} "\n" or croak "Can not print to MONO file: $!";

      foreach my $name ( @packages ) {
         print {$W} qq/package $name;\nsub ________monolith {}\n/
               or croak "Can not print to MONO file: $!";
      }

      open my $TOP,  '<:raw', $buffer or croak "Can not open file($buffer): $!";
      while ( my $line = <$TOP> ) {
         print {$W} $line or croak "Can not print to BUFFER file: $!";
      }
      close $TOP or croak 'Can not close BUFFER file';

      open my $COPY, '<:raw', $copy   or croak "Can not open file($copy): $!";
      while ( my $line = <$COPY> ) {
         print {$W} $line or croak "Can not print to COPY file: $!";
      }
      close $COPY or croak "Can not close COPY file: $!";

      close  $W or croak "Can not close MONO file: $!";
   }

   if ( $POD ) {
      open my $MONOX, '>>:raw', $mono or croak "Can not open file($mono): $!";
      foreach my $line ( split /\n/, $POD ) {
         print $MONOX $line, "\n";
         print $MONOX $self->_monolith_pod_warning if "$line\n" =~ RE_POD_LINE;
      }
      close $MONOX;
   }

   unlink $buffer or die "Can not delete $buffer $!";
   unlink $copy   or die "Can not delete $copy $!";

   print "\t";
   system( $^X, '-wc', $mono ) && die "$mono does not compile!\n";

   PROVE: {
      warn "\tTESTING MONOLITH\n";
      local $ENV{AUTHOR_TESTING_MONOLITH_BUILD} = 1;
      my @output = qx(prove -Imonolithic_version);
      print "\t$_" for @output;
      chomp(my $result = pop @output);
      die MONOLITH_TEST_FAIL if $result ne 'Result: PASS';
   }

   warn "\tADD README\n";
   $self->_write_file('>', $readme, $self->_monolith_readme);

   warn "\tADD TO MANIFEST\n";
   (my $monof   = $mono  ) =~ s{\\}{/}xmsg;
   (my $readmef = $readme) =~ s{\\}{/}xmsg;
   my $name = $self->module_name;
   $self->_write_file( '>>', 'MANIFEST',
      "$readmef\n",
      "$monof\tThe monolithic version of $name",
      " to ease dropping into web servers. Generated automatically.\n"
   );
   return;
}

sub _write_file {
   my($self, $mode, $file, @data) = @_;
   $mode = $mode . ':raw';
   open my $FH, $mode, $file or croak "Can not open file($file): $!";
   foreach my $content ( @data ) {
      print {$FH} $content or croak "Can not print to FH: $!";
   }
   close $FH or croak "Can not close $file $!";
   return;
}

sub _monolith_add_to_top {
   my $self = shift;
   my $base = shift;
   my $list = $self->monolith_add_to_top || die "monolith_add_to_top not set";
   die "monolith_add_to_top is not an ARRAY" if ref($list) ne 'ARRAY';
   foreach my $test ( @{ $list } ) {
      return 1 if $test eq $base;
   }
   return 0;
}

sub _monolith_readme {
   my $self = shift;
   my $pod  = $self->_monolith_pod_warning;
   $pod =~ s{B<(.+?)>}{$1}xmsg;
   return $pod;
}

sub _monolith_pod_warning {
   my $self = shift;
   my $name = $self->module_name;
   return <<"MONOLITH_POD_WARNING";

B<WARNING>! This is the monolithic version of $name
generated with an automatic build tool. If you experience problems
with this version, please install and use the supported standard
version. This version is B<NOT SUPPORTED>.
MONOLITH_POD_WARNING
}

sub _add_vanilla_makefile_pl {
   my $self = shift;
   my $file = 'Makefile.PL';
   return if -e $file; # do not overwrite
   $self->_write_file(  '>', $file, $self->_vanilla_makefile_pl );
   $self->_write_file( '>>', 'MANIFEST', "$file\tGenerated automatically\n");
   warn "ADDED VANILLA $file\n";
   return;
}

sub _vanilla_makefile_pl {
   <<'VANILLA_MAKEFILE_PL';
#!/usr/bin/env perl
use strict;
use ExtUtils::MakeMaker;
use lib qw( builder );
use Build::Spec qw( mm_spec );

my %spec = mm_spec;

WriteMakefile(
    NAME         => $spec{module_name},
    VERSION_FROM => $spec{VERSION_FROM},
    PREREQ_PM    => $spec{PREREQ_PM},
    PL_FILES     => {},
    ($] >= 5.005 ? (
    AUTHOR       => $spec{dist_author},
    ABSTRACT     => $spec{ABSTRACT},
    ) : ()),
);
VANILLA_MAKEFILE_PL
}

sub _pod_author_copyright_license {
   my $self = shift;
   my $da   = $self->dist_author; # support only 1 author for now
   my($author, $email) = $da->[0] =~ m{ (.+?) < ( .+?) > }xms;
   $author = $self->mytrim( $author );
   $email  = $self->mytrim( $email );
   my $cfy = $self->copyright_first_year;
   my $year = (localtime time)[5] + 1900;
   $year = "$cfy - $year" if $cfy && $cfy != $year && $cfy < $year;
   my $perl = sprintf( '%vd', $^V );
   return <<"POD";
=head1 AUTHOR

$author <$email>.

=head1 COPYRIGHT

Copyright $year $author. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version $perl or, 
at your option, any later version of Perl 5 you may have available.

POD
}

1;

__END__
