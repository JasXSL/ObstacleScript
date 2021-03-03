#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"
#define BAR_SIZE <0.22981, 0.06894, 0.02039>
#define BUTTON_SIZE <0.06, 0.06, 0.06>

list BARS = ["","",""];  // (str)label
list BAR_SETTINGS = [0,0,0];
#define BAR_HAS_ICON 0x1

list BUTTONS = ["","","","","","","",""];  // (str)label
list INSTRUCTIONS = [];		// Instruction prims

integer CTDN;

// Tries to get a bar by label
integer getBar( string label ){
    
    integer i;
    for(; i < count(BARS); ++i ){
        
        if( l2s(BARS, i) == label )
            return i;
            
    }
    return -1;
    
}
// Gets a bar index if it already exists, or tries to find a new one
integer getBarCreateIndex( string label ){
    
    integer idx = getBar(label);
    if( ~idx )
        return idx;
    
    integer i;
    for(; i < count(BARS); ++i ){
        
        if( l2s(BARS, i) == "" ){
            
            BARS = llListReplaceList(BARS, (list)label, i, i);            
            return i;
            
        }
        
    } 
    
    llDialog(
        llGetOwner(), 
        "Error: Level is trying to create more than 3 bars", 
        [], 
        132
    );
    return -1;
    
}

integer getButton( string label ){
    
    integer i;
    for(; i < count(BUTTONS); ++i ){
        
        if( l2s(BUTTONS, i) == label )
            return i;
            
    }
    return -1;
    
}

integer getButtonCreateIndex( string label ){
    
    integer idx = getButton(label);
    if( ~idx )
        return idx;
    
    integer i;
    for(; i < count(BUTTONS); ++i ){
        
        if( l2s(BUTTONS, i) == "" ){
            
            BUTTONS = llListReplaceList(BUTTONS, (list)label, i, i);            
            return i;
            
        }
        
    } 
    
    llDialog(
        llGetOwner(), 
        "Error: Level is trying to create more than 8 buttons", 
        [], 
        132
    );
    return -1;
    
}

updateBarPositions(){
    
    vector size = BAR_SIZE;
    vector start = <0,0,.16>;
    list toSet;
    integer i;
    integer hasIcon;
    for(; i < count(BARS); ++i ){
        
        if( l2s(BARS, i) ){
            
            toSet += i;
            integer flags = l2i(BAR_SETTINGS, i);
            float width = size.x;
            if( flags & BAR_HAS_ICON )
                hasIcon = TRUE;
            
        }
        
    }
    
    if( toSet == [] )
		return;
    
    float width = size.x;
    if( !hasIcon )
        width *= 0.8;
    else
        width *= 0.95;
    
    float totalWidth = width*count(toSet);

    start.x = totalWidth/2+totalWidth/(count(toSet)*2);
    float x = 0;

    list dta;
    for( i = 0; i < count(toSet); ++i ){
        
        integer bar = l2i(toSet, i);
        integer flags = l2i(BAR_SETTINGS, bar);
        
        // Coordinates use Y left and Z up for some reason
        x += width;
        vector pos = start-<x, 0,0>;
        pos.y = pos.x;
        pos.x = 0;
        
        dta += (list)PRIM_LINK_TARGET + l2i(pBARS, bar) +
            PRIM_POSITION + pos
        ;
        
    } 
    llSetLinkPrimitiveParamsFast(0, dta);
    
}

updateButtonPositions(){
    
    // Todo
    vector size = BUTTON_SIZE;
    vector start = <0,0,.2>;
    list toSet;
    integer i;
    for(; i < count(BUTTONS); ++i ){
        
        if( l2s(BUTTONS, i) != "" ){
            
            toSet += i;
            
        }
        
    }
    
    float x;
    list dta;
    float width = size.x*0.8;
    float totalWidth = count(toSet)*width;
    start.x = totalWidth/2+totalWidth/(count(toSet)*2);
    
    for( i=0; i<count(toSet); ++i ){
        
        integer btn = l2i(toSet, i);
        
        // Coordinates use Y left and Z up for some reason
        x += width;
        vector pos = start-<x, 0,0>;
        pos.y = pos.x;
        pos.x = 0;
        
        dta += (list)PRIM_LINK_TARGET + l2i(pBUTTONS, btn) +
            PRIM_POSITION + pos
        ;
        
    }
    
    llSetLinkPrimitiveParamsFast(0, dta);

}


