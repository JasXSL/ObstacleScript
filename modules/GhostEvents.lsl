#define USE_STATE_ENTRY
#define USE_SENSOR
#define USE_NO_SENSOR
#define USE_PLAYERS
#define USE_HUDS
#define USE_TIMER
#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"
#include "ObstacleScript/index.lsl"


int BFL;
#define BFL_LIGHT_POPPED 0x1		// Can only pop one light

list cObjs; // (key)id
int GHOST_TYPE;
int EVIDENCE_TYPES;


int evtHit;
int evtType;
int subType;
list evtPlayers;
float evtDur;

// Searches desc for a specific type
list getDescType( key id, str type ){
	
	list d = split(prDesc(id), "$$");
	
    integer s;
    for(; s < count(d); ++s ){
        
		list sub = split(l2s(d, s), "$");
        if( l2s(sub, 0) == type )
			return sub;
			
    }
	return [];

}

// Returns 1 if door, 0 if not door, -1 if not interactive
integer isInteractive( key id ){
    
	str name = llKey2Name(id);
	if( name == "HOTS" && EVIDENCE_TYPES & GhostConst$evidence$hots ){
		
		// GHOST BEHAVIOR :: Gooryo - Don't touch hots if a player is within 4m
		vector g = llGetPos();
		forPlayer(i, k)
			if( llVecDist(g, prPos(k)) < 4 && ~llGetAgentInfo(k) & AGENT_SITTING )
				return -1;
		end
		
		return 0;
		
	}
	
	if( name == "Ecchisketch" && EVIDENCE_TYPES & GhostConst$evidence$writing )
		return 0;
	
	if( getDescType(id, Desc$TASK_DOOR_STAT) )
		return 1;
	if( getDescType(id, Desc$TASK_GHOST_INTERACTIVE) ){
		
		// GHOST BEHAVIOR :: BARE - Don't turn on lights
		list ls = getDescType(id, Desc$TASK_LIGHT_SWITCH);
		if( GHOST_TYPE == GhostConst$type$bare && ls != [] && !l2i(ls, 1) )
			return -1;
			
		return 0;
		
	}
	
    return -1;

}


onGhostEventStart(){
	Level$raiseEvent(LevelCustomType$GHOSTEVT, LevelCustomEvt$GHOSTEVT$evt, mkarr(evtPlayers) + evtType + subType + evtDur);
	raiseEvent(GhostEventsEvt$begin, mkarr(evtPlayers) + evtType + subType + evtDur );
}

#include "ObstacleScript/begin.lsl"

onStateEntry()

    llSensorRepeat("", "", ACTIVE|PASSIVE, 8, PI, 1);
	Portal$scriptOnline();
    
end

onSensor( total )
    
	vector gp = llGetPos();
    cObjs = [];
    integer i;
    for(; i < total; ++i ){
        
		
		key dk = llDetectedKey(i);
		vector dp = llDetectedPos(i);
		integer intr = isInteractive(llDetectedKey(i));
		if( ~intr && llFabs(gp.z-dp.z) < 1.5 )
			cObjs += (list)dk;
		
    }
    
end

onNoSensor()
    
    cObjs = [];

end

onGhostType( type, evidence )
	
	GHOST_TYPE = type;
	EVIDENCE_TYPES = evidence;
	
end

handleTimer( "END" )
	
	if( evtType == GhostEventsConst$IT_LIGHTS ){
	
		if( subType == GhostEventsConst$ITL_BREAKER )
			Lamp$toggle( "BREAKER", false );
		else if( subType == GhostEventsConst$ITL_ELECTRONICS ){
			
			GhostTool$emp();
			llTriggerSound("338f43a4-4165-12a5-43d7-1f770a244457", 1);
			
		}

	}
	
	
	
	// Ugly, but functional finisher
	if( evtType == GhostEventsConst$IT_POSSESS && subType == GhostEventsConst$ITP_SPANK ){
		AnimHandler$anim(
			l2k(evtPlayers, 0), 
			"butthurt", 
			TRUE, 
			2, 
			0
		);
		llSleep(2);
	}
	
	unsetTimer("EVT");
	raiseEvent(GhostEventsEvt$end, evtPlayers + evtType + subType );
	int i;
	for( ; i < count(evtPlayers); ++i ){
		Rlv$unsetFlags( l2k(evtPlayers, i), RlvFlags$IMMOBILE, FALSE );
	}
	

