The file sysmlv2 is an example of a parsing tool to evaluate requirmetns with constraints. 
1 - The important function starts at line 30
2 - The hards parts are lines 48-55 where varaibles are exposed to the local fuction
3 - Line 102 where the constraint string is evaluated 2x live. 
	A - first eval extracts the string locally
	B - second eval evalueates the string as an equation  