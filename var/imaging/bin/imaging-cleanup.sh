#!/bin/bash

# This script is called by systemd
# at startup to do some application
# maintenance.

LOG='/var/log/listener'
LOCKFILE='/var/imaging/locks/listener-stop'
SPOOLFILE='/var/spool/mail/listener'

echo "[`date` imaging-cleanup ($$)] Begin application cleanup" >> $LOG

# Remove the listener stop flag if it is present:
[ -e $LOCKFILE ] && rm -f $LOCKFILE

# Incomplete uploads can leave empty files behind,
# so we clean them up if the FTP service is not running:
[ -e /var/lock/subsys/vsftpd ] && find /home -type f -empty -exec rm -f \{\} \;

# This user receives internal email that will never
# be read, so just delete it:
[ -e $SPOOLFILE ] && rm -f $SPOOLFILE

# If the email fetch process crashed, it may have left
# a lock behind, so clean them up:
[ -e /tmp/.imaging-email-import*.pid ] && rm -f /tmp/.imaging-email-import*.pid

# Samba .tdb files can get corrupted sometimes and break things.
# They are regenerated as needed, so they are safe to remove:
rm -f /etc/samba/*.tdb
rm -f /var/cache/samba/*.tdb
rm -f /var/cache/samba/printing/*.tdb

# Some very old systems might not have a page count
# in the database for every document. This adds one:
nice /usr/bin/img-util-cleanup.pl -p &

# Problems during the commit process can leave stray files
# in /usr/images/inqueue that do not have matching database
# records. This removes the files:
nice /var/imaging/bin/img-util-inqueue.pl &
