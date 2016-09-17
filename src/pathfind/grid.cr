require "crsfml"
require "./priority_queue"
require "./utils"
require "./algorithms"

module Pathfind

alias Point = Tuple(UInt32, UInt32)

class Grid
	include Pathfind::Algorithms

	getter rows, cols
	setter tiles
	property path

	@arrow : SF::Texture?

	def initialize(@rows : UInt32, @cols : UInt32)
		@tiles = [] of Int32
		@path = [] of Point
		@came_from = {} of Point => Point?
		@arrow = SF::Texture.from_file("arrow.png") if CONF[:show_arrows]
	end

	def clear
		@tiles.clear
		self
	end

	def fill(density = 0.15, uniform = false)
		(@rows * @cols).times do
			r = rand
			@tiles << (r < density ? 0 : uniform ? 1 : (r + 1).to_i)
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

	include SF::Drawable

	def draw(window, states : SF::RenderStates)
		rect = SF::RectangleShape.new(SF.vector2f(TILE_SIZE, TILE_SIZE))
		sprite = SF::Sprite.new
		if CONF[:show_arrows]
			sprite.origin = {TILE_SIZE.to_f32/2, TILE_SIZE.to_f32/2}
			sprite.texture = @arrow.not_nil!
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
		@came_from = case algorithm
		when "breadth_first"
			pathfind_breadth_first(self, start, goal)
		when "early_exit_breadth_first"
			pathfind_early_exit_breadth_first(self, start, goal)
		when "dijkstra"
			pathfind_dijkstra(self, start, goal)
		when "greedy_best_first"
			pathfind_greedy_best_first(self, start, goal)
		when "a_star"
			pathfind_a_star(self, start, goal)
		else
			raise "Unknown algorithm: #{algorithm}"
		end
	end

	def cost(a, b)
		ca = tile(*a)
		return Float64::INFINITY if ca == 0
		cb = tile(*b)
		return Float64::INFINITY if cb == 0
		[1, (cb - ca).abs].max
	end

	private def rotate_arrow(sprite, x, y)
		return false unless @came_from.has_key?({x, y})
		cf = @came_from[{x, y}] 
		if cf.is_a? Point
			if cf[0] < x
				sprite.rotation = 270
			elsif cf[1] > y
				sprite.rotation = 180
			elsif cf[0] > x
				sprite.rotation = 90
			else
				sprite.rotation = 0
			end
			return true
		end
		return false
	end

	private def pathable(tile)
		tile != 0
	end
end

end # module Pathfind
