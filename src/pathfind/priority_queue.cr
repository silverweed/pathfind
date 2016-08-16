module Pathfind

class Element(T)
	include Comparable(Element)

	property value, priority

	def initialize(@value : T, @priority : Float64)
		puts "value: #{@value}, prio: #{@priority}"
	end

	def <=>(other)
		@priority <=> other.priority
	end
end

class PriorityQueue(T)
	def initialize
		@elements = [] of Element(T)
	end

	def <<(element)
		@elements << element
	end

	def <<(pair : Tuple(T, Float64))
		@elements << Element(T).new(pair[0], pair[1])
	end

	def pop
		last_element_index = @elements.size - 1
		@elements.sort!
		@elements.delete_at(last_element_index)
	end

	def shift
		@elements.sort!
		#puts "after sort: #{@elements}"
		@elements.shift
	end

	def empty?
		@elements.empty?
	end
end

end # module Pathfind
