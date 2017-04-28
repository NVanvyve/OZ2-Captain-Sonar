functor
import
<<<<<<< HEAD
   Player010DrunkAI
   Player010TargetPractice
   Player010DroneMasterAI
   Player033RandAI
=======
   %Une bibliothèque de joueurs
   Player101RandomAI
   Player100TargetPractice
   PlayerBasicAI
   PlayerXXXSmart1
>>>>>>> dce73b5251f05f06553cb7b0b55149acd8151669
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind Color ID}
      case Kind
<<<<<<< HEAD
      of player010DrunkAI then
	 {Player010DrunkAI.portPlayer Color ID}
      [] player010TargetPractice then
	 {Player010TargetPractice.portPlayer Color ID}
      %[] player010DroneMasterAI then
   	 %{Player010DroneMasterAI.portPlayer Color ID}
      [] player033RandAI then
         {Player033RandAI.portPlayer Color ID}
=======
      of player101RandomAI then
	 {Player101RandomAI.portPlayer Color ID}
      [] player100TargetPractice then
	 {Player100TargetPractice.portPlayer Color ID}
      [] playerBasicAI then
   	 {PlayerBasicAI.portPlayer Color ID}
      [] playerSmart1 then
         {PlayerXXXSmart1.portPlayer Color ID}
>>>>>>> dce73b5251f05f06553cb7b0b55149acd8151669
      end
   end
end
