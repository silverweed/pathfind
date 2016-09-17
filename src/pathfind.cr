require "crsfml"
require "option_parser"
require "./pathfind/grid"
require "./pathfind/conf"
require "./pathfind/utils"

include Pathfind

macro _p(name)
	def self.{{name.id}}
		@@{{name.id}}
	end
	def self.{{name.id}}=(val)
		@@{{name.id}} = val
	end
end

class Glob
	@@start = {0_u32, 0_u32}
	@@goal = {0_u32, 0_u32}
	@@density = 0_f32
	@@algo = ""
	
	_p :start
	_p :goal
	_p :density
	_p :algo
end

TILES = [
	1,1,1,1,1,1,200,1,1,1,1,1,1,1,1,
	1,1,7,7,7,1,1,200,1,1,1,1,1,1,1,
	1,7,10,10,1,1,1,1,1,1,1,1,1,1,1,
	1,7,10,10,1,1,3,3,6,6,6,3,1,1,1,
	1,4,7,7,7,3,3,6,8,8,9,6,1,1,1,
	1,1,4,1,1,3,6,6,9,9,9,6,1,1,1,
	1,1,1,1,1,3,36,49,49,112,9,6,1,1,1,
	30,1,1,1,1,3,36,49,115,115,9,6,1,1,1,
	50,1,1,1,1,3,36,49,0,0,9,6,6,1,100,
	1,1,100,1,1,3,36,49,0,0,115,9,6,1,1,
	1,1,100,1,1,3,36,49,0,0,115,9,6,1,1,
	1,1,100,1,1,3,6,9,9,9,9,6,3,1,1,
	1,1,1,1,1,3,3,6,6,6,6,6,3,1,1,
	1,1,1,1,1,1,3,3,3,3,3,3,3,1,1,
	1,1,1,4,1,1,1,1,1,1,1,1,1,1,1,
]


def reconstruct(came_from, start, goal)
	current = goal
	path = [current]
	while current != start
		break unless came_from.has_key? current
		current = came_from[current]
		path << current.as Point
	end
	path << start
	path.reverse
end

def random_point(grid)
	{(rand * grid.cols).to_u, (rand * grid.rows).to_u}
end

def random_pathfind(grid)
	Glob.start, Glob.goal = random_point(grid), random_point(grid)
	grid.clear
	if CONF[:uniform_weights]
		grid.clear.fill(0, true)
	elsif grid.rows == 15 && grid.cols == 15
		grid.tiles = TILES.clone
	else
		grid.fill
	end
	grid.set(*Glob.start, 1)
	grid.set(*Glob.goal, 1)
	recalc_pathfind(grid)
end

def recalc_pathfind(grid)
	STDERR.puts "Using algorithm: #{Glob.algo}"
	grid.path = reconstruct grid.pathfind(Glob.start, Glob.goal, Glob.algo), Glob.start, Glob.goal
end

######################### MAIN ############################

rows = 15_u32
cols = 15_u32
algorithms = [
	"breadth_first",
	"early_exit_breadth_first",
	"dijkstra",
	"greedy_best_first",
	"a_star"
]
Glob.density = 0.15_f32
Glob.algo = algorithms[-1]

OptionParser.parse! do |parser|
	parser.banner = "Usage: #{$0} [args]"
	parser.on("-r ROWS", "--rows=ROWS", "Number of rows") { |r| rows = r.to_u32 }
	parser.on("-c COLS", "--cols=COLS", "Number of columns") { |c| cols = c.to_u32 }
	parser.on("-h", "--help", "Show this help") { puts parser; exit 1 }
	parser.on("-v", "--verbose", "Be verbose") { CONF[:verbose] = true }
	parser.on("-A", "--noarrows", "Don't show arrows") { CONF[:show_arrows] = false }
	parser.on("-w", "--weights", "Show weights") { CONF[:show_weights] = true }
	parser.on("-u", "--uniform", "Use uniform weights") { CONF[:uniform_weights] = true }
	parser.on("-l", "--list", "List available algorithms") {
		puts "Algorithm index:"
		algorithms.each_with_index { |a, i| puts "#{i}  #{a}" }
		exit 0
	}
	#parser.on("-a ALGO_NAME_OR_NUMBER", "--algorithm=ALGO_NAME_OR_NUMBER", "Algorithm") { |a| 
		#begin
			#Glob.algo = algorithms[a.to_i]
		#rescue ArgumentError 
			#puts e
			#Glob.algo = a
		#end
	#}
end


# Create the grid
grid = Grid.new(rows, cols)
Glob.start = random_point(grid)
Glob.goal = random_point(grid)

# Create the rendering window
window = SF::RenderWindow.new(
	SF::VideoMode.new(cols * TILE_SIZE, rows * TILE_SIZE),
	"Pathfind test")


font = SF::Font.from_file("Roboto-Regular.ttf")
algo_text = SF::Text.new(Glob.algo, font, 14)
algo_text.color = SF::Color::Black unless CONF[:show_weights]
random_pathfind grid

while window.open?
	while event = window.poll_event
		case event
		when SF::Event::KeyPressed
			case event.code
			when SF::Keyboard::Q
				window.close
			when SF::Keyboard::P
				random_pathfind grid
			when SF::Keyboard::A
				Glob.algo = algorithms[(algorithms.index(Glob.algo).not_nil! + 1) % algorithms.size]
				algo_text.string = Glob.algo
				recalc_pathfind grid
			when SF::Keyboard::Num0
				Glob.algo = algorithms[0] 
				algo_text.string = Glob.algo
				recalc_pathfind grid
			when SF::Keyboard::Num1
				Glob.algo = algorithms[1] 
				algo_text.string = Glob.algo
				recalc_pathfind grid
			when SF::Keyboard::Num2
				Glob.algo = algorithms[2] 
				algo_text.string = Glob.algo
				recalc_pathfind grid
			when SF::Keyboard::Num3
				Glob.algo = algorithms[3] 
				algo_text.string = Glob.algo
				recalc_pathfind grid
			when SF::Keyboard::Num4
				Glob.algo = algorithms[4] 
				algo_text.string = Glob.algo
				recalc_pathfind grid
			end
		end
	end

	window.clear
	window.draw grid
	window.draw algo_text
	window.display
end
