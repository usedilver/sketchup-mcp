module SU_MCP
  module Tools
    module Booleans
      OPERATIONS = {
        "union"        => :union,
        "subtract"     => :subtract,
        "difference"   => :subtract,    # alias
        "intersect"    => :intersect,
        "intersection" => :intersect,   # alias
      }.freeze

      def self.perform(params)
        op_key = params["operation"].to_s.downcase
        method = OPERATIONS[op_key]
        raise ArgumentError, "operation must be one of: #{OPERATIONS.keys.join(', ')}" unless method

        target = SU_MCP::Entities.find_solid!(params["target_id"], "target")
        tool   = SU_MCP::Entities.find_solid!(params["tool_id"],   "tool")

        result = target.public_send(method, tool)
        raise "Boolean #{op_key} produced no geometry (do the solids overlap?)" unless result

        { success: true, id: result.entityID, operation: op_key }
      end
    end
  end
end

SU_MCP::Dispatcher.register("boolean_operation") { |params| SU_MCP::Tools::Booleans.perform(params) }
