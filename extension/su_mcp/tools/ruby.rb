module SU_MCP
  module Tools
    module Ruby
      def self.eval_code(params)
        code = params["code"].to_s
        raise ArgumentError, "code is required" if code.empty?

        SU_MCP::Log.info("eval_ruby: #{code.length} chars")
        result = eval(code, TOPLEVEL_BINDING.dup)
        { success: true, result: result.inspect }
      end
    end
  end
end

SU_MCP::Dispatcher.register("eval_ruby") { |params| SU_MCP::Tools::Ruby.eval_code(params) }
