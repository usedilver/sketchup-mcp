require "timeout"

module SU_MCP
  module Tools
    module Ruby
      DEFAULT_TIMEOUT = 30 # seconds

      def self.eval_code(params)
        code = params["code"].to_s
        raise ArgumentError, "code is required" if code.empty?

        timeout = (params["timeout"] || DEFAULT_TIMEOUT).to_i
        SU_MCP::Log.info("eval_ruby: #{code.length} chars (timeout=#{timeout}s)")

        result = Timeout.timeout(timeout) { eval(code, TOPLEVEL_BINDING.dup) }
        { success: true, result: result.inspect }
      rescue Timeout::Error
        raise "eval_ruby timed out after #{timeout}s (pass {\"timeout\": N} to extend)"
      end
    end
  end
end

SU_MCP::Dispatcher.register("eval_ruby") { |params| SU_MCP::Tools::Ruby.eval_code(params) }
