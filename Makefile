test:
	mocha -R spec -t 30000 --compilers coffee:coffee-script test/*.coffee

.PHONY: test