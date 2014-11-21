module VindiniumClient
	using Requests
	using JSON
	importall Vindinium

	export run_training, run_arena

	function Tile_from_string(tile :: String)
		if tile == "##"
			return Woodtile()
		end
		if tile == "  "
			return Freetile()
		end
		if tile == "[]"
			return Taverntile()
		end
		if tile[1] == '@'
			return Herotile(int(tile[2:end]))
		end
		if tile[1] == '\$'
			if tile[2] == '-'
				return Minetile(0)
			else
				return Minetile(int(tile[2:end]))
			end
		end
	end 

	function Dir_from_string(data :: ASCIIString)
		if data == "Stay"
			return Stay()
		end
		if data == "North"
			return North()
		end
		if data == "South"
			return South()
		end
		if data == "West"
			return West()
		end
		if data == "East"
			return East()
		end
	end

	function Data(data :: Dict{String,Any},game :: Game)
		return Vindinium.Data(
			game, 
			game.heroes[data["hero"]["id"]],
			data["token"],
			data["viewUrl"],
			data["playUrl"],
			data)
	end

	function Game(data :: Dict{String,Any},
		heroes :: Array{Hero,1},
		board :: Board)
		return Game(
			data["id"],
			data["turn"],
			data["maxTurns"],
			heroes,
			board,
			data["finished"])
	end

	function Hero(data :: Dict{String,Any},size :: Integer)
		lastDir = Stay()
		if haskey(data,"lastDir")
			lastDir = Dir_from_string(data["lastDir"])
		end
		userId = ""
		if haskey(data,"userId")
			userId = data["userId"]
		end
		elo = -1;
		if haskey(data,"elo")
			elo = data["elo"]
		end
		return Hero(
			data["id"],
			data["name"],
			userId,
			elo,
			[data["pos"]["x"], data["pos"]["y"]] + 1,
			lastDir,
			data["life"],
			data["gold"],
			data["mineCount"],
			[data["pos"]["x"], data["spawnPos"]["y"]] + 1,
			data["crashed"])
	end

	function Board(data :: Dict{String,Any})
		size = data["size"]
		map = data["tiles"]
		tiles = Array(Tile,size,size)
		for y = 1:size
			for x = 1:size
				start = 2*x+(y-1)*size*2 -1
				stop = start + 1
				tiles[y,x] = Tile_from_string(map[start:stop])
			end
		end
		return Board(size,tiles)
	end

	function start_training(key :: String, turns :: Int, map :: String)
		data = {
		"key" => key,
		"turns" => turns}

		if map != "Random"
			if !(map in ["m1","m2","m3","m4","m5","m6"])
				error("Map ", map, " does not exist.")
			end
			data["map"] = map
		end

		response = post("http://vindinium.org/api/training", json = data)
		return decode_response(response)
	end

	function start_arena(key :: String)
		data = {"key" => key};
		response = post("http://vindinium.org/api/arena",json = data)
		return decode_response(response)
	end

	function send_action(key :: String, session :: Vindinium.Data, dir :: Dir)
		data = {"key" => key}
		if isa(dir,North)
			data["dir"] = "North"
		elseif isa(dir,South)
			data["dir"] = "South"
		elseif isa(dir,East)
			data["dir"] = "East"
		elseif isa(dir,West)
			data["dir"] = "West"
		elseif isa(dir,Stay)
			data["dir"] = "Stay"
		end

		response = post(session.playUrl, json=data)
		return decode_response(response)
	end

	function decode_response(response :: Requests.Response)
		if response.status == 200
			data = JSON.parse(response.data)
			board = Board(data["game"]["board"])
			nr_heroes = size(data["game"]["heroes"])[1]
			heroes = Array(Hero,nr_heroes)
			for i=1:nr_heroes
				heroes[i] = Hero(data["game"]["heroes"][i],board.size)
			end
			game = Game(data["game"],heroes,board)
			return Data(data,game)
		elseif response.status == 500
			error("Server error " ,response.status, ". ", response.data)
		else
			error("Client error " ,response.status, ". ", response.data)
		end
	end
	
	function show_stats(session :: Vindinium.Data, dir :: Dir, prev_size :: Integer)
		for i=1:prev_size
			print("\b \b")
		end
		id = session.hero.id
		all_gold = map(x -> x.gold, session.game.heroes)
		nr_heroes = size(session.game.heroes,1)
		turn = int(session.game.turn / nr_heroes)
		maxTurns = int(session.game.maxTurns / nr_heroes)
		gold = session.hero.gold
		if sum(all_gold) == 0
			percentage = int(100 / nr_heroes)
		else
			percentage = int(100 * gold / sum(all_gold))
		end 
		place = nr_heroes - find(map(x-> x== session.hero.id, sortperm(all_gold)))[1] + 1
		if place == 1
			place = "1st"
		elseif place == 2
			place = "2nd"
		elseif place == 3
			place = "3rd"
		else
			place = "4th"
		end
		mine = session.hero.mineCount
		dirName = "Stay"
		if isa(dir,North)
			dirName = "north"
		elseif isa(dir,South)
			dirName = "south"
		elseif isa(dir,East)
			dirName = "east"
		elseif isa(dir,West)
			dirName = "west"
		end
		pos = session.hero.pos
		pos = (pos[1],pos[2])
		text = "Turn: $turn/$maxTurns Gold: $gold ($place, $percentage%) Mines: $mine Dir: $dirName Pos: $pos"
		print(text)
		return length(text)
	end

	function run_arena(key :: String, bot :: Module)
		println("Starting arena ..")
		session = start_arena(key)
		println("Started, view at:", session.viewUrl)
		prev_size = 0;
		dir = Stay();
		while !session.game.finished
			dir = bot.step(session)
			if dir == None
				dir = Stay()
			end
			session = send_action(key,session,dir)
			prev_size = show_stats(session, dir, prev_size)
		end
		println("\nGame ended.")
		return session
	end

	function run_training(key :: String, bot :: Module, 
		turns :: Integer, map :: String)
		println("Starting training ..")
		session = start_training(key, turns, map)
		println("Started, view at:", session.viewUrl)
		prev_size = 0;
		dir = Stay();
		while !session.game.finished
			dir = bot.step(session)
			if dir == None
				dir = Stay()
			end
			session = send_action(key,session,dir)
			prev_size = show_stats(session, dir, prev_size)
		end
		println("\nGame ended.")
		return session
	end

	function run_training(key :: String, bot :: Module)
		run_training(key,bot,300,"Random")
	end

	function run_training(key :: String, bot :: Module,
		turns :: Integer)
		run_training(key,bot,turns,"Random")
	end

	function run_training(key :: String, bot :: Module,
		map :: String)
		run_training(key,bot,300,map)
	end
end