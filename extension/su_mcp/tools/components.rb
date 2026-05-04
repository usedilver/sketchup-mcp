module SU_MCP
  module Tools
    module Components
      CIRCLE_SEGMENTS = 24
      SPHERE_SEGMENTS = 16

      # Position is the min corner of the shape's bounding box.
      # Dimensions is [width, depth, height] along x, y, z.
      def self.create(params)
        type = params["type"].to_s
        pos  = params["position"]   || [0, 0, 0]
        dims = params["dimensions"] || [1, 1, 1]

        entities = Sketchup.active_model.active_entities
        group = entities.add_group

        case type
        when "cube", "box"
          build_box(group, pos, dims)
        when "cylinder"
          build_cylinder(group, pos, dims)
        when "sphere"
          build_sphere(group, pos, dims)
        when "cone"
          build_cone(group, pos, dims)
        else
          group.erase!
          raise ArgumentError, "Unknown component type: #{type.inspect}"
        end

        { success: true, id: group.entityID, type: type }
      end

      def self.build_box(group, pos, dims)
        face = group.entities.add_face(
          [pos[0],            pos[1],            pos[2]],
          [pos[0] + dims[0], pos[1],            pos[2]],
          [pos[0] + dims[0], pos[1] + dims[1], pos[2]],
          [pos[0],            pos[1] + dims[1], pos[2]],
        )
        face.pushpull(dims[2])
      end

      def self.build_cylinder(group, pos, dims)
        radius = dims[0] / 2.0
        height = dims[2]
        center = [pos[0] + radius, pos[1] + radius, pos[2]]
        face = group.entities.add_face(circle_points(center, radius, CIRCLE_SEGMENTS))
        face.pushpull(height)
      end

      def self.build_cone(group, pos, dims)
        radius = dims[0] / 2.0
        height = dims[2]
        center = [pos[0] + radius, pos[1] + radius, pos[2]]
        apex   = [center[0], center[1], center[2] + height]
        points = circle_points(center, radius, CIRCLE_SEGMENTS)

        group.entities.add_face(points)
        points.each_with_index do |p, i|
          group.entities.add_face(p, points[(i + 1) % points.length], apex)
        end
      end

      # UV sphere built from quads. Faces near the poles may collapse to
      # degenerate quads; SketchUp raises on those, so we skip them.
      def self.build_sphere(group, pos, dims)
        radius = dims[0] / 2.0
        center = [pos[0] + radius, pos[1] + radius, pos[2] + radius]
        n = SPHERE_SEGMENTS

        points = Array.new((n + 1) * (n + 1))
        (0..n).each do |lat_i|
          lat = Math::PI * lat_i / n
          (0..n).each do |lon_i|
            lon = 2 * Math::PI * lon_i / n
            points[lat_i * (n + 1) + lon_i] = [
              center[0] + radius * Math.sin(lat) * Math.cos(lon),
              center[1] + radius * Math.sin(lat) * Math.sin(lon),
              center[2] + radius * Math.cos(lat),
            ]
          end
        end

        (0...n).each do |lat_i|
          (0...n).each do |lon_i|
            i1 = lat_i * (n + 1) + lon_i
            i2 = i1 + 1
            i3 = i1 + n + 1
            i4 = i3 + 1
            begin
              group.entities.add_face(points[i1], points[i2], points[i4], points[i3])
            rescue StandardError
              # Degenerate quad at pole — skip.
            end
          end
        end
      end

      def self.circle_points(center, radius, segments)
        Array.new(segments) do |i|
          angle = 2 * Math::PI * i / segments
          [
            center[0] + radius * Math.cos(angle),
            center[1] + radius * Math.sin(angle),
            center[2],
          ]
        end
      end
    end
  end
end

SU_MCP::Dispatcher.register("create_component") { |params| SU_MCP::Tools::Components.create(params) }
