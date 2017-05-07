functor
import
   Player010DrunkAI
   Player010TargetPractice
   Player010DroneMasterAI
   Player010DroneMasterAI2
   Player033RandAI
   Player069USA
   Player099ILikeTrains
   Player032Random
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
      [] player010DroneMasterAI2 then
      	 {Player010DroneMasterAI2.portPlayer Color ID}
      [] player033RandAI then
         {Player033RandAI.portPlayer Color ID}
      [] player069USA then
         {Player069USA.portPlayer Color ID}
      [] player099ILikeTrains then
         {Player099ILikeTrains.portPlayer Color ID}
      [] player032Random then
         {Player032Random.portPlayer Color ID}
      end
   end
end
