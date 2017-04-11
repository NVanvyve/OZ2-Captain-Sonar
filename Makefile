all :compile

compile :
	@ozc *.oz

start :
	@ozengine Main.ozf

clean :
	@rm -rf *.ozf
