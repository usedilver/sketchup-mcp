require "sketchup"
require "extensions"

module SU_MCP
  PLUGIN_ROOT = File.dirname(__FILE__)

  unless file_loaded?(__FILE__)
    extension = SketchupExtension.new(
      "SketchUp MCP",
      File.join(PLUGIN_ROOT, "su_mcp", "main")
    )
    extension.version     = "0.2.0"
    extension.creator     = "usedilver"
    extension.copyright   = "2026"
    extension.description = "Model Context Protocol server for SketchUp."
    Sketchup.register_extension(extension, true)
    file_loaded(__FILE__)
  end
end
