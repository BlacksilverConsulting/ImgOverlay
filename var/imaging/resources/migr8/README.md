# Img Application Migration Tool
Tools for moving a specific application to a new host.

On the old host:

1. Fetch the file(s) <- FIXME
2. Unpack the file(s) <- FIXME
3. Run this command `(cd / && tar czpf /tmp/img-migr8.tgz -X /tmp/img-migr8-excludes -T /tmp/img-migr8-includes usr/bin/img-* var/www/html/img-*)`
4. Move /tmp/img-migr8.tgz to /tmp on the new host

On the new host:

1. Unpack with `tar zxf /tmp/img-migr8.tgz -C /`
2. Apply system configuration with `sysupdate.pl`
3. Start the listener service with `service imaging-listener restart`

## Note

If you are migrating from a mounted drive, rather than root, you will need to alter the `cd /` part of the command above to change to the directory that is at the root of the copy of the application you want to migrate.

If you want to verify that you have the correct directory, you can check for the file var/imaging/resources/amanda.txt, which has been present and unchanged since early 2012. For example, if you have mounted the drive with the application at /mnt/lv_root, you could check for the file like this:

`(cd /mnt/lv_root && ls var/imaging/resources/amanda.txt)`

## Explanation

When the application was shipped by the original vendor (before it was abandoned), they used a script to generate a compressed archive file (.tgz). This process is similar, but starts with the running application on an installed system instead of a private repository.

The `img-migr8-excludes` file is used to skip over files that may have accumulated on the existing server but do not need to be copied (.trash., mostly) and support libraries that are installed by [dm.yaml](https://github.com/BlacksilverConsulting/OS9/blob/main/dm.yaml).

The `img-migr8-includes` file is a list of directories and specific files that should be included. It does not support globbing (wildcard shell expansion), so those are included on the command line separately.