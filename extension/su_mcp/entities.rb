module SU_MCP
  module Entities
    # Resolve an entity ID that may arrive as int, "123", or '"123"'.
    def self.find!(id)
      clean = id.to_s.gsub('"', '').to_i
      entity = Sketchup.active_model.find_entity_by_id(clean)
      raise ArgumentError, "Entity not found: #{id.inspect}" unless entity
      entity
    end

    # Used by joinery tools — both ends of a joint must be solids
    # (groups or component instances) we can subtract from / add to.
    def self.find_solid!(id, label = "entity")
      entity = find!(id)
      unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        raise ArgumentError, "#{label} (id=#{id}) must be a group or component instance"
      end
      entity
    end

    # Returns the entity collection a solid contains: group.entities or
    # component.definition.entities depending on the type.
    def self.contents(solid)
      solid.is_a?(Sketchup::Group) ? solid.entities : solid.definition.entities
    end
  end
end
