require "sketchup"

module SU_MCP
  PLUGIN_DIR = File.dirname(__FILE__)
end

require File.join(SU_MCP::PLUGIN_DIR, "logger")
require File.join(SU_MCP::PLUGIN_DIR, "entities")
require File.join(SU_MCP::PLUGIN_DIR, "dispatcher")
require File.join(SU_MCP::PLUGIN_DIR, "server")
require File.join(SU_MCP::PLUGIN_DIR, "menu")

# Load all tool modules
Dir[File.join(SU_MCP::PLUGIN_DIR, "tools", "*.rb")].sort.each { |f| require f }

SU_MCP::Server.instance.start
SU_MCP::Menu.install
