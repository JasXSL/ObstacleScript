// This is a tool script that checks through Desc$TASK_SOUND_LOOP in a linkset and updates the sound loops accordingly, then this script deletes itself
// I suggest making one in your inventory, then dropping it into the linkset and have it update and auto delete
/*
    Desc syntax:
    S$<uuid>$vol$radius
*/
#include "obstaclescript/index.lsl"
default
{
    state_entry()
    {
		llOwnerSay("Starting update");
        integer set;
        forLink(nr, name)
            
            set += updateLinkSoundLoop(nr);
            
        end
        
        llOwnerSay((string)set+" sounds updated");
        llRemoveInventory(llGetScriptName());
    }

}


