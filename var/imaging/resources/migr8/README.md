# Img Application Migration Tool 

Process for moving a specific application to a new host running 
[RHEL / CentOS 9](https://github.com/BlacksilverConsulting/OS9) or [RHEL / CentOS 8](https://github.com/BlacksilverConsulting/OS8).

## Create Migration File

Enter these commands on the existing host to package the application for migration:

```
# Download the exclusion list
( cd /tmp && wget https://github.com/BlacksilverConsulting/ImgOverlay/raw/main/var/imaging/resources/migr8/img-migr8-excludes )
# Download the inclusion list
( cd /tmp && wget https://github.com/BlacksilverConsulting/ImgOverlay/raw/main/var/imaging/resources/migr8/img-migr8-includes )
# Create the compressed archive (see note below)
( cd / && tar chzpf /tmp/img-migr8.tgz -X /tmp/img-migr8-excludes -T /tmp/img-migr8-includes usr/bin/img-* var/www/html/img-* )
```

### Note

If you are migrating from a mounted drive, rather than root, you will need to alter the `cd /` part of the command that creates the compressed archive to change to the directory that is at the root of the copy of the application you want to migrate. For example, if you have mounted an LVM snapshot of the old root at `/mnt/lv_root`, then you should `cd /mnt/lv_root` before running the `tar chzpf ...` command. The error `tar: var/www/html/images: File removed before we read it` can be ignored, that symlink will be fixed later.

If you want to verify that you have the correct directory, you can check for the file var/imaging/resources/amanda.txt, which has been present and unchanged since early 2012. For example, if you have mounted the drive containing the application at /mnt/lv_root, you could check for the file like this:

`( cd /mnt/lv_root && ls var/imaging/resources/amanda.txt )`

## Install Migrated Files

Move the /tmp/img-migr8.tgz file to the /tmp directory on the new host, then run these commands on the new host to set up the application:

```
# This assumes the pg1[04].yaml and dm.yaml playbooks have already been run
# ( https://github.com/BlacksilverConsulting/OS9 )
tar zxf /tmp/img-migr8.tgz -C /
# The next line patches the application to work with modern OSes
for p in /root/ImgOverlay-main/var/imaging/patches/*.patch; do ( cd / && patch -p0 -N -r- -i $p ); done
# This is also a good time to apply the tess.yaml playbook if that's your thing:
ansible-playbook ~/tess.yaml
# NOTE: If you have not yet initialized CPAN on this machine, do it now or the next command will hang until you press Enter unprompted.
# The is the system configuration script for the application:
sysupdate.pl force
# This is the application's background service for file and queue processing:
service imaging-listener restart
```

## Explanation

When the application was shipped by the original vendor (before it was abandoned), they used a script to generate a compressed archive file (.tgz). This process is similar, but starts with the running application on an installed system instead of a private repository.

The [img-migr8-excludes](https://github.com/BlacksilverConsulting/ImgOverlay/raw/main/var/imaging/resources/migr8/img-migr8-excludes) file is used to skip over files that may have accumulated on the existing server but do not need to be copied (`.trash.*`, mostly). It also omits support libraries that are installed by [dm.yaml](https://github.com/BlacksilverConsulting/OS9/blob/main/dm.yaml).

The [img-migr8-includes](https://github.com/BlacksilverConsulting/ImgOverlay/raw/main/var/imaging/resources/migr8/img-migr8-includes) file is a list of directories and specific files that should be included. The `tar` command does not support globbing (wildcard shell expansion) in this file, so the paths that need globbing are included on the command line separately.

The command to create the migration file should run very quickly (completion in less than 10 seconds on a typical system), and generate a file of about 15MB.

## Database Migration

If you also need to move the application database from the old host to a new one, run this command on the old host to make a copy of the live database:

`su - postgres -c "pg_dump images | gzip > /tmp/img-migr8.dump.gz"`

If you are migrating from a system that is not live (mounted), and you did not specifically take a backup while it was running, you can copy the last daily automatic backup:

`cp /mnt/lv_root/home/backup/images-daily.dump.gz /tmp/img-migr8.dump.gz`

(As above, alter the source path to match your circumstances. This example shows the old system mounted at `/mnt/lv_root`.)

After you transfer the file to the new host, you can restore it like this:

`su - postgres -c "createdb images;"`

`su - postgres -c "gunzip -c /tmp/img-migr8.dump.gz | psql images"`

If the `createdb` command fails because the database already exists, you can delete it like this:

`su - postgres -c "dropdb images;"`

Restore time will vary **widely** depending on many factors. Some of the individual steps within the restore process can take minutes to complete.

## Document File Migration

The application database does not contain the document files; the are stored in the file system, usually at `/usr/images`. The directory structure divides the eight-character (hexadecimal) document ID into four groups (octets) of two characters each. The first three groups are used as directory names, and the last group is the base file name. For example, if document 12345678 is a TIFF file, it will be at `/usr/images/12/34/56/78.tif`. This deep structure (up to 16.7 million directories) is very efficient for normal operations, but can run into memory limitations during migration operations. To address this, divide the operation into smaller chunks. For example, this will copy all of the documents from `/mnt/data/lv_data/images`:

```
for i in 0 1 2 3 4 5 6 7 8 9 a b c d e f; do
  for j in 0 1 2 3 4 5 6 7 8 9 a b c d e f; do
    echo `date`: Migrate partition $i$j
    cp -prv /mnt/data/lv_data/images/$i$j /usr/images
    # Assumes SSH trust is already set up:
    # rsync -progv /usr/images/$i$j root@newhost:/usr/images
  done
done
```

Similar loops should be used with `scp` and `rsync`.
