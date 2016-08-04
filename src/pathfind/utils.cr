require "./conf"

module Pathfind

macro log(s)
	puts {{s}} if CONF[:verbose]
end

end
