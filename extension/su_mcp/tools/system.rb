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

      # Run several tool calls under a single undo operation. Each call
      # is `{tool: "name", args: {...}}`. By default, an error rolls
      # back the whole batch (atomic). Pass `wrap_undo: false` to skip
      # the undo wrapper, or `stop_on_error: false` to continue past
      # individual failures.
      def self.batch(params)
        calls         = Array(params["calls"])
        wrap_undo     = params["wrap_undo"]     != false
        stop_on_error = params["stop_on_error"] != false
        undo_name     = params["undo_name"] || "MCP batch"
        model         = Sketchup.active_model

        results = []
        runner  = lambda do
          calls.each_with_index do |call, i|
            tool_name = call["tool"] || call[:tool]
            args      = call["args"] || call[:args] || {}
            sub_request = { "jsonrpc" => "2.0", "method" => tool_name, "params" => args, "id" => "batch-#{i}" }
            response    = SU_MCP::Dispatcher.dispatch(sub_request)

            if response[:error]
              results << { index: i, success: false, error: response[:error][:message] }
              raise response[:error][:message] if stop_on_error
            else
              results << { index: i, success: true, result: response[:result] }
            end
          end
        end

        if wrap_undo && model
          model.start_operation(undo_name, true)
          begin
            runner.call
            model.commit_operation
          rescue StandardError => e
            model.abort_operation rescue nil
            return { success: false, error: e.message, completed: results.length, results: results }
          end
        else
          runner.call
        end

        { success: true, count: results.length, results: results }
      end
    end
  end
end

SU_MCP::Dispatcher.register("ping")      { |params| SU_MCP::Tools::System.ping(params) }
SU_MCP::Dispatcher.register("undo_last") { |params| SU_MCP::Tools::System.undo(params) }
SU_MCP::Dispatcher.register("batch")     { |params| SU_MCP::Tools::System.batch(params) }
