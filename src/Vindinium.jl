module Vindinium
	export Tile, Freetile, Woodtile, Herotile, Minetile, Taverntile, Dir, North, South, West, East, Stay, Board, Hero, Game, Session,==

	abstract Tile

	type Freetile <: Tile
	end

	type Woodtile <: Tile
	end

	type Herotile <: Tile
		id :: Int
	end

	type Minetile <: Tile
		id :: Int # Unowned if id == 0
	end

	type Taverntile <: Tile
	end

	function ==(a :: Tile, b :: Tile)
		if typeof(a) == typeof(b)
			if isa(a,Minetile) || isa(a,Herotile)
				return a.id == b.id
			end
		return true
			end
		return false
	end

	abstract Dir

	type North <: Dir
	end

	type South <: Dir
	end

	type East <: Dir
	end

	type West <: Dir
	end

	type Stay <: Dir
	end

	type Board
		size :: Int
		tiles :: Array{Tile,2}
	end

	type Hero
		id :: Int # "" if none availeble (random training bot)
		name :: String
		userId :: String
		elo :: Int # -1 if none availeble (random training bot)
		pos :: Array{Integer,1}
		lastDir :: Dir    # Stay() if none availeble
		life :: Int
		gold :: Int
		mineCount :: Int
		spawnPos :: Array{Integer,1}
		crashed :: Bool
	end

	type Game
		id :: String
		turn :: Int
		maxTurns :: Int
		heroes :: Array{Hero,1}
		board :: Board
		finished :: Bool
	end

	type Data
		game :: Game
		hero :: Hero
		token :: String
		viewUrl :: String
		playUrl :: String
		debug :: Dict{String,Any}
	end
end