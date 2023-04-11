--- /var/imaging/subsys/Templates/setupdb/9999000207.pl 2023-04-10 21:51:47.077809071 -0400
+++ -   2023-04-10 21:54:29.630753742 -0400
@@ -121,7 +121,7 @@
     # Create function
     $dbh->do(<<ENDSQL)
 CREATE OR REPLACE FUNCTION $fname( )
-  RETURNS opaque
+  RETURNS trigger
   AS 'BEGIN
   $deletes
   RETURN OLD;
@@ -166,7 +166,7 @@
  -- img_Page is referenced by img_PageEvent, img_PageIndex, and img_WorkQueue

  CREATE OR REPLACE FUNCTION f_cascade_img_page( )
-  RETURNS opaque
+  RETURNS trigger
   AS '
  BEGIN
   DELETE FROM img_PageEvent WHERE hdr_IntDocID = OLD.hdr_IntDocID;