// Countdown number stage
integer ctStep;
ctStage( ){
    
    float y = 0.125*ctStep*2;
    llSetLinkPrimitiveParamsFast(CTDN, (list)
        PRIM_TEXTURE + 0 + "59bdde35-e67d-8bd0-8b95-7b34bbb0b1b4" + 
        <0.125,0.125,0> +
        <-0.4375,0.4375-y,0> +
        0
    );
    llSetLinkTextureAnim(
        CTDN,
        0, 0, 
        0, 0,
        0, 0,
        0
    );
 
    llSetLinkTextureAnim(
        CTDN,
        ANIM_ON, 0, 
        8, 8,
        ctStep*16, 16,
        32
    );
    
    
}


list pBARS;
list pBUTTONS;



#include "ObstacleScript/begin.lsl"

onStateEntry()

    list set;
    links_each(nr, name,
        
        if( name == "BTN" ){
            
            pBUTTONS += nr;
            set += (list)PRIM_LINK_TARGET + nr +
                PRIM_POSITION + ZERO_VECTOR
            ;
            
        }
        else if( name == "BAR" ){
            
            pBARS += nr;
            set += (list)PRIM_LINK_TARGET + nr +
                PRIM_POSITION + ZERO_VECTOR
            ;
            
        }
		
		else if( name == "INST" ){
			
			
			set += (list)PRIM_LINK_TARGET + nr +
				PRIM_POSITION + (<0,1.5,.75-.1*count(INSTRUCTIONS)>)
			;
			INSTRUCTIONS += nr;
			
		}
        
        if( name == "CTDN" )
            CTDN = nr;
        
    )
    
    llSetLinkPrimitiveParamsFast(0, set);
	        
end




handleMethod( GuiMethod$createBar )
    
    str label = argStr(0);
    vector color = argVec(1);
    vector border = argVec(2);
    
    if( label == "" )
        return;
    
    integer bar = getBarCreateIndex( label );
    
    if( bar == -1 )
        return;
		
		
	integer prim = l2i(pBARS, bar);
        
    llSetLinkTextureAnim(prim, 0, Gui$BAR_BAR_MAIN, 0,0,0,0,0);
	llSetLinkTextureAnim(prim, 0, Gui$BAR_BAR_BG, 0,0,0,0,0);
	
    
    llSetLinkPrimitiveParamsFast(prim, (list)
        PRIM_SIZE + BAR_SIZE +
        PRIM_COLOR + ALL_SIDES + ZERO_VECTOR + 0 +
        PRIM_COLOR + Gui$BAR_BORDER + border + 1 +
        PRIM_COLOR + Gui$BAR_BAR_BG + color + 1 +
        PRIM_TEXTURE + Gui$BAR_BAR_BG + Gui$BAR_TEXTURE_MAIN + <1,.5,1> + <0,-.25,0> + -PI_BY_TWO +
		PRIM_DESC + (str)color
    );
    BAR_SETTINGS = llListReplaceList(BAR_SETTINGS, (list)0, bar, bar);
    
    updateBarPositions();
    
end

handleMethod( GuiMethod$removeBars )

    integer i;
    for( ; i < count(METHOD_ARGS); ++i ){
        
        integer pos = getBar(l2s(METHOD_ARGS, i));
        if( ~pos ){
            
            BARS = llListReplaceList(BARS, (list)"", pos, pos);
            llSetLinkPrimitiveParamsFast(l2i(pBARS, pos), (list)
                PRIM_POSITION + ZERO_VECTOR
            );
            
        }
        
    }
    updateBarPositions();

end

