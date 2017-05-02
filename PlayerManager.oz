functor
import
   Player010DrunkAI
   Player010TargetPractice
   Player010DroneMasterAI
   Player033RandAI
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind Color ID}
      case Kind
      of player010DrunkAI then
	 {Player010DrunkAI.portPlayer Color ID}
      [] player010TargetPractice then
	 {Player010TargetPractice.portPlayer Color ID}
      [] player010DroneMasterAI then
   	 {Player010DroneMasterAI.portPlayer Color ID}
      [] player033RandAI then
         {Player033RandAI.portPlayer Color ID}
      end
   end
end
