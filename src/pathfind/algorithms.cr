require "./utils"

module Pathfind

module Algorithms

def heuristic(a, b)
	# Manhattan
	(a[0].to_i - b[0].to_i).abs + (a[1].to_i - b[1].to_i).abs - 1
end

def pathfind_early_exit_breadth_first(grid, start, goal)
	frontier = [start]
	came_from = {} of Point => Point?
	came_from[start] = nil

	while !frontier.empty?
		current = frontier.shift
		break if current == goal
		log "current = #{current}"
		neighbors(*current).each do |nxt|
			next if came_from.has_key? nxt
			log "next = #{nxt}"
			frontier << nxt
			came_from[nxt] = current
		end
	end

	log "came_from = #{came_from}"
	came_from
end

def pathfind_breadth_first(grid, start, goal)
	frontier = [start]
	came_from = {} of Point => Point?
	came_from[start] = nil

	while !frontier.empty?
		current = frontier.shift
		log "current = #{current}"
		neighbors(*current).each do |nxt|
			next if came_from.has_key? nxt
			log "next = #{nxt}"
			frontier << nxt
			came_from[nxt] = current
		end
	end

	log "came_from = #{came_from}"
	came_from
end

def pathfind_dijkstra(grid, start, goal)
	frontier = PriorityQueue(Point).new
	frontier << {start, 0.0}
	came_from = {} of Point => Point?
	came_from[start] = nil
	cost_so_far = {} of Point => Float64
	cost_so_far[start] = 0.0

	while !frontier.empty?
		current = frontier.shift.value
		break if current == goal
		log "current = #{current}"
		neighbors(*current).each do |nxt|
			new_cost = cost_so_far[current] + grid.cost(current, nxt)
			next if cost_so_far.has_key?(nxt) && new_cost >= cost_so_far[nxt]
			log "next = #{nxt}"
			cost_so_far[nxt] = new_cost
			frontier << {nxt, new_cost}
			came_from[nxt] = current
		end
	end

	log "came_from = #{came_from}"
	came_from
end

def pathfind_greedy_best_first(grid, start, goal)
	frontier = PriorityQueue(Point).new
	frontier << {start, 0.0}
	came_from = {} of Point => Point?
	came_from[start] = nil
	cost_so_far = {} of Point => Float64
	cost_so_far[start] = 0.0

	while !frontier.empty?
		current = frontier.shift.value
		break if current == goal
		log "current = #{current}"
		neighbors(*current).each do |nxt|
			new_cost = cost_so_far[current] + grid.cost(current, nxt)
			next if cost_so_far.has_key?(nxt) && new_cost >= cost_so_far[nxt]
			log "next = #{nxt}"
			cost_so_far[nxt] = new_cost
			priority = heuristic(goal, nxt).to_f64
			frontier << {nxt, priority}
			came_from[nxt] = current
		end
	end

	log "came_from = #{came_from}"
	came_from
end

def pathfind_a_star(grid, start, goal)
	frontier = PriorityQueue(Point).new
	frontier << {start, 0.0}
	came_from = {} of Point => Point?
	came_from[start] = nil
	cost_so_far = {} of Point => Float64
	cost_so_far[start] = 0.0

	while !frontier.empty?
		current = frontier.shift.value
		break if current == goal
		log "current = #{current}"
		neighbors(*current).each do |nxt|
			new_cost = cost_so_far[current] + grid.cost(current, nxt)
			next if cost_so_far.has_key?(nxt) && new_cost >= cost_so_far[nxt]
			log "next = #{nxt}"
			cost_so_far[nxt] = new_cost
			priority = new_cost + heuristic(goal, nxt)
			frontier << {nxt, priority}
			came_from[nxt] = current
		end
	end

	log "came_from = #{came_from}"
	came_from
end

end # module Pathfind::Algorithms

end # module Pathfind