handleMethod( GuiMethod$setBarTexture )
    
    string label = argStr(0);
    integer face = argInt(1);
    key texture = argKey(2);
    integer bar = getBar(label);
    if( bar == -1 )
        return;
        
    integer prim = l2i(pBARS, bar);
    if( texture ){
        
        llSetLinkPrimitiveParamsFast(prim, (list)
            PRIM_TEXTURE + face + texture + <1,1,0> + ZERO_VECTOR + 0 +
            PRIM_COLOR + face + ONE_VECTOR + 1
        );
        if( face == Gui$BAR_ICON_FWD || face == Gui$BAR_ICON_BACK ){
            
            BAR_SETTINGS = llListReplaceList(BAR_SETTINGS, (list)TRUE, bar, bar);
            updateBarPositions();
            
        }
        return;
        
    }
    

    llSetLinkPrimitiveParamsFast(prim, (list)
        PRIM_COLOR + face + ONE_VECTOR + 0
    );
    if( face == Gui$BAR_ICON_FWD || face == Gui$BAR_ICON_BACK ){
        
        BAR_SETTINGS = llListReplaceList(BAR_SETTINGS, (list)FALSE, bar, bar);
        updateBarPositions();
        
    }
     
    
end

handleMethod( GuiMethod$setBarPerc )

    str label = argStr(0);
    float perc = argFloat(1);
    integer bar = getBar(label);
    if( bar == -1 )
        return;
        
	
    integer prim = l2i(pBARS, bar);
	
	vector color = (vector)l2s(llGetLinkPrimitiveParams(prim, (list)PRIM_DESC), 0);
	llSetLinkTextureAnim(prim, 0, Gui$BAR_BAR_MAIN, 0,0,0,0,0);
	
    llSetLinkPrimitiveParamsFast(prim, [
		PRIM_COLOR,
		Gui$BAR_BAR_MAIN,
		ZERO_VECTOR,
		0,
		PRIM_COLOR,
		Gui$BAR_BAR_BG,
		color,
		1,
        PRIM_TEXTURE, 
        Gui$BAR_BAR_BG, 
        Gui$BAR_TEXTURE_MAIN, 
        <1,.5,0>, 
        <0,-.25+(1-perc)*.5,0>, 
        -PI_BY_TWO
    ]);

end

handleMethod( GuiMethod$tweenBar )

    str label = argStr(0);
    float from = argFloat(1);
	float to = argFloat(2);
	float time = argFloat(3);
	
    integer bar = getBar(label);
    if( bar == -1 )
        return;
        
	int total = 4*64;
	int pos = floor(from*total);
	int y = pos/4;
	int x = pos-4*y;
	
	integer prim = l2i(pBARS, bar);
	
	vector color = (vector)l2s(llGetLinkPrimitiveParams(prim, (list)PRIM_DESC), 0);
    
	llSetLinkPrimitiveParamsFast(prim, [
		PRIM_COLOR,
		Gui$BAR_BAR_BG,
		ZERO_VECTOR,
		0.75,
		PRIM_COLOR,
		Gui$BAR_BAR_MAIN,
		color,
		1,
		PRIM_TEXTURE,
		Gui$BAR_BAR_MAIN,
		Gui$BAR_TEXTURE_ANIM,
		<0.25, 1.0/64, 0>,
		<-.375+0.25*x, 1.0/128+1.0/64*31-1.0/64*y, 0>,
		0
	]);
	
	
	int frames = floor((to-from)*(total));
	//pos = floor(from*(total-1));
	
	if( !frames || time <= 0 )
		return;
		
	float rate = llFabs(frames/time);

	int reverse;
	if( frames < 0 )
		reverse = REVERSE;
	

		
	llSetLinkTextureAnim(prim, 0, Gui$BAR_BAR_MAIN, 0,0,0,0,0);
	llSetLinkTextureAnim(
		prim, 
		ANIM_ON|reverse, 
		Gui$BAR_BAR_MAIN, 
		4,64,
		pos,llAbs(frames),
		rate
	);
	
end



handleMethod( GuiMethod$createButton )
    
    str label = argStr(0);
    key texture = argKey(1);
    
    if( label == "" )
        return;
    
    integer button = getButtonCreateIndex( label );
    if( button == -1 )
        return;
        
    
    integer prim = l2i(pBUTTONS, button);
    llSetLinkPrimitiveParamsFast(prim, (list)
        PRIM_SIZE + BUTTON_SIZE +
        PRIM_COLOR + ALL_SIDES + ZERO_VECTOR + 0 +
        PRIM_COLOR + Gui$ICON_BORDER + ONE_VECTOR + 1 +
        PRIM_COLOR + Gui$ICON_BUTTON_BG + ONE_VECTOR + 1 +
        PRIM_TEXTURE + Gui$ICON_BUTTON_BG + texture + ONE_VECTOR + ZERO_VECTOR + 0 +
        PRIM_TEXTURE + Gui$ICON_BUTTON_OVERLAY + "a0adbf17-dc55-9bd3-879e-4ba5527063b4" + <0.0625, 0.0625, 0> + <0.53124, -0.53124, 0> + 0 +
        PRIM_COLOR + Gui$ICON_BUTTON_OVERLAY + ZERO_VECTOR + 0
    );
    
    updateButtonPositions();
    
