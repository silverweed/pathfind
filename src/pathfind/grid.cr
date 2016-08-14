require "crsfml"
require "./priority_queue"
require "./utils"

module Pathfind

alias Point = Tuple(UInt32, UInt32)

class Grid
	getter rows, cols
	setter tiles
	property path

	def initialize(@rows : UInt32, @cols : UInt32)
		@tiles = [] of Int32
		@path = [] of Point
		@came_from = {} of Point => Point?
	end

	def clear
		@tiles.clear
		self
	end

	def fill(density = 0.15)
		(@rows * @cols).times do
			r = rand
			@tiles << (r < density ? 0 : (r * 10).to_i)
		end
	end

	def tile(x, y)
		@tiles[y * @cols + x]
	end
	
	def set(x, y, v)
		@tiles[y * @cols + x] = v
	rescue IndexError
		raise "Out of bounds: x = #{x} / #{@cols}, y = #{y} / #{@rows};" +
			"\ny * cols + x = #{y * @cols + x} / #{@tiles.size}"
	end

	def draw(window, states)
		rect = SF::RectangleShape.new(SF.vector2f(TILE_SIZE, TILE_SIZE))
		sprite = SF::Sprite.new
		if CONF[:show_arrows]
			sprite.origin = {TILE_SIZE.to_f32/2, TILE_SIZE.to_f32/2}
			sprite.texture = $arrow
			sprite.texture_rect = SF.int_rect(0, 0, ARROW_SCALE[0], ARROW_SCALE[1])
			sprite.scale = SF.vector2f(TILE_SIZE.to_f32 / ARROW_SCALE[0], TILE_SIZE.to_f32 / ARROW_SCALE[1])
		end
		@rows.times do |y|
			@cols.times do |x|
				pos = SF.vector2f(x * TILE_SIZE, y * TILE_SIZE)
				tile = tile(x, y)
				if CONF[:show_arrows]
					sprite.position = SF.vector2f(
						pos.x+TILE_SIZE.to_f32/2,
						pos.y+TILE_SIZE.to_f32/2)
					show_arrow = rotate_arrow(sprite, x, y)
				end
				rect.position = pos
				rect.fill_color = 
					if !pathable(tile)
						SF::Color::Red
					else
						if @path.includes?({x, y})
							if @path[0] == {x, y}
								SF::Color::Green
							elsif @path[-1] == {x, y}
								SF::Color::Magenta
							else
								SF::Color::Blue
							end
						else
							#SF.color(tile, tile, tile)
							SF.color(210, 210, 210)
						end
					end
				if CONF[:show_weights]
					c = rect.fill_color
					rect.fill_color = SF.color(c.r, c.g, c.b, 100 + 10* tile)
				end
				window.draw(rect, states)
				window.draw(sprite, states) if CONF[:show_arrows] && pathable(tile) && show_arrow
			end
		end
	end

	def neighbors(x, y)
		n = [] of Point
		n << {x - 1, y} unless x == 0 || !pathable(tile(x - 1, y))
		n << {x, y - 1} unless y == 0 || !pathable(tile(x, y - 1))
		n << {x + 1, y} unless x == @cols - 1 || !pathable(tile(x + 1, y))
		n << {x, y + 1} unless y == @rows - 1 || !pathable(tile(x, y + 1))
		log "neighbours of #{x}, #{y} = #{n}"
		n
	end

	def pathfind(start, goal, algorithm = "early_exit_breadth_first")
		case algorithm
		when "breadth_first"
			pathfind_breadth_first(start, goal)
		when "early_exit_breadth_first"
			pathfind_early_exit_breadth_first(start, goal)
		when "dijkstra"
			pathfind_dijkstra(start, goal)
		when "greedy_best_first"
			pathfind_greedy_best_first(start, goal)
		when "a_star"
			pathfind_a_star(start, goal)
		else
			raise "Unknown algorithm: #{algorithm}"
		end
	end

	private def rotate_arrow(sprite, x, y)
		return false unless @came_from.has_key?({x, y})
		cf = @came_from[{x, y}] 
		return false if cf == nil 
		cf = cf as Point
		if cf[0] < x
			sprite.rotation = 270
		elsif cf[1] > y
			sprite.rotation = 180
		elsif cf[0] > x
			sprite.rotation = 90
		else
			sprite.rotation = 0
		end
		true
	end

	private def cost(a, b)
		ca = tile(*a)
		ca = Float64::INFINITY if ca == 0
		cb = tile(*b)
		cb = Float64::INFINITY if cb == 0
		cb - ca
	end
	
	private def pathable(tile)
		tile != 0
	end

	private def heuristic(a, b)
		# Manhattan
		(a[0] - b[0]).abs + (a[1] - b[1]).abs
	end


	private def pathfind_early_exit_breadth_first(start, goal)
		frontier = [start]
		@came_from = {} of Point => Point?
		@came_from[start] = nil

		while !frontier.empty?
			current = frontier.shift
			break if current == goal
			log "current = #{current}"
			neighbors(*current).each do |nxt|
				next if @came_from.has_key? nxt
				log "next = #{nxt}"
				frontier << nxt
				@came_from[nxt] = current
			end
		end

		log "came_from = #{@came_from}"
		@came_from
	end

	private def pathfind_breadth_first(start, goal)
		frontier = [start]
		@came_from = {} of Point => Point?
		@came_from[start] = nil

		while !frontier.empty?
			current = frontier.shift
			log "current = #{current}"
			neighbors(*current).each do |nxt|
				next if @came_from.has_key? nxt
				log "next = #{nxt}"
				frontier << nxt
				@came_from[nxt] = current
			end
		end

		log "came_from = #{@came_from}"
		@came_from
	end

	private def pathfind_dijkstra(start, goal)
		frontier = PriorityQueue(Point).new
		frontier << {start, 0.0}
		@came_from = {} of Point => Point?
		@came_from[start] = nil
		cost_so_far = {} of Point => Float64
		cost_so_far[start] = 0.0

		while !frontier.empty?
			current = frontier.shift.value
			break if current == goal
			log "current = #{current}"
			neighbors(*current).each do |nxt|
				new_cost = cost_so_far[current] + cost(current, nxt)
				next if cost_so_far.has_key?(nxt) && new_cost >= cost_so_far[nxt]
				log "next = #{nxt}"
				cost_so_far[nxt] = new_cost
				frontier << {nxt, new_cost}
				@came_from[nxt] = current
			end
		end

		log "came_from = #{@came_from}"
		@came_from
	end

	private def pathfind_greedy_best_first(start, goal)
		frontier = PriorityQueue(Point).new
		frontier << {start, 0.0}
		@came_from = {} of Point => Point?
		@came_from[start] = nil
		cost_so_far = {} of Point => Float64
		cost_so_far[start] = 0.0

		while !frontier.empty?
			current = frontier.shift.value
			break if current == goal
			log "current = #{current}"
			neighbors(*current).each do |nxt|
				new_cost = cost_so_far[current] + cost(current, nxt)
				next if cost_so_far.has_key?(nxt) && new_cost >= cost_so_far[nxt]
				log "next = #{nxt}"
				cost_so_far[nxt] = new_cost
				priority = heuristic(goal, nxt).to_f64
				frontier << {nxt, priority}
				@came_from[nxt] = current
			end
		end

		log "came_from = #{@came_from}"
		@came_from
	end

	private def pathfind_a_star(start, goal)
		frontier = PriorityQueue(Point).new
		frontier << {start, 0.0}
		@came_from = {} of Point => Point?
		@came_from[start] = nil
		cost_so_far = {} of Point => Float64
		cost_so_far[start] = 0.0

		while !frontier.empty?
			current = frontier.shift.value
			break if current == goal
			log "current = #{current}"
			neighbors(*current).each do |nxt|
				new_cost = cost_so_far[current] + cost(current, nxt)
				next if cost_so_far.has_key?(nxt) && new_cost >= cost_so_far[nxt]
				log "next = #{nxt}"
				cost_so_far[nxt] = new_cost
				priority = new_cost + heuristic(goal, nxt)
				frontier << {nxt, priority}
				@came_from[nxt] = current
			end
		end

		log "came_from = #{@came_from}"
		@came_from
	end
end

end # module Pathfind
