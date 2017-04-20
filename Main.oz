functor
import
   GUI
   Input
   PlayerManager

   Browser %debug
   System %debug
define
   GuiPort %Port du GUI

   Players %Liste des ports des players

   Broadcast %Proc
   CreatePlayers %Proc
   CreateGameState %Proc
   InitPlayers %Proc
   GameLoop %Proc
in

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{CreatePlayers} %retourne une liste de ports
      fun{Sub ID NbPlayer Players Colors}
	 if(ID =< NbPlayer) then
	    case Players#Colors
	    of (H1|T1)#(H2|T2) then
	       {PlayerManager.playerGenerator H1 H2 ID}|{Sub ID+1 NbPlayer T1 T2}
	    else nil
	    end
	 else
	    nil
	 end
      end
   in
      {Sub 1 Input.nbPlayer Input.players Input.colors}
   end

   fun{CreateGameState}
      fun{Sub N R} NewR in
	 if N =< Input.nbPlayer then
	    NewR = {AdjoinList R [N#player(remainSurf:0 surf:true dead:false)]}
	    {Sub N+1 NewR}
	 else
	    R
	 end
      end
      NewState
   in
      NewState = {Sub 1 state()}
      {AdjoinList NewState [alive#Input.nbPlayer]}
   end

   proc{InitPlayers}
      proc{Sub L}
	 case L
	 of nil then
	    skip
	 []H|T then ID Pos in
	    {Send H initPosition(ID Pos)}
	    {Wait ID}
	    {Wait Pos}
	    {Send GuiPort initPlayer(ID Pos)}
	    {Sub T}
	 end
      end
   in
      {Sub Players}
   end

   proc{Broadcast L Msg} %L une liste de ports
      case L
      of nil then
	 skip
      []H|T then
	 {Send H Msg}
	 {Broadcast T Msg}
      end
   end

   proc{GameLoop State}
      fun{OneTurn L N State} NewState in
	 case L
	 of nil then State
	 []H|T then
	    MidState1
	 in
	    {System.show '-----------------'}
	    {System.show newTurn(N)}

	    {System.show remainSurf(State.N.remainSurf)}
	    {System.show isSurf(State.N.surf)}

	    %Vérification de la surface
	    if State.N.remainSurf > 0 then StateN in
	       StateN = {AdjoinList State.N [remainSurf#(State.N.remainSurf-1)]}
	       MidState1 = {AdjoinList State [N#StateN]}
	    elseif State.N.surf andthen State.N.remainSurf == 0 then StateN in
	       {Send H dive}
	       StateN = {AdjoinList State.N [surf#false]}
	       MidState1 = {AdjoinList State [N#StateN]}
	    else
	       MidState1 = State
	    end

	    {System.show actions(MidState1.N.surf)}
	    %Si on est sous l'eau, on fait le reste des actions
	    if MidState1.N.surf == false then
	       MidState2
	       M_ID
	       M_Pos
	       M_Dir
	       CI_ID
	       CI_KindItem
	       FI_ID
	       FI_KindFire
	       FM_ID
	       FM_Mine
	    in

	       {System.show move}
	       %Mouvement
	       {Send H move(M_ID M_Pos M_Dir)}
	       if M_Dir == surface then StateN in
		  StateN = {AdjoinList State.N [remainSurf#Input.turnSurface surf#true]}
		  MidState2 = {AdjoinList MidState1 [N#StateN]}
		  {Send GuiPort surface(M_ID)}
		  {Broadcast Players saySurface(M_ID)}
	       else
		  {Broadcast Players sayMove(M_ID M_Dir)}
		  {Send GuiPort movePlayer(M_ID M_Pos)}
		  MidState2 = MidState1
	       end

	       {System.show charge}
	       %ChargeItem
	       {Send H chargeItem(CI_ID CI_KindItem)}
	       case CI_KindItem
	       of null then
		  skip
	       else
		  {Broadcast Players sayCharge(CI_ID CI_KindItem)}
	       end

	       {System.show fire}
	       %Fireitem
	       {Send H fireItem(FI_ID FI_KindFire)}
	       case FI_KindFire
	       of null then
		  skip
	       []mine(Pos) then %Mine
		  {Broadcast Players sayMinePlaced(FI_ID)}
		  {Send GuiPort putMine(FI_ID Pos)}
	       []missile(Pos) then %Missile
		  proc{BroadcastMissile L Pos}
		     case L
		     of nil then skip
		     []H|T then Msg in
			{Send H sayMissileExplode(FI_ID Pos Msg)}
			case Msg
			of null then skip
			[]sayDeath(RET_ID) then
			   {Broadcast Players sayDeath(RET_ID)}
			   {Send GuiPort removePlayer(RET_ID)}
			[]sayDamageTaken(RET_ID RET_DMG RET_HP) then
			   {Broadcast Players sayDamageTaken(RET_ID RET_DMG RET_HP)}
			   {Send GuiPort lifeUpdate(RET_ID RET_HP)}
			end
			{BroadcastMissile T Pos}
		     end
		  end
	       in
		  {Browser.browse missile(Pos)}
		  {BroadcastMissile Players Pos}
	       []drone(Dir Val) then %Drone
		  proc{BroadcastDrone L Dir Val}
		     case L
		     of nil then skip
		     []He|T then PD_ID PD_ANS in
			{Send He sayPassingDrone(drone(Dir Val) PD_ID PD_ANS)}
			{Send H sayAnswerDrone(drone(Dir Val) PD_ID PD_ANS)}
			{BroadcastDrone T Dir Val}
		     end
		  end
	       in
		  {BroadcastDrone Players Dir Val}
	       []sonar then %Sonar
		  proc{BroadcastSonar L}
		     case L
		     of nil then skip
		     []He|T then PS_ID PS_ANS in
			{Send He sayPassingSonar(PS_ID PS_ANS)}
			{Send H sayAnswerSonar(PS_ID PS_ANS)}
			{BroadcastSonar T}
		     end
		  end
	       in
		  {BroadcastSonar Players}
	       end

	       {System.show explode}
	       %ExplodeMine
	       {Send H fireMine(FM_ID FM_Mine)}
	       case FM_Mine of null then skip
	       []pt(x:X y:Y) then
		  proc{BroadcastMine L Pos}
		     case L
		     of nil then skip
		     []H|T then Msg in
			{Send H sayMineExplode(FM_ID Pos Msg)}
			case Msg
			of null then skip
			[]sayDeath(RET_ID) then
			   {Broadcast Players sayDeath(RET_ID)}
			   {Send GuiPort removePlayer(RET_ID)}
			[]sayDamageTaken(RET_ID RET_DMG RET_HP) then
			   {Broadcast Players sayDamageTaken(RET_ID RET_DMG RET_HP)}
			   {Send GuiPort lifeUpdate(RET_ID RET_HP)}
			end
			{BroadcastMine T Pos}
		     end
		  end
	       in
		  {BroadcastMine Players pt(X Y)}
		  {Send GuiPort removeMine(FM_ID FM_Mine)}
	       end
	       NewState = MidState2

	    else %Si on est en surface
	       NewState = MidState1
	    end
	    {System.show endTurn}
	    {Delay 500}
	    {OneTurn T N+1 NewState}
	 end
      end %OneTurn

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      proc{OneTurnThread H N State} NewState in
	 if true then %insérer vérif sur H ici
	    MidState1
	 in
	    {System.show '-----------------'}
	    {System.show newTurn(N)}
	    {System.show hp(State)}

	    {System.show remainSurf(State.N.remainSurf)}
	    {System.show isSurf(State.N.surf)}

	    %Vérification de la surface
	    if State.N.remainSurf > 0 then StateN in
	       StateN = {AdjoinList State.N [remainSurf#(State.N.remainSurf-1)]}
	       MidState1 = {AdjoinList State [N#StateN]}
	    elseif State.N.surf andthen State.N.remainSurf == 0 then StateN in
	       {Send H dive}
	       StateN = {AdjoinList State.N [surf#false]}
	       MidState1 = {AdjoinList State [N#StateN]}
	    else
	       MidState1 = State
	    end

	    {System.show actions(MidState1.N.surf)}
	    %Si on est sous l'eau, on fait le reste des actions
	    if MidState1.N.surf == false then
	       MidState2
	       M_ID
	       M_Pos
	       M_Dir
	       CI_ID
	       CI_KindItem
	       FI_ID
	       FI_KindFire
	       FM_ID
	       FM_Mine
	    in
	       
	       {System.show move}
	       %Mouvement
	       {Send H move(M_ID M_Pos M_Dir)}
	       if M_Dir == surface then StateN in
		  StateN = {AdjoinList State.N [remainSurf#Input.turnSurface surf#true]}
		  MidState2 = {AdjoinList MidState1 [N#StateN]}
		  {Send GuiPort surface(M_ID)}
		  {Broadcast Players saySurface(M_ID)}
	       else
		  {Broadcast Players sayMove(M_ID M_Dir)}
		  {Send GuiPort movePlayer(M_ID M_Pos)}
		  MidState2 = MidState1
	       end

	       {System.show charge}
	       %ChargeItem
	       {Send H chargeItem(CI_ID CI_KindItem)}
	       case CI_KindItem
	       of null then
		  skip
	       else
		  {Broadcast Players sayCharge(CI_ID CI_KindItem)}
	       end

	       {System.show fire}
	       %Fireitem
	       {Send H fireItem(FI_ID FI_KindFire)}
	       case FI_KindFire
	       of null then
		  skip
	       []mine(Pos) then %Mine
		  {Broadcast Players sayMinePlaced(FI_ID)}
		  {Send GuiPort putMine(FI_ID Pos)}
	       []missile(Pos) then %Missile
		  proc{BroadcastMissile L Pos}
		     case L
		     of nil then skip
		     []H|T then Msg in
			{Send H sayMissileExplode(FI_ID Pos Msg)}
			case Msg
			of null then skip
			[]sayDeath(RET_ID) then
			   {Broadcast Players sayDeath(RET_ID)}
			   {Send GuiPort removePlayer(RET_ID)}
			[]sayDamageTaken(RET_ID RET_DMG RET_HP) then
			   {Broadcast Players sayDamageTaken(RET_ID RET_DMG RET_HP)} 
			   {Send GuiPort lifeUpdate(RET_ID RET_HP)}
			end
			{BroadcastMissile T Pos}
		     end
		  end
	       in
		  {Browser.browse missile(Pos)}
		  {BroadcastMissile Players Pos}
	       []drone(Dir Val) then %Drone
		  proc{BroadcastDrone L Dir Val}
		     case L
		     of nil then skip
		     []He|T then PD_ID PD_ANS in
			{Send He sayPassingDrone(drone(Dir Val) PD_ID PD_ANS)}
			{Send H sayAnswerDrone(drone(Dir Val) PD_ID PD_ANS)}
			{BroadcastDrone T Dir Val}
		     end
		  end
	       in
		  {BroadcastDrone Players Dir Val}
	       []sonar then %Sonar
		  proc{BroadcastSonar L}
		     case L
		     of nil then skip
		     []He|T then PS_ID PS_ANS in
			{Send He sayPassingSonar(PS_ID PS_ANS)}
			{Send H sayAnswerSonar(PS_ID PS_ANS)}
			{BroadcastSonar T}
		     end
		  end
	       in
		  {BroadcastSonar Players}
	       end

	       {System.show explode}
	       %ExplodeMine
	       {Send H fireMine(FM_ID FM_Mine)}
	       case FM_Mine of null then skip
	       []pt(x:X y:Y) then
		  proc{BroadcastMine L Pos}
		     case L
		     of nil then skip
		     []H|T then Msg in
			{Send H sayMineExplode(FM_ID Pos Msg)}
			case Msg
			of null then skip
			[]sayDeath(RET_ID) then
			   {Broadcast Players sayDeath(RET_ID)}
			   {Send GuiPort removePlayer(RET_ID)}
			[]sayDamageTaken(RET_ID RET_DMG RET_HP) then
			   {Broadcast Players sayDamageTaken(RET_ID RET_DMG RET_HP)}
			   {Send GuiPort lifeUpdate(RET_ID RET_HP)}
			end
			{BroadcastMine T Pos}
		     end
		  end
	       in
		  {BroadcastMine Players pt(X Y)}
		  {Send GuiPort removeMine(FM_ID FM_Mine)}
	       end
	       NewState = MidState2
	       
	    else %Si on est en surface
	       NewState = MidState1
	    end
	    {System.show endTurn}
	    {Delay 500}
	    {OneTurnThread H N NewState}
	 end
      end %OneTurnThread
      NextState
   in
      if Input.isTurnByTurn then
	 NextState = {OneTurn Players 1 State}
	 {GameLoop NextState}
      else
	 proc{Launcher L N State}
	    case L of nil then skip
	    [] H|T then
	       thread {OneTurnThread H N State} end
	       {Launcher T N+1 State}
	    end   
	 end
      in
	 {Launcher Players 1 State}
      end
   end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %CREATING THE GUI
   GuiPort = {GUI.portWindow}
   {Send GuiPort buildWindow}

   %CREATE PORT FOR EVERY PLAYER USING PLAYERMANAGER AND ASSIGN ID
   Players = {CreatePlayers}

   %ASK EVERY PLAYER TO INIT
   {System.show 'starting player init'}
   {InitPlayers}

   %WHEN EVERY PLAYER HAS SET UP LAUNCH THE GAME
   {Delay 4000}
   {System.show 'starting game loop'}
   {GameLoop {CreateGameState}}


end
