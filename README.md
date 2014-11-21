Vindinium-Julia-Client
======================

A simple Vindinium client implemented in Julia.

Requires the Requests and JSON packages they can be installed as follow:

```
julia> Pkg.update()
julia> Pkg.add("Requests")
julia> Pkg.add("JSON")
```

The run_training and run_arena functions of the VindiniumClient module can be used to run a game, for example:

```
julia> using VindiniumClient
julia> using RandomBot
julia> session = VindiniumClient.run_training("key_here",RandomBot,10,"m1")
Starting training ..
Started, view at:
Turn: 10/10 Gold: 0 (4th, 0%) Mines: 0 Dir: east Pos: (3,4)
Game ended.
julia>
```

The RandomBot module contains an example implementation of a Vindinium bot.

Some notes regarding the coordinate system. In the browser view the top left square corresponds with the (1,1) coordinate, where the first index corresponds to the vertical axis and the second index corresponds to the horizontal axis.

```
julia> session.hero.pos
2-element Array{Integer,1}:
 3 		# vertical axis browser view
 4 		# horizontal axis browser view
julia> session.game.board.tiles[session.hero.pos...]
Herotile(1)
```
