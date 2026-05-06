require "sketchup"

module SU_MCP
  module Menu
    SUBMENU_NAME = "SketchUp MCP".freeze
    MIN_PORT     = 1024
    MAX_PORT     = 65535

    def self.install
      return if @installed
      @installed = true

      menu = UI.menu("Plugins").add_submenu(SUBMENU_NAME)
      menu.add_item("Server Status…")  { show_status }
      menu.add_item("Configure Port…") { configure_port }
    end

    def self.show_status
      server = Server.instance
      state  = server.running? ? "Running" : "Stopped"
      UI.messagebox("SketchUp MCP\n\nStatus: #{state}\nPort:   #{server.port}\nHost:   127.0.0.1")
    end

    def self.configure_port
      server  = Server.instance
      current = server.port
      result  = UI.inputbox(
        ["Port (#{MIN_PORT}-#{MAX_PORT}):"],
        [current.to_s],
        "Configure SketchUp MCP Port",
      )
      return unless result

      new_port = result[0].to_i
      if new_port < MIN_PORT || new_port > MAX_PORT
        UI.messagebox("Invalid port. Must be between #{MIN_PORT} and #{MAX_PORT}.")
        return
      end
      return if new_port == current

      Sketchup.write_default("SU_MCP", "port", new_port)
      server.restart(new_port)

      if server.running?
        UI.messagebox(
          "Port set to #{new_port}. Server is running.\n\n" \
          "Update your MCP client config to use SKETCHUP_PORT=#{new_port}.",
        )
      else
        UI.messagebox(
          "Could not bind to port #{new_port} (likely in use).\n\n" \
          "Server is now stopped. Try a different port.",
        )
      end
    end
  end
end
