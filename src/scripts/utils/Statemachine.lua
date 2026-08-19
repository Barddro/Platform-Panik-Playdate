-- Each state is a plain table of the shape:
--   {
--     enter = function(owner, ...) end,  -- optional, runs once on entry
--     update = function(owner) end,      -- optional, runs every frame
--     exit = function(owner) end,        -- optional, runs once on exit
--     -- plus any other flags/data the owner wants to read off the active state
--   }

class('StateMachine').extends()

function StateMachine:init(owner, states, initialState)
	self.owner = owner
	self.states = states
	self.currentName = nil
	self.current = nil
	self:transitionTo(initialState)
end

function StateMachine:transitionTo(name, ...)
	local nextState = self.states[name]
	assert(nextState, "StateMachine: unknown state '" .. tostring(name) .. "'")

	if self.current and self.current.exit then
		self.current.exit(self.owner)
	end

	self.currentName = name
	self.current = nextState

	if self.current.enter then
		self.current.enter(self.owner, ...)
	end
end

function StateMachine:update()
	if self.current and self.current.update then
		self.current.update(self.owner)
	end
end

function StateMachine:is(name)
	return self.currentName == name
end