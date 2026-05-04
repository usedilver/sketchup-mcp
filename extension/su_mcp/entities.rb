module SU_MCP
  module Entities
    # Resolve an entity ID that may arrive as int, "123", or '"123"'.
    def self.find!(id)
      clean = id.to_s.gsub('"', '').to_i
      entity = Sketchup.active_model.find_entity_by_id(clean)
      raise ArgumentError, "Entity not found: #{id.inspect}" unless entity
      entity
    end
  end
end
