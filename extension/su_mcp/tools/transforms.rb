module SU_MCP
  module Tools
    module Transforms
      def self.delete(params)
        entity = SU_MCP::Entities.find!(params["id"])
        entity.erase!
        { success: true }
      end

      # Translate / rotate / scale an entity. All three are optional and
      # applied in that order. `translate` is a relative move (delta).
      # `rotate` is degrees around X, Y, Z about the entity's bounds center.
      # `scale` is per-axis factors about the entity's bounds center.
      def self.transform(params)
        entity = SU_MCP::Entities.find!(params["id"])

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