end

handleMethod( GuiMethod$removeButtons )

    integer i;
    for( ; i < count(METHOD_ARGS); ++i ){
        
        integer pos = getButton(l2s(METHOD_ARGS, i));
        if( ~pos ){
            
            BUTTONS = llListReplaceList(BUTTONS, (list)"", pos, pos);
            llSetLinkPrimitiveParamsFast(l2i(pBUTTONS, pos), (list)
                PRIM_POSITION + ZERO_VECTOR
            );
            
        }
        
    }
    updateButtonPositions();

end

handleMethod( GuiMethod$setButtonCooldown )
    
    str label = argStr(0);
    float cd = argFloat(1);
    integer button = getButton(label);
    if( button == -1 )
        return;
        
    integer prim = l2i(pBUTTONS, button);
    if( cd > 0 ){
        
        llSetLinkTextureAnim(
            prim, 
            0, 
            Gui$ICON_BUTTON_OVERLAY, 
            16, 16,
            0, 256,
            256.0/cd
        );
        llSetLinkTextureAnim(
            prim, 
            ANIM_ON, 
            Gui$ICON_BUTTON_OVERLAY, 
            16, 16,
            0, 256,
            256.0/cd
        );
        
        llSetLinkPrimitiveParamsFast(prim, (list)
            PRIM_COLOR + Gui$ICON_BUTTON_OVERLAY + ZERO_VECTOR + .5
        );
        return;
        
    }
    
    llSetLinkPrimitiveParamsFast(prim, (list)
        PRIM_COLOR + Gui$ICON_BUTTON_OVERLAY + ZERO_VECTOR + 0
    );
    
    
end


handleMethod( GuiMethod$instruction )

	int frame = argInt(0);
	int index = argInt(1);
	int prim = l2i(INSTRUCTIONS, index);
	
	key texture = Gui$TEXTURE_INSTRUCTIONS;
	if( argKey(2) )
		texture = argKey(2);
	
	if( frame == -1 ){

		llSetLinkPrimitiveParamsFast(prim, (list)
			PRIM_POS_LOCAL + <0,1.5,0.75-.1*index> +
			PRIM_TEXTURE + 0 + texture + <1,1,0> + ZERO_VECTOR + 0
		);

		return;
	}
	
	
	int xSize = argInt(3);
	int ySize = argInt(4);
	
	
	
	if( !xSize )
		xSize = 4;
	if( !ySize )
		ySize = 16;
		
	integer y = frame/xSize;
	integer x = frame-y*xSize;
	
	llSetLinkPrimitiveParamsFast(prim, (list)
		PRIM_TEXTURE + 0 + texture + 
		<1.0/xSize, 1.0/ySize, 0> + 
		<
			(-1.0/xSize/2*(!(xSize%2))) - 1.0/xSize*(xSize/2-1) + 1.0/xSize*x,
			(1.0/ySize/2*(!(ySize%2))) + 1.0/ySize*(ySize/2-1) - 1.0/ySize*y,
			0
		> +
		0 +
		
		PRIM_POS_LOCAL + <0,.5,.75-.1*index>
	);
	
	
end





// COUNTDOWN
handleMethod( GuiMethod$startCountdown )

    ctStep = 0;
    ctStage();
    llSetLinkPrimitiveParamsFast(CTDN, (list)PRIM_POSITION + <0,0,.75>);
    setInterval("CD", 1);

end

handleTimer( "CD" )
    
    ++ctStep;
    if( ctStep <= 3 ){
        ctStage();
        if( ctStep == 3 )
            setTimeout("CD", 1.5);
    }
    else{
        llSetLinkPrimitiveParamsFast(CTDN, (list)PRIM_POSITION + ZERO_VECTOR);
    }
end




#include "ObstacleScript/end.lsl"



