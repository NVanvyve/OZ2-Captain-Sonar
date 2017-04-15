functor
import
   Input

   OS %rand
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
      state( id:id(id:ID color:Color name:'Target')
	     %pos:pt(x:X y:Y)
	     hp:Input.maxDamage
	     surf:true
	     dead:false
	   )
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
   in
      NewState = {UpdateState State [pos#{NewPos}]}
      ID = NewState.id
      Position = NewState.pos
      NewState
   end

   fun{Move State ID Position Direction} NewState in
      ID = State.id
      Position = State.pos
      Direction = surface
      NewState = {UpdateState State [surf#true]}
      NewState
   end

   fun{Dive State} NewState in
      NewState = {UpdateState State [surf#false]}
      NewState
   end

   fun{ChargeItem State ID KindItem}
      ID = State.id
      KindItem = null
      State
   end

   fun{FireItem State ID KindFire}
      ID = State.id
      KindFire = null
      State
   end

   fun{FireMine State ID Mine}
      ID = State.id
      Mine = null
      State
   end

   fun{IsSurface State ID Answer}
      ID = State.id
      Answer = State.surf
      State
   end

   fun{SayMove State ID Direction}
      State
   end

   fun{SaySurface State ID}
      State
   end

   fun{SayCharge State ID KindItem}
      State
   end

   fun{SayMinePlaced State ID}
      State
   end

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

   fun{SayAnswerDrone State Drone ID Answer}
      State
   end

   fun{SayPassingSonar State ID Answer}
      ID = State.id
      Answer = State.pos
      State
   end

   fun{SayAnswerSonar State ID Answer}
      State
   end

   fun{SayDeath State ID}
      State
   end

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
