all :compile

compile :
	@ozc -c GUI.oz Input.oz Main.oz MapGenerator.oz PlayerXXXSmart1.oz Player100TargetPractice.oz Player101RandomAI.oz PlayerManager.oz

start :
	@ozengine Main.ozf

clean :
	@rm -rf GUI.ozf Input.ozf Main.ozf MapGenerator.ozf PlayerXXXSmart1.ozf Player100TargetPractice.ozf Player101RandomAI.ozf PlayerManager.ozf
