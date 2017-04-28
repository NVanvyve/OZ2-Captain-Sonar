functor
import
   Input

   OS %rand
   %System %debug
   %Browser %debug
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream

   InitState
   UpdateState
   MapRandomPos
   MapIsWater

   InitPosition
   Move
   Dive
   ChargeItem
   FireItem
   FireMine
   IsSurface
   SayMove
   SaySurface
   SayCharge
   SayMinePlaced
   SayMissileExplode
   SayMineExplode
   SayPassingDrone
   SayAnswerDrone
   SayPassingSonar
   SayAnswerSonar
   SayDeath
   SayDamageTaken
in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{InitState ID Color}
      fun{Sub State N} NewState StateEn in
	 if N == 0 then
	    State
	 else
	    StateEn = {UpdateState State.enemies [N#enemy(pos:null spotted:false)]}
	    NewState = {UpdateState State [enemies#StateEn]}
	    {Sub NewState N-1}
	 end
      end
      MidState
      NewState
   in
      MidState = state(
		    id:id(id:ID color:Color name:'Dummy')
		    hp:Input.maxDamage
		    missileCharge:0
		    mineCharge:0
		    sonarCharge:0
		    droneCharge:0
		    enemies:data(1:null)
		    surf:true
		    surfCharge:0
		    visited:nil
		    lastDir:null
		    focus:null
		    )
      NewState = {Sub MidState Input.nbPlayer}
      NewState
   end

   %Update un State avec une liste de tuple contenant les valeurs qui ont changé
   % state(a:1 b:2) + [b#3] = state(a:1 b:3)
   fun{UpdateState State L}
      {AdjoinList State L}
   end

   fun{MapRandomPos}
      pt(x:({OS.rand} mod Input.nRow + 1) y:({OS.rand} mod Input.nColumn + 1))
   end

   fun{MapIsWater Pos}
      if {List.nth {List.nth Input.map Pos.x} Pos.y} == 0 then
	 true
      else
	 false
      end
   end


%%%%%%%

   %les fonctions ci-dessous représentent le comportement du sub

   fun{InitPosition State ID Position}
      fun{NewPos} Pos in
	 Pos = {MapRandomPos}
	 if {MapIsWater Pos} then
	    Pos
	 else
	    {NewPos}
	 end
      end
      NewState
      RetPos
   in
      RetPos = {NewPos}
      NewState = {UpdateState State [visited#[RetPos] pos#RetPos]}
      ID = NewState.id
      Position = NewState.pos
      NewState
   end

%%%

   fun{Move State ID Position Direction}
      fun{CanMove State Pos}
	 fun{Visited State Pos}
	    fun{Check L Pos}
	       case L
	       of nil then false
	       []pt(x:X y:Y)|T then
		  if Pos.x == X andthen Pos.y == Y then
		     true
		  else
		     {Check T Pos}
		  end
	       end
	    end
	 in
	    {Check State.visited Pos}
	 end
      in
	 if Pos.x>0 andthen Pos.x=<Input.nRow andthen Pos.y>0 andthen Pos.y=<Input.nColumn andthen  {List.nth {List.nth Input.map Pos.x} Pos.y} == 0 andthen {Visited State Pos} == false then
	    true
	 else
	    false
	 end
      end
      fun{RandomMove State}
	 fun{SubRandom Try Pos}
	    if Try == 0 then
	       null
	    else Rand in
	       Rand = {OS.rand} mod 4
	       case Rand
	       of 0 then
		  if {CanMove State pt(x:Pos.x+1 y:Pos.y)} then
		     move(south pt(x:Pos.x+1 y:Pos.y))
		  else
		     {SubRandom Try-1 Pos}
		  end
	       [] 1 then
		  if {CanMove State pt(x:Pos.x-1 y:Pos.y)} then
		     move(north pt(x:Pos.x-1 y:Pos.y))
		  else
		     {SubRandom Try-1 Pos}
		  end
	       [] 2 then
		  if {CanMove State pt(x:Pos.x y:Pos.y-1)} then
		     move(west pt(x:Pos.x y:Pos.y-1))
		  else
		     {SubRandom Try-1 Pos}
		  end
	       [] 3 then
		  if {CanMove State pt(x:Pos.x y:Pos.y+1)} then
		     move(east pt(x:Pos.x y:Pos.y+1))
		  else
		     {SubRandom Try-1 Pos}
		  end
	       end
	    end
	 end
	 Msg
	 NewState
      in
	 Msg = {SubRandom 10 State.pos}
	 case Msg
	 of null then
	    NewState = {UpdateState State [surf#true visited#[State.visited.1]]}
	    ret(surface NewState)
	 [] move(Dir NewPos) then
	    NewState = {UpdateState State [pos#NewPos visited#(NewPos|State.visited)]}
	    ret(Dir NewState)
	 end
      end
      Ret
   in
      Ret = {RandomMove State}
      case Ret
      of ret(NewDir NewState) then
	 Direction = NewDir
	 Position = NewState.pos
	 ID = NewState.id
	 NewState
      end
   end

%%%

   fun{Dive State} NewState in
      NewState = {UpdateState State [surf#false]}
      NewState
   end

%%%

   fun{ChargeItem State ID KindItem} NewState in
      if State.missileCharge<Input.missile then
	 NewState = {UpdateState State [missileCharge#State.missileCharge+1]}
	 ID = NewState.id
	 if NewState.missileCharge == Input.missile then
	    KindItem = missile
	 else
	    KindItem = null
	 end
      elseif State.sonarCharge<Input.sonar then
	 NewState = {UpdateState State [sonarCharge#State.sonarCharge+1]}
	 ID = NewState.id
	 if NewState.sonarCharge == Input.sonar then
	    KindItem = sonar
	 else
	    KindItem = null
	 end
      elseif State.droneCharge<Input.drone then
	 NewState = {UpdateState State [droneCharge#State.droneCharge+1]}
	 ID = NewState.id
	 if NewState.droneCharge == Input.drone then
	    KindItem = drone
	 else
	    KindItem = null
	 end
      elseif State.mineCharge<Input.mine then
	 NewState = {UpdateState State [mineCharge#State.mineCharge+1]}
	 ID = NewState.id
	 if NewState.mineCharge == Input.mine then
	    KindItem = mine
	 else
	    KindItem = null
	 end
      else
	 NewState = State
	 ID = NewState.id
	 KindItem = null
      end
      NewState
   end

%%%

   fun{FireItem State ID KindFire}
      fun{DistTo Pos1 Pos2}
	 {Number.abs Pos1.x-Pos2.x} + {Number.abs Pos1.y-Pos2.y}
      end
      NewState
   in
      case State.focus
      of null then %Si on a pas repéré d'ennemi
	 if State.sonarCharge == Input.sonar then
	    %FIRE SONAR
	    KindFire = sonar
	    NewState = {UpdateState State [sonarCharge#0]}
	 else
	    NewState = State
	    KindFire = null
	 end
      []N then
	 if State.enemies.N.spotted andthen State.missileCharge == Input.missile andthen {DistTo State.pos State.enemies.N.pos} =< Input.maxDistanceMissile andthen {DistTo State.pos State.enemies.N.pos} >= Input.minDistanceMissile then
	    %FIRE THE MISSILE
	    KindFire = missile(State.enemies.N.pos)
	    NewState = {UpdateState State [missileCharge#0]}
	 else
	    NewState = State
	    KindFire = null
	 end
      end
      ID = NewState.id
      NewState
   end

%%%

   fun{FireMine State ID Mine}
      ID = State.id
      Mine = null
      State
   end

%%%

   fun{IsSurface State ID Answer}
      ID = State.id
      Answer = State.surf
      State
   end

%%%

   fun{SayMove State ID Direction} N StateN StateEn NewState in
      N = ID.id
      if State.enemies.N.spotted then
	 case Direction
	 of north then
	    StateN = {UpdateState State.enemies.N [pos#pt(x:State.enemies.N.pos.x-1 y:State.enemies.N.pos.y)]}
	    StateEn = {UpdateState State.enemies [N#StateN]}
	    NewState = {UpdateState State [enemies#StateEn]}
	 [] south then
	    StateN = {UpdateState State.enemies.N [pos#pt(x:State.enemies.N.pos.x+1 y:State.enemies.N.pos.y)]}
	    StateEn = {UpdateState State.enemies [N#StateN]}
	    NewState = {UpdateState State [enemies#StateEn]}
	 [] west then
	    StateN = {UpdateState State.enemies.N [pos#pt(x:State.enemies.N.pos.x y:State.enemies.N.pos.y-1)]}
	    StateEn = {UpdateState State.enemies [N#StateN]}
	    NewState = {UpdateState State [enemies#StateEn]}
	 [] east then
	    StateN = {UpdateState State.enemies.N [pos#pt(x:State.enemies.N.pos.x y:State.enemies.N.pos.y+1)]}
	    StateEn = {UpdateState State.enemies [N#StateN]}
	    NewState = {UpdateState State [enemies#StateEn]}
	 end
      else
	 NewState = State
      end
      NewState
   end

%%%

   fun{SaySurface State ID}
      State
   end

%%%

   fun{SayCharge State ID KindItem}
      State
   end

%%%

   fun{SayMinePlaced State ID}
      State
   end

%%%

   fun{SayMissileExplode State ID Position Message}
      fun{DistToSub State Pos}
	 {Number.abs State.pos.x - Pos.x} + {Number.abs State.pos.y - Pos.y}
      end
      NewState
      MidState
      Dist
   in
      Dist = {DistToSub State Position}
      if Dist == 0 then
	 MidState = {UpdateState State [hp#(State.hp-2)]}
      elseif Dist == 1 then
	 MidState = {UpdateState State [hp#(State.hp-1)]}
      else
	 MidState = State
	 NewState = State
      end
      if State.hp \= MidState.hp then
	 if MidState.hp =< 0 then
	    Message = sayDeath(State.id)
	    NewState = {UpdateState MidState [dead#true hp#0]}
	 else
	    Message = sayDamageTaken(State.id State.hp-MidState.hp MidState.hp)
	    NewState = MidState
	 end
      else
	 Message = null
      end
      NewState
   end

%%%

   fun{SayMineExplode State ID Position Message}
      fun{DistToSub State Pos}
	 {Number.abs State.pos.x - Pos.x} + {Number.abs State.pos.y - Pos.y}
      end
      NewState
      MidState
      Dist
   in
      Dist = {DistToSub State Position}
      if Dist == 0 then
	 MidState = {UpdateState State [hp#(State.hp-2)]}
      elseif Dist == 1 then
	 MidState = {UpdateState State [hp#(State.hp-1)]}
      else
	 MidState = State
	 NewState = State
      end
      if State.hp \= MidState.hp then
	 if MidState.hp =< 0 then
	    Message = sayDeath(State.ID)
	    NewState = {UpdateState MidState [dead#true hp#0]}
	 else
	    Message = sayDamageTaken(State.ID State.hp-MidState.hp MidState.hp)
	    NewState = MidState
	 end
      else
	 Message = null
      end
      NewState
   end

%%%

   fun{SayPassingDrone State Drone ID Answer}
      case Drone
      of drone(row X) then
	 if State.pos.x == X then
	    Answer = true
	 else
	    Answer = false
	 end
      [] drone(column Y) then
	 if State.pos.y == Y then
	    Answer = true
	 else
	    Answer = false
	 end
      end
      ID = State.id
      State
   end

%%%

   fun{SayAnswerDrone State Drone ID Answer}
      State
   end

%%%

   fun{SayPassingSonar State ID Answer}
      ID = State.id
      Answer = State.pos
      State
   end

%%%

   fun{SayAnswerSonar State ID Answer} StateN StateEn NewState in
      if ID \= State.id then
	 StateN = {UpdateState State.enemies.(ID.id) [pos#Answer spotted#true]}
	 StateEn = {UpdateState State.enemies [ID.id#StateN]}
	 NewState = {UpdateState State [focus#ID.id enemies#StateEn]}
	 NewState
      else
	 State
      end
   end

%%%

   fun{SayDeath State ID}
      State
   end

%%%

   fun{SayDamageTaken State ID Damage LifeLeft}
      State
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{StartPlayer Color ID}
      Stream
      Port
      State
   in
      Port = {NewPort Stream}
      thread
	 State = {InitState ID Color}
	 {TreatStream Stream State}
      end
      Port
   end

   proc{TreatStream Stream State}
      %Le State va être les infos sur notre Sub, ou autre chose
      %Pv, position, munitions, ...
      %state(id:ID pos:POS  ...)

      case Stream
      of nil then skip
      []initPosition(ID Position)|S then NewState in
	 NewState = {InitPosition State ID Position}
	 {TreatStream S NewState}
      []move(ID Position Direction)|S then NewState in
	 NewState = {Move State ID Position Direction}
	 {TreatStream S NewState}
      []dive|S then NewState in
	 NewState = {Dive State}
	 {TreatStream S NewState}
      []chargeItem(ID KindItem)|S then NewState in
	 NewState = {ChargeItem State ID KindItem}
	 {TreatStream S NewState}
      []fireItem(ID KindFire)|S then NewState in
	 NewState = {FireItem State ID KindFire}
	 {TreatStream S NewState}
      []fireMine(ID Mine)|S then NewState in
	 NewState = {FireMine State ID Mine}
	 {TreatStream S NewState}
      []isSurface(ID Answer)|S then NewState in
	 NewState = {IsSurface State ID Answer}
	 {TreatStream S NewState}
      []sayMove(ID Direction)|S then NewState in
	 NewState = {SayMove State ID Direction}
	 {TreatStream S NewState}
      []saySurface(ID)|S then NewState in
	 NewState = {SaySurface State ID}
	 {TreatStream S NewState}
      []sayCharge(ID KindItem)|S then NewState in
	 NewState = {SayCharge State ID KindItem}
	 {TreatStream S NewState}
      []sayMinePlaced(ID)|S then NewState in
	 NewState = {SayMinePlaced State ID}
	 {TreatStream S NewState}
      []sayMissileExplode(ID Position Message)|S then NewState in
	 NewState = {SayMissileExplode State ID Position Message}
	 {TreatStream S NewState}
      []sayMineExplode(ID Position Message)|S then NewState in
	 NewState = {SayMineExplode State ID Position Message}
	 {TreatStream S NewState}
      []sayPassingDrone(Drone ID Answer)|S then NewState in
	 NewState = {SayPassingDrone State Drone ID Answer}
	 {TreatStream S NewState}
      []sayAnswerDrone(Drone ID Answer)|S then NewState in
	 NewState = {SayAnswerDrone State Drone ID Answer}
	 {TreatStream S NewState}
      []sayPassingSonar(ID Answer)|S then NewState in
	 NewState = {SayPassingSonar State ID Answer}
	 {TreatStream S NewState}
      []sayAnswerSonar(ID Answer)|S then NewState in
	 NewState = {SayAnswerSonar State ID Answer}
	 {TreatStream S NewState}
      []sayDeath(ID)|S then NewState in
	 NewState = {SayDeath State ID}
	 {TreatStream S NewState}
      []sayDamageTaken(ID Damage LifeLeft)|S then NewState in
	 NewState = {SayDamageTaken State ID Damage LifeLeft}
	 {TreatStream S NewState}
      else
	 skip
      end
   end
end
