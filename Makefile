all :compile

compile :
	@ozc -c *oz

start :
	@ozengine Main.ozf

clean :
	@rm -rf GUI.ozf Input.ozf Main.ozf MapGenerator.ozf PlayerXXXSmart1.ozf Player100TargetPractice.ozf Player101RandomAI.ozf PlayerManager.ozf
