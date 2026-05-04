module SU_MCP
  # Routes JSON-RPC method calls to registered handlers.
  #
  # Tool modules register themselves like:
  #
  #   SU_MCP::Dispatcher.register("create_component") do |params|
  #     # ...returns a Hash that becomes the JSON-RPC result
  #   end
  module Dispatcher
    @handlers = {}

    class << self
      attr_reader :handlers

      def register(method_name, &block)
        @handlers[method_name.to_s] = block
      end

      def dispatch(request)
        method = request["method"]
        params = request["params"] || {}
        id     = request["id"]

        # MCP framing: tool calls arrive as method="tools/call" with
        # params = { "name": "<tool>", "arguments": {...} }
        if method == "tools/call"
          method = params["name"]
          params = params["arguments"] || {}
        end

        handler = @handlers[method.to_s]
        if handler.nil?
          return jsonrpc_error(id, -32601, "Method not found: #{method}")
        end

        begin
          result = handler.call(params)
          { jsonrpc: "2.0", id: id, result: result }
        rescue StandardError => e
          Log.error("Handler '#{method}' raised: #{e.message}")
          Log.error(e.backtrace.first(5).join("\n"))
          jsonrpc_error(id, -32603, e.message)
        end
      end

      private

      def jsonrpc_error(id, code, message)
        { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
      end
    end
  end
end
