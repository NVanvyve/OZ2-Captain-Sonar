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

   GL_Surf
   GL_Move
   GL_Charge
   GL_Fire
   GL_Explode
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

   fun{GL_Surf State H N} MidState1 in
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
      MidState1
   end

   fun{GL_Move MidState1 GuiPort H N} M_ID M_Pos M_Dir MidState2 in
      {Send H move(M_ID M_Pos M_Dir)}
      if M_Dir == surface then StateN in
         StateN = {AdjoinList MidState1.N [remainSurf#Input.turnSurface surf#true]}
         MidState2 = {AdjoinList MidState1 [N#StateN]}
         {Send GuiPort surface(M_ID)}
         {Broadcast Players saySurface(M_ID)}
      else
         {Broadcast Players sayMove(M_ID M_Dir)}
         {Send GuiPort movePlayer(M_ID M_Pos)}
         MidState2 = MidState1
      end
      MidState2
   end

   proc{GL_Charge H Players} CI_ID CI_KindItem in
      {Send H chargeItem(CI_ID CI_KindItem)}
      case CI_KindItem
      of null then
         skip
      else
         {Broadcast Players sayCharge(CI_ID CI_KindItem)}
      end
   end

   fun{GL_Fire MidState2 GuiPort Players H N} FI_ID FI_KindFire in
      {Send H fireItem(FI_ID FI_KindFire)}
      case FI_KindFire
      of null then
         MidState2
      []mine(Pos) then %Mine
         {Broadcast Players sayMinePlaced(FI_ID)}
         {Send GuiPort putMine(FI_ID Pos)}
         MidState2
      []missile(Pos) then %Missile
         fun{BroadcastMissile State L Pos} ThisState in
            case L
            of nil then State
            []H|T then Msg in
               {Send H sayMissileExplode(FI_ID Pos Msg)}
               case Msg
               of null then ThisState = State
               []sayDeath(RET_ID) then StateN in
                  StateN = {AdjoinList State.N [dead#true]}
                  ThisState = {AdjoinList State [alive#State.alive-1 N#StateN]}
                  {Broadcast Players sayDeath(RET_ID)}
                  {Send GuiPort removePlayer(RET_ID)}
                  if Input.isTurnByTurn == false then
                     {Send State.sync dead}
                  end
               []sayDamageTaken(RET_ID RET_DMG RET_HP) then
                  ThisState = MidState2
                  {Broadcast Players sayDamageTaken(RET_ID RET_DMG RET_HP)}
                  {Send GuiPort lifeUpdate(RET_ID RET_HP)}
               end
               {BroadcastMissile ThisState T Pos}
            end
         end
      in
         {BroadcastMissile MidState2 Players Pos}
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
         MidState2
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
         MidState2
      end
   end

   fun{GL_Explode State GuiPort Players H N} FM_ID FM_Mine NewState in
      {Send H fireMine(FM_ID FM_Mine)}
      case FM_Mine
      of null then State
      []pt(x:X y:Y) then
	 proc{BroadcastMine L Pos}
	    case L
	    of nil then skip
	    []H|T then Msg in
	       {Send H sayMineExplode(FM_ID Pos Msg)}
	       case Msg
	       of null then skip
	       []sayDeath(RET_ID) then StateN in
                  StateN = {AdjoinList State.N [dead#true]}
                  NewState = {AdjoinList State [alive#State.alive-1 N#StateN]}
		  {Broadcast Players sayDeath(RET_ID)}
		  {Send GuiPort removePlayer(RET_ID)}
                  if Input.isTurnByTurn == false then
                     {Send State.sync dead}
                  end
	       []sayDamageTaken(RET_ID RET_DMG RET_HP) then
                  NewState = State
		  {Broadcast Players sayDamageTaken(RET_ID RET_DMG RET_HP)}
		  {Send GuiPort lifeUpdate(RET_ID RET_HP)}
	       end
	       {BroadcastMine T Pos}
	    end
	 end
      in
	 {BroadcastMine Players pt(X Y)}
	 {Send GuiPort removeMine(FM_ID FM_Mine)}
	 NewState
      end
   end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   proc{GameLoop State}
      fun{OneTurn L N State} NewState in
	 case L
	 of nil then State
	 []H|T then
	    MidState1
	 in
         {System.show '-----------------'}
         {System.show newTurn(N)}

         %Vérification de la surface
         MidState1 = {GL_Surf State H N}

         %Si on est sous l'eau, on fait le reste des actions
         if MidState1.N.surf == false then
            MidState2
            MidState3
            MidState4
         in

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
            {GL_Charge H Players}

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

            %Vérification de la surface
            MidState1 = {GL_Surf State H N}

	    %Si on est sous l'eau, on fait le reste des actions
	    if MidState1.N.surf == false then
	       MidState2
               MidState3
               MidState4
	    in

	       {System.show move}
	       %Mouvement
               MidState2 = {GL_Move MidState1 GuiPort H N}

	       {System.show charge}
	       %ChargeItem
               {GL_Charge H Players}

	       {System.show fire}
	       %Fireitem
               MidState3 = {GL_Fire MidState2 GuiPort Players H N}

	       {System.show explode}
	       %ExplodeMine
               MidState4 = {GL_Explode MidState3 GuiPort Players H N}

	       NewState = MidState4

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
         if NextState.alive > 1 then
	    {GameLoop NextState}
         end
         {System.show 'game over'}
      else
	 proc{Launcher L N State}
	    case L of nil then skip
	    [] H|T then
	       thread {OneTurnThread H N State} end
	       {Launcher T N+1 State}
	    end
	 end
         proc{StateSync Stream Remain}
            case Stream
            of nil then skip
            []sync(Ret)|S then
               if Remain > 1 then
                  Ret = true
               else
                  Ret = false
                  {System.show 'game over'}
               end
               {StateSync S Remain}
            []dead|S then
               {StateSync S Remain-1}
            end
         end %StateSync
         SyncPort
         Str
      in
         SyncPort = {NewPort Str}
         thread {StateSync Str Input.nbPlayer} end
         {Launcher Players 1 {AdjoinList State [sync#SyncPort]}}
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
