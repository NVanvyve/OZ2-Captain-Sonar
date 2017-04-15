all :compile

compile :
	@ozc -c *.oz

start :
	@ozengine Main.ozf

clean :
	@rm -rf *.ozf
