functor
import
   %Une bibliothèque de joueurs
   Player101RandomAI
   Player100TargetPractice
   PlayerBasicAI
   PlayerXXXSmart1
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind Color ID}
      case Kind
      of player101RandomAI then
	 {Player101RandomAI.portPlayer Color ID}
      [] player100TargetPractice then
	 {Player100TargetPractice.portPlayer Color ID}
      [] playerBasicAI then
   	 {PlayerBasicAI.portPlayer Color ID}
      [] playerSmart1 then
         {PlayerXXXSmart1.portPlayer Color ID}
      end
   end
end
