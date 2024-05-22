
STACK=stack --allow-different-user
BUILD_OPTS=--ghc-options -O0

test: clean
	$(STACK) test $(BUILD_OPTS)

bin:
	$(STACK) build $(BUILD_OPTS)

cont:
	$(STACK) build --file-watch $(BUILD_OPTS)
clean:
	$(STACK) clean

distclean: clean
	rm -rf .stack-work

tags:
	hasktags -x -c src/

turnin:
	git commit -a -m "turnin"
	git push origin main

upstream:
	git remote add upstream https://github.com/ucsd-cse130/04-nano.git

update:
	git pull upstream main

ghci:
	mkdir -p ~/.tmpdir
	TMPDIR=~/.tmpdir $(STACK) ghci
