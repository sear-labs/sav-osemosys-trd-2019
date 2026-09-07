* Export the model's instance data to a GDX, for conversion to open CSVs.
*
*   gams export_data.gms --GDXFILE=<path>
*
* The data lives inline in a 1,889-line GAMS file, so reading the instance currently
* requires a GAMS licence. This exports it so the Python port - and any reader - can
* work from plain CSVs instead. Nothing is modified: this includes the data file and
* unloads what it built.
*
* Note FMT arrives here ALREADY multiplied by the data file's scalar DM. The Python
* port recovers the base row the same way model/osemosys_scenario.gms does, so both
* start from the same numbers.

$if not set GDXFILE $abort 'GDXFILE not set'

$include ATX_Integrated_Final_Fleet.gms

execute_unload "%GDXFILE%";
