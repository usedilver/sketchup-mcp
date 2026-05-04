module SU_MCP
  module Tools
    module System
      def self.ping(_params)
        { success: true, pong: true, timestamp: Time.now.to_i }
      end

      def self.undo(params)
        steps = [(params["steps"] || 1).to_i, 1].max
        model = Sketchup.active_model
        raise "No active model" unless model

        undone = 0
        steps.times do
          begin
            model.undo_operation
            undone += 1
          rescue StandardError
            break
          end
        end
        { success: true, undone: undone, requested: steps }
      end
    end
  end
end

SU_MCP::Dispatcher.register("ping")      { |params| SU_MCP::Tools::System.ping(params) }
SU_MCP::Dispatcher.register("undo_last") { |params| SU_MCP::Tools::System.undo(params) }