end

handleTimer( "EVT" )

	if( evtType == GhostEventsConst$IT_POSSESS && subType == GhostEventsConst$ITP_SPANK ){
		
		++evtHit;
		str anim = "wall_spank_hit";
		if( evtHit%2 )
			anim += "_2";
		key targ = l2k(evtPlayers, 0);
		AnimHandler$anim(
			targ, 
			anim, 
			TRUE, 
			0, 
			0
		);
		Rlv$triggerSound( targ, "78603eaa-5e77-7d9c-9c99-d6b3d82d6e40", .5 );
		setTimeout("EVT", .5+llFrand(1));
		
	}


end



handleOwnerMethod( GhostEventsMethod$trigger )
	
	list viable = (list)
		GhostEventsConst$IT_LIGHTS
	;
	if( GHOST_TYPE != GhostConst$type$jim ){
		
		viable += (list)
			GhostEventsConst$IT_DOORS +
			GhostEventsConst$IT_POSSESS
		;
		
	}
	
viable = (list)GhostEventsConst$IT_LIGHTS;
	
	viable = llListRandomize(viable, 1);
	

	key closest; float dist;
	forPlayer(i,k)
		float d = llVecDist(llGetPos(), prPos(closest));
		if( dist <= 0 || d < dist ){
			
			dist = d;
			closest = k;
			
		}
	end
	evtPlayers = (list)closest;
	
	integer v;
	for(; v < count(viable); ++v ){
		
		int type = l2i(viable, v);
		evtType = type;
		
		if( type == GhostEventsConst$IT_LIGHTS ){
			
			list viable = (list)
				GhostEventsConst$ITL_BREAKER +
				GhostEventsConst$ITL_ELECTRONICS
			;
			if( ~BFL & BFL_LIGHT_POPPED )
				viable += GhostEventsConst$ITL_POP;
			
			type = l2i(viable, llFloor(llFrand(count(viable))));
			
type = GhostEventsConst$ITL_ELECTRONICS;
			subType = type;
			evtDur = 2+llFrand(4);
			

			
			if( type == GhostEventsConst$ITL_POP ){
				
				evtDur = 2.5;
				// #AUX handles the rest through the ghost event
				BFL = BFL|BFL_LIGHT_POPPED;
				
			}
			/*
			Handled at the end
			else if( type == GhostEventsConst$ITL_ELECTRONICS ){
				
			}
			*/
			/* Handled at end
			else if( type == GhostEventsConst$ITL_BREAKER ){
				
			}
			*/
				
			setTimeout("END", evtDur);
			onGhostEventStart();
			return;
				
		}
		
		if( type == GhostEventsConst$IT_DOORS ){
			
			subType = 0;
			qd("Todo: Slam doors");
			evtDur = 3+llFrand(3);
			setTimeout("END", evtDur);
			onGhostEventStart();
			return;
		
		}
		
		if( type == GhostEventsConst$IT_POSSESS ){
			
			list vi = llListRandomize((list)
				GhostEventsConst$ITP_RUB_UNI +
				GhostEventsConst$ITP_RUB_F +
				GhostEventsConst$ITP_RUB_DUO +
				GhostEventsConst$ITP_SPANK +
				GhostEventsConst$ITP_DRAG
			, 1);
			
			list targets;
			vector gp = llGetPos();
			forHuds( idx, k )
				
				list ray = llCastRay(gp, prPos(k), RC_DEFAULT);
				if( l2i(ray, -1) == 0 )
					targets += k;
			
			end

			if( targets ){
				
				targets = llListRandomize(targets, 1);
				
				int success;
				int i; float timeout;
				for(; i < count(vi) && !success; ++i ){
					
					type = l2i(vi, i);
					subType = type;
					// Rub self or self F
					if( type == GhostEventsConst$ITP_RUB_UNI || type == GhostEventsConst$ITP_RUB_F ){
						
						list subset;
						int sub;
						for(; sub < count(targets); ++sub ){
						
							key t = l2k(targets, sub);
							if( type == GhostEventsConst$ITP_RUB_UNI || Rlv$getDesc$sex(t) & GENITALS_BREASTS )
								subset += t; 
								
						}
						
						if( subset ){
							
							str anim = "rubself";
							if( type == GhostEventsConst$ITP_RUB_F )
								anim = "rubself_f";
							
							key target = randElem(subset);
							evtPlayers = (list)target;
							
							timeout = 4+llFrand(4);
							AnimHandler$anim(
								target, 
								anim, 
								TRUE, 
								timeout, 
								0
							);
							Rlv$setFlags( target, RlvFlags$IMMOBILE, FALSE );
							
							success = true;
							
						}
						
					}
					else if( type == GhostEventsConst$ITP_RUB_DUO && count(targets) > 1 ){
					
						vector aPos; vector bPos;
						// Find if there are two players with LOS
						int sub;
						key a; key b;
						for(; sub < count(targets) && b == ""; ++sub ){
							
							a = l2k(targets, sub);
							aPos = prPos(a);
							list ray = llCastRay(aPos, aPos-<0,0,4>, RC_DEFAULT + RC_DATA_FLAGS + RC_GET_NORMAL);
							vector n = l2v(ray, 2);
							vector p = l2v(ray, 1);
							int ssub;
							for( ssub = sub+1; ssub < count(targets) && b == "" && n.z > 0.9; ++ssub ){
								
								key bp = l2k(targets, ssub);
								bPos = prPos(bp);
								ray = llCastRay(aPos, bPos, RC_DEFAULT);
								list fl = llCastRay(
									aPos+llVecNorm(bPos-aPos)*.5, 
									aPos+llVecNorm(bPos-aPos)*.5-<0,0,4>, 
									RC_DEFAULT
								);
								
								vector pos = l2v(fl, 1);
								if( 
									l2i(ray, -1) == 0 && 
									l2i(fl, -1) == 1 && 
									llFabs(pos.z-p.z) < .5 
								){
								
									b = bp;
									bPos = pos;
									aPos = p;
									
								}
							}
							
						}
					
						if( b != "" ){
							
							a = llGetOwnerKey(a);
							b = llGetOwnerKey(b);
							
							timeout = 4+llFrand(2);
							success = true;
							evtPlayers = (list)a + b;
							vector as = llGetAgentSize(a);
							aPos.z += as.z/2*.8;
							vector offs = bPos-aPos;
							offs = llVecNorm(<offs.x, offs.y, 0>);
							rotation rot = llRotBetween(<1,0,0>, offs);
							
							vector bPos = aPos+offs*.5;
							
							list tasks = (list)
								SupportCubeBuildTask(SupportCube$tSetPos, aPos) +
								SupportCubeBuildTask(SupportCube$tSetRot, rot) +
								SupportCubeBuildTask(SupportCube$tForceSit, FALSE) +
								SupportCubeBuildTask(SupportCube$tRunMethod, 
									a + "AnimHandler" + AnimHandlerMethod$anim + mkarr("rub_other_a" + TRUE + timeout)
								) +
								SupportCubeBuildTask(SupportCube$tDelay, timeout) +
								SupportCubeBuildTask(SupportCube$tForceUnsit, [])
							;
							Rlv$cubeTask( a, tasks );
							tasks = (list)
								SupportCubeBuildTask(SupportCube$tSetPos, bPos) +
								SupportCubeBuildTask(SupportCube$tSetRot, (llEuler2Rot(<0,0,PI>)*rot)) +
								SupportCubeBuildTask(SupportCube$tForceSit, FALSE) +
								SupportCubeBuildTask(SupportCube$tRunMethod, 
									b + "AnimHandler" + AnimHandlerMethod$anim + mkarr("rub_other_t" + TRUE + timeout)
								) +
								SupportCubeBuildTask(SupportCube$tDelay, timeout) +
								SupportCubeBuildTask(SupportCube$tForceUnsit, [])
							;
							Rlv$cubeTask( b, tasks );
							
						}
						
					}
					else if( type == GhostEventsConst$ITP_SPANK ){
						
						list ray;
						int i; key targ; vector wall; vector norm;
						for( ; i < count(targets) && targ == ""; ++i ){
							
							key pl = l2k(targets, i);
							vector pos = prPos(pl);
							int dir;
							for(; dir < 4 && targ == ""; ++dir ){
								
								list ray = llCastRay(pos, pos+<3,0,0>*llEuler2Rot(<0,0,PI_BY_TWO*dir>), RC_DEFAULT + RC_DATA_FLAGS + RC_GET_NORMAL);
								vector n = l2v(ray, 2);
								if( llKey2Name(l2k(ray, 0)) == "WALL" && llFabs(n.z) < 0.05 ){
									
									n.z = 0;
									n = llVecNorm(n)*.9;
									vector offs = l2v(ray, 1)+n;
									// Get floor
									list r2 = llCastRay(offs, offs-<0,0,3>, RC_DEFAULT + RC_DATA_FLAGS + RC_GET_NORMAL );
									vector fn = l2v(r2, 2);
									if( l2i(r2, -1) == 1 && fn.z > 0.95 ){
										
										vector size = llGetAgentSize(llGetOwnerKey(pl));
										wall = l2v(r2, 1)+<0,0,size.z/2*.8>;
										norm = n;
										targ = pl;
									
									}
									
								}
								
							}
							
						}
						
						if( targ ){
							
							timeout = 6+llFrand(4);
							evtPlayers = (list)targ;
							Rlv$cubeTask( targ,  
								SupportCubeBuildTask(SupportCube$tSetPos, wall) +
								SupportCubeBuildTask(SupportCube$tSetRot, (llRotBetween(<1,0,0>, -norm))) +
								SupportCubeBuildTask(SupportCube$tForceSit, false) +
								SupportCubeBuildTask(SupportCube$tDelay, (timeout+2)) +
								SupportCubeBuildTask(SupportCube$tForceUnsit, true)
							);
							AnimHandler$anim(
								targ, 
								"wall_spank_loop", 
								TRUE, 
								timeout, 
								0
							);							
							success = true;
							setTimeout("EVT", 1.5);
						
						}
						
					}
					else if( type == GhostEventsConst$ITP_DRAG ){
					
						int i; key targ; rotation evtRot; vector evtPos; vector evtEnd;
						for(; i < count(targets) && targ == ""; ++i ){
							
							key pl = l2k(targets, i);
							vector rot = llRot2Euler(prRot(pl));
							vector pp = prPos(pl);
							rot = <0,0,rot.z>;
							vector ep = pp+<-4,0,0>*llEuler2Rot(rot);
							
							list ray = llCastRay(pp, ep, RC_DEFAULT);
							if( l2i(ray, -1) == 0 ){
							
								list r2 = llCastRay(pp, pp-<0,0,3>, RC_DEFAULT);
								list r3 = llCastRay(ep, ep-<0,0,3>, RC_DEFAULT);
								vector v1 = l2v(r2, 1); vector v2 = l2v(r3, 1);
								if( l2i(r2, -1) == 1 && l2i(r3, -1) == 1 && llFabs(v1.z-v2.z) < 1 ){
								
									targ = pl;
									vector as = llGetAgentSize(llGetOwnerKey(pl));
									evtPos = v1+<0,0,as.z/2*.8>;
									evtEnd = v2+<0,0,as.z/2*.8>;
									evtRot = llRotBetween(<1,0,0>, llVecNorm(evtPos-evtEnd));								
								}
								
							}		
							
						}
						
						if( targ ){
							
							success = true;
							evtPlayers = (list)targ;
							
							list tasks = (list)
								SupportCubeBuildTask(SupportCube$tSetPos, evtPos) +
								SupportCubeBuildTask(SupportCube$tSetRot, evtRot) +
								
								SupportCubeBuildTask(SupportCube$tForceSit, FALSE + TRUE) +
								SupportCubeBuildTask(SupportCube$tRunMethod, 
									targ + "AnimHandler" + AnimHandlerMethod$anim + mkarr("knockdown_drag" + TRUE + 3)
								) +
								SupportCubeBuildTask(SupportCube$tDelay, 1.5) +
								
								SupportCubeBuildTask(SupportCube$tKFM, mkarr((evtEnd-evtPos) + ZERO_ROTATION + 1.2)) +
								
								SupportCubeBuildTask(SupportCube$tDelay, 1.2) +
								
								SupportCubeBuildTask(SupportCube$tRunMethod, 
									targ + 
									"AnimHandler" + 
									AnimHandlerMethod$anim + 
									mkarr("knockdown_drag_stand" + TRUE)
								) +
								
								SupportCubeBuildTask(SupportCube$tDelay, 1.5) +
								
								SupportCubeBuildTask(SupportCube$tForceUnsit, [])
							;
							timeout = 4.2;
							Rlv$cubeTask( targ, tasks );
						
						}
						
					}
					
				
				}
				
				if( success ){
				
					setTimeout("END", timeout);
					evtDur = timeout;
					onGhostEventStart();
					return;
					
				}
				
			}
		
		}
	
	}

end


#include "ObstacleScript/end.lsl"


