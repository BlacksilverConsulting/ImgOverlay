#!/usr/bin/env perl

use strict;
use warnings;
use English;
use v5.32;

=pod

General plan:
- Connect to the database
- Parse setting 1241 as a space-separated list of division names
- Call an sta that returns a list of group numbers in those divisions
- Loop over
-- Create a new TmwUnkGroup object for this group
-- Commit it
-- Log the error if there was one
- Exit

=cut

# CPAN Modules
use Log::LogLite;

# TMW Modules
use lib "/var/imaging/lib";
use Tmw qw(:all);
use TmwDB qw(:all);
use TmwUnkGroup;

uniquestart;

my $dbh = &dbhandle;
die "Can't connect to database!"
    unless defined $dbh;

my $_loglevel = getsysparm( "System", "Logging Level" ) || 6;
my $_log      = Log::LogLite->new( '/var/log/listener', $_loglevel )
    or die "Can't open Log::LogLite";
$_log->default_message("$PROGRAM_NAME ($PID): ");
my @_log_prefix = (
    'PANIC', 'FAILURE', 'CRITICAL', 'ERROR', 'WARNING', 'NOTICE',
    'INFO',  'DEBUG',   'DEBUG',    'DEBUG', 'DEBUG'
);

sub logx {
    my ( $message_level, $message_text ) = @_;
    $message_level ||= 6;
    $_log->write( $_log_prefix[$message_level] . ": " . $message_text,
        $message_level );
    print "DEBUG: $message_text\n"
        if $_loglevel > 6 and $message_level <= $_loglevel;
    return;
}

logx 6, "Starting.";

sub closedb {
    return $dbh->disconnect;
}

my $pgany_divs = pgany( getsysparmlist( 'Templating', 'Auto-commit divisions') );
if ( $pgany_divs !~ /\w/ ) {
    logx 5, "No auto-commit divisions found, exiting peacefully.";
    exit 0;
}

my @grouprows = flatten st( 'GetGroupsByDivisions', $pgany_divs );
my $count = 0;

for my $groupnum ( @grouprows ) {
  my $unkgrp = TmwUnkGroup->load( GROUP => $groupnum );
  if ( $unkgrp->{errstr} ) { 
    logx 4, "Failed to load group [$groupnum]: " . $unkgrp->error;
    next;
  }
  $unkgrp->Commit();
  if ( $unkgrp->{errstr} ) { 
    logx 4, "Failed to commit group [$groupnum]: " . $unkgrp->error;
  }
  $count++;
}

logx 6, "All done. Committed [$count].";

__END__