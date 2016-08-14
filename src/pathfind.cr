require "crsfml"
require "option_parser"
require "./pathfind/grid"
require "./pathfind/conf"
require "./pathfind/utils"

include Pathfind

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
		path << current as Point
	end
	path << start
	path.reverse
end

def random_point(grid)
	{(rand * grid.cols).to_u as UInt32, (rand * grid.rows).to_u as UInt32}
end

def random_pathfind(grid)
	$start, $goal = random_point(grid), random_point(grid)
	grid.clear
	if grid.rows == 15 && grid.cols == 15
		grid.tiles = TILES.clone
	else
		grid.fill
	end
	grid.set(*$start, 1)
	grid.set(*$goal, 1)
	recalc_pathfind(grid)
end

def recalc_pathfind(grid)
	STDERR.puts "Using algorithm: #{$algo}"
	grid.path = reconstruct grid.pathfind($start, $goal, $algo), $start, $goal
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
$algo : String = algorithms[-1]

OptionParser.parse! do |parser|
	parser.banner = "Usage: #{$0} [args]"
	parser.on("-r ROWS", "--rows=ROWS", "Number of rows") { |r| rows = r.to_u32 }
	parser.on("-c COLS", "--cols=COLS", "Number of columns") { |c| cols = c.to_u32 }
	parser.on("-h", "--help", "Show this help") { puts parser; exit 1 }
	parser.on("-v", "--verbose", "Be verbose") { CONF[:verbose] = true }
	parser.on("-A", "--noarrows", "Don't show arrows") { CONF[:show_arrows] = false }
	parser.on("-w", "--weights", "Show weights") { CONF[:show_weights] = true }
	parser.on("-l", "--list", "List available algorithms") {
		puts "Algorithm index:"
		algorithms.each_with_index { |a, i| puts "#{i}  #{a}" }
		exit 0
	}
	parser.on("-a ALGO_NAME_OR_NUMBER", "--algorithm=ALGO_NAME_OR_NUMBER", "Algorithm") { |a| 
		begin
			$algo = algorithms[a.to_i]
		rescue ArgumentError
			$algo = a
		end
	}
end

$arrow : SF::Texture = SF::Texture.from_file("arrow.png") if CONF[:show_arrows]

# Create the grid
grid = Grid.new(rows, cols)
$start : Point = random_point(grid)
$goal : Point = random_point(grid)

# Create the rendering window
window = SF::RenderWindow.new(
	SF.video_mode(cols * TILE_SIZE, rows * TILE_SIZE),
	"Pathfind test")


font = SF::Font.from_file("Roboto-Regular.ttf")
algo_text = SF::Text.new($algo, font, 14)
algo_text.color = SF::Color::Black unless CONF[:show_weights]
random_pathfind grid

while window.open?
	while event = window.poll_event
		case event.type
		when SF::Event::KeyPressed
			case event.key.code
			when SF::Keyboard::Q
				window.close
			when SF::Keyboard::P
				random_pathfind grid
			when SF::Keyboard::A
				$algo = algorithms[(algorithms.index($algo) as Int + 1) % algorithms.size]
				algo_text.string = $algo
				recalc_pathfind grid
			end
		end
	end

	window.clear
	window.draw grid
	window.draw algo_text
	window.display
end
