#include "./index.lsl"


// Type contains the event or method
// Script is the script that raised the event. If the call is a method, script is "!"
// If it's a special case event like setting players, _sc is ":"
// Sender is the id of the user that send a method, or "" if it's internal
// evdta is a list of the data attached

onEvent( int _ty, string _sc, key _se, list _dta ){
	// Owner flags. 0b1 = is_internal, 0b10 = is_owner
	int _of = 
		(_se == "")|
		((llGetOwnerKey(_se) == llGetOwner())<<1)
	;

