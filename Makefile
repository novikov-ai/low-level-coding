hello-world:
	clang -o hello/hello hello/hello.s 
	./hello/hello

run-game:
	clang -o game/game game/game.s
	./game/game