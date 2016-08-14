module Pathfind

class Element(T)
	include Comparable(Element)

	property value, priority

	def initialize(@value : T, @priority : Int32)
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

	def pop
		last_element_index = @elements.size - 1
		@elements.sort!
		@elements.delete_at(last_element_index)
	end

	def shift
		el = @elements.shift
		@elements.sort!
		el
	end

	def empty?
		@elements.empty?
	end
end

end # module Pathfind
