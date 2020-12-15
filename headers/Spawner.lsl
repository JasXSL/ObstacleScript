#ifndef __Spawner
#define __Spawner

#define SpawnerMethod$reset 0				// Resets the script
#define SpawnerMethod$callbackRepoEnum 1	// asset1, asset2... - Handles callback from Repo which lists what objects it can hand out
#define SpawnerMethod$callbackRepoFetch 2	// void - All requested items have been delivered
#define SpawnerMethod$callbackPortalSave 3	// void - Saves the selected portal item


#define SpawnerMethod$load 10				// (str)callback, (bool)live, (str)group1, group2... - Loads one or more groups of objects. Callback is raised as an event in the linkset. Use JSON_INVALID if you don't want an event
#define SpawnerMethod$listSpawns 11			// Outputs an indexed list of spawns
#define SpawnerMethod$purge 12				// Purges all spawns
#define SpawnerMethod$delete 13				// (int)index
#define SpawnerMethod$add 14				// void - Adds said object, use $ notation to save description
#define SpawnerMethod$savePortals 15		// (str)batch - Adds all spawned portals to the DB
#define SpawnerMethod$setSpawnValue 16		// (int)spawnIndex, (int)paramIndex, (var)value - Updates a spawn value
#define SpawnerMethod$spawnByIndex 17		// (int)live, (int)index1, index2... - Spawns one or many items by index


#define SpawnerConst$CB_GAME_START "_G_"


#define Spawner$add( targ ) \
	runMethod(targ, "Spawner", SpawnerMethod$add, [])


#define Spawner$load( targ, groups, live, callback ) \
	runMethod(targ, "Spawner", SpawnerMethod$load, callback +live + groups)

#define Spawner$spawnGame() \
	Spawner$load( LINK_THIS, "", TRUE, SpawnerConst$CB_GAME_START )


#endif
