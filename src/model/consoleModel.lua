local class = require('util.class')

require("model.canvasModel")
require("model.editor.editorModel")
require("model.project.project")

--- @class Model table
--- @field input UserInputModel
--- @field editor EditorModel
--- @field output CanvasModel
--- @field projects ProjectService
--- @field cfg Config
ConsoleModel = class.create(function(cfg)
  return {
    input    = UserInputModel(cfg, LuaEval(), 'console'),
    editor   = EditorModel(cfg),
    output   = CanvasModel(cfg),
    projects = ProjectService(),
    cfg      = cfg
  }
end)
