module SU_MCP
  module Tools
    module Transforms
      # Resolve an entity ID that may arrive as int, "123", or '"123"'.
      def self.find_entity!(id)
        clean = id.to_s.gsub('"', '').to_i
        entity = Sketchup.active_model.find_entity_by_id(clean)
        raise ArgumentError, "Entity not found: #{id.inspect}" unless entity
        entity
      end

      def self.delete(params)
        entity = find_entity!(params["id"])
        entity.erase!
        { success: true }
      end

      # Translate / rotate / scale an entity. All three are optional and
      # applied in that order. `translate` is a relative move (delta).
      # `rotate` is degrees around X, Y, Z about the entity's bounds center.
      # `scale` is per-axis factors about the entity's bounds center.
      def self.transform(params)
        entity = find_entity!(params["id"])

        if (t = params["translate"] || params["position"])
          entity.transform!(Geom::Transformation.translation(Geom::Point3d.new(t[0], t[1], t[2])))
        end

        if (r = params["rotate"] || params["rotation"])
          center = entity.bounds.center
          axes   = [Geom::Vector3d.new(1, 0, 0), Geom::Vector3d.new(0, 1, 0), Geom::Vector3d.new(0, 0, 1)]
          r.each_with_index do |deg, i|
            next if deg.to_f.zero?
            entity.transform!(Geom::Transformation.rotation(center, axes[i], deg * Math::PI / 180.0))
          end
        end

        if (s = params["scale"])
          entity.transform!(Geom::Transformation.scaling(entity.bounds.center, s[0], s[1], s[2]))
        end

        { success: true, id: entity.entityID }
      end
    end
  end
end

SU_MCP::Dispatcher.register("delete_component")    { |params| SU_MCP::Tools::Transforms.delete(params) }
SU_MCP::Dispatcher.register("transform_component") { |params| SU_MCP::Tools::Transforms.transform(params) }
