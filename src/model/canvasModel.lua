local _ = require("util/dequeue")

CanvasModel = {}

function CanvasModel:new()
  local cm = {
    result = Dequeue:new(),
  }
  setmetatable(cm, self)
  self.__index = self

  return cm
end

function CanvasModel:push(newResult)
  self.result:push(newResult)
end