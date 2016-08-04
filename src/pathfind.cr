require "crsfml"
require "option_parser"
require "./pathfind/grid"
require "./pathfind/conf"
require "./pathfind/utils"

include Pathfind

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
	grid.clear.fill
	grid.set(*$start, 1)
	grid.set(*$goal, 1)
	recalc_pathfind(grid)
end

def recalc_pathfind(grid)
	grid.path = reconstruct grid.pathfind($start, $goal, $algo), $start, $goal
end

######################### MAIN ############################

rows = 15_u32
cols = 15_u32
algorithms = [
	"breadth_first",
	"early_exit_breadth_first",
	"dijkstra"
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
				recalc_pathfind grid
			end
		end
	end

	window.clear
	window.draw grid
	window.display
end