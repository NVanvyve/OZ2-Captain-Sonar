functor
import
   OS
   System
export
   map:MapExp
define
   MapExp
   Generator
   LandMass
   Isles
in

   LandMass = 30 %Pourcentage de cases occupées par des îles
   Isles = 8 %Nombre d'îles

   fun{Generator NRow NColumn LandMass Isles}
      fun{RandomIsles N}
	 if N == 0 then
	    nil
	 else
	    pt(x:({OS.rand} mod NRow +1) y:({OS.rand} mod NColumn +1))|{RandomIsles N-1}
	 end
      end
      fun{NewMap NRow NColumn}
	 fun{Sub N}
	    if N == 0 then nil
	    else
	       0|{Sub N-1}
	    end
	 end
      in
	 if NRow == 0 then
	    nil
	 else
	    {Sub NColumn}|{NewMap NRow-1 NColumn}
	 end
      end
      fun{FillMap State NRow NColumn}
	 fun{Sink State}
	    fun{SubSink Pos Map}
	       fun{AddLand Pos Map N}
		  fun{Sub Pos Map N X}
		     if N > NColumn then
			nil
		     elseif Pos.y == N then
			1|{Sub Pos Map N+1 X}
		     else
			{List.nth {List.nth Map X} N}|{Sub Pos Map N+1 X}
		     end
		  end
	       in
		  if N > NRow then
		     nil
		  elseif Pos.x == N then
		     {Sub Pos Map 1 N}|{AddLand Pos Map N+1}
		  else
		     {List.nth Map N}|{AddLand Pos Map N+1}
		  end
	       end
	    in
               {System.show Pos.x#Pos.y}
               {System.show Map}
	       if {List.nth {List.nth Map Pos.x} Pos.y} == 0 then
		  {AddLand Pos Map 1}
	       else Rand in
		  Rand = {OS.rand} mod 4
		  if Rand == 0 then %droite
		     if Pos.y < NColumn then
			{SubSink pt(x:Pos.x y:Pos.y+1) Map}
		     else
			{SubSink pt(x:Pos.x y:Pos.y-1) Map}
		     end
		  elseif Rand == 1 then %gauche
		     if Pos.y > 1 then
			{SubSink pt(x:Pos.x y:Pos.y-1) Map}
		     else
			{SubSink pt(x:Pos.x y:Pos.y+1) Map}
		     end
		  elseif Rand == 2 then %haut
		     if Pos.x > 1 then
			{SubSink pt(x:Pos.x-1 y:Pos.y) Map}
		     else
			{SubSink pt(x:Pos.x+1 y:Pos.y) Map}
		     end
		  else %bas
		     if Pos.x < NRow then
			{SubSink pt(x:Pos.x+1 y:Pos.y) Map}
		     else
			{SubSink pt(x:Pos.x-1 y:Pos.y) Map}
		     end
		  end
	       end
	    end
	 in
	    if State.remain == 0 then
	       State
	    else
	       case State.isl
	       of nil then State
	       [] H|T then MidMap in
		  MidMap = {SubSink H State.map}
		  {Sink state(remain:State.remain-1 isl:T map:MidMap)}
	       end
	    end
	 end
      in
	 if State.remain > 0 then MidState in
	    MidState = {Sink State}
	    {FillMap state(remain:MidState.remain isl:State.isl map:MidState.map) NRow NColumn}
	 else
	    State.map
	 end
      end
      IslesPos
      EmptyMap
      State
   in
      {System.show b1}
      IslesPos = {RandomIsles Isles}
      {System.show b2}
      EmptyMap = {NewMap NRow NColumn}
      {System.show b3}
      State = state(remain:(NRow*NColumn*LandMass div 100) isl:IslesPos map:EmptyMap)
      {System.show b4}
      {FillMap State NRow NColumn}
   end

   proc{MapExp EXP NRow NColumn}
      {System.show c1}
      EXP = {Generator NRow NColumn LandMass Isles}
   end
end
