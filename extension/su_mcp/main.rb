require "sketchup"

module SU_MCP
  PLUGIN_DIR = File.dirname(__FILE__)
end

require File.join(SU_MCP::PLUGIN_DIR, "logger")
require File.join(SU_MCP::PLUGIN_DIR, "dispatcher")
require File.join(SU_MCP::PLUGIN_DIR, "server")

# Load all tool modules
Dir[File.join(SU_MCP::PLUGIN_DIR, "tools", "*.rb")].sort.each { |f| require f }

SU_MCP::Server.instance.start
