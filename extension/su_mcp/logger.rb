module SU_MCP
  module Log
    PREFIX = "MCP".freeze

    def self.info(msg)
      write("#{PREFIX}: #{msg}")
    end

    def self.error(msg)
      write("#{PREFIX} ERROR: #{msg}")
    end

    def self.write(line)
      begin
        SKETCHUP_CONSOLE.write("#{line}\n")
      rescue StandardError
        puts line
      end
    end
  end
end
