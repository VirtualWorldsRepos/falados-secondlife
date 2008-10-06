== Introduction ==

Thank you for downloading Open Round Table. These are open source scripts that can turn any table/chair combination into a prim-saving chair-rezer that always has 1 seat available.  Please follow the simple instructure in order to get this up and running.

== Getting Started ==

Thinks you'll need:
    Configuration: Config
    Table Script: ort-Table or Table Anchor object
    Chair Script: ort-Chair or Chair Anchor object
    Any Object that will function as a table
    Another object that will function as a chair
    
=== Step 1 ===

Rez your table on the ground. Make sure the table is rotated 0 degrees on each axis.
If your table is facing an odd direction, you can accomplish this by linking it with an transparent prim.
The transparent prim will be the root prim, and the rest of the table will be child prims. 
If you do not follow this, the chairs will most likely rez in the wrong directions.

You can use the Table Anchor which is provided and link your table to it.  Be sure to rotate 
the table anchor to zero degrees on each axis. Then select your table first and then the anchor.
Position the Table anchor at about the center of the chair.
Link them together by pressing Ctrl + L

=== Step 2 ===

Put the ort-Table script and the Config notecard inside your table

=== Step 3 ===

Edit the Config Notecard inside your table,  Every other line is a value you can edit.
Do not edit the structure of the notecard aside from replacing the values!
Be sure to set the name of the chair object in the notecard.
Save the notecard when you are finished.

=== Step 4 ===

Rez your Chair object. Put the ort-Chair script inside of it.
Name it after the same name you put in the Config notecard.

You can use the Chair Anchor which is provided and link your chair to it.  Be sure to rotate 
the chair anchor to zero degrees on each axis. Then select your chair first and then the anchor.
Position the Chair anchor at about the center of the chair.
Link them together by pressing Ctrl + L

Take it back into inventory

=== Step 5 ===

Put your Chair inside the Table.  The table should automatically set itself up according to your configuration.

=== Step 6 === 

If you are unhappy with the setup, tweak the Config notecard to your liking.
