module SU_MCP
  module Tools
    module Query
      # Returns bounds + position + material + class for an entity.
      # Lengths are in inches (SketchUp's internal unit) — clients can
      # convert via units_info if they need cm/mm/etc.
      def self.measure(params)
        entity = SU_MCP::Entities.find!(params["id"] || params["entity_id"])

        data = { id: entity.entityID, class: entity.class.name, valid: entity.valid? }

        if entity.respond_to?(:bounds)
          bb = entity.bounds
          data[:bounds] = { min: bb.min.to_a, max: bb.max.to_a, size: [bb.width, bb.height, bb.depth] }
        end

        if entity.respond_to?(:transformation)
          data[:position] = entity.transformation.origin.to_a
        end

        if entity.respond_to?(:material) && entity.material
          data[:material] = { name: entity.material.display_name, color: entity.material.color.to_a }
        end

        case entity
        when Sketchup::ComponentInstance then data[:definition] = entity.definition.name
        when Sketchup::Group             then data[:group_name] = entity.name
        end

        data
      end

      # Lists component definitions in the model. Optional `name_match`
      # is a case-insensitive regex.
      def self.list_definitions(params)
        match = params["name_match"]
        include_bounds = params["include_bounds"] != false

        rx = match && !match.to_s.empty? ? Regexp.new(match.to_s, Regexp::IGNORECASE) : nil

        results = Sketchup.active_model.definitions.map do |d|
          next nil if rx && !rx.match?(d.name.to_s)
          entry = {
            name:           d.name,
            instance_count: d.count_instances,
            is_component:   d.is_a?(Sketchup::ComponentDefinition),
          }
          if include_bounds
            bb = d.bounds
            entry[:bounds_size] = [bb.width, bb.height, bb.depth]
          end
          entry
        end.compact

        { count: results.length, definitions: results }
      end

      # Lists component instances and groups (top-level only). Filters
      # by definition name and an axis-aligned bounding box.
      def self.list_instances(params)
        want_def  = params["definition_name"]
        limit     = (params["limit"] || 500).to_i
        bb_filter = params["bounds"]

        collected = []
        Sketchup.active_model.entities.each do |e|
          break if collected.length >= limit
          next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)

          name = e.is_a?(Sketchup::ComponentInstance) ? e.definition.name : e.name
          next if want_def && name != want_def
          next unless intersects_bounds?(e.bounds, bb_filter)

          entry = { id: e.entityID, name: name, bounds_min: e.bounds.min.to_a, bounds_max: e.bounds.max.to_a }
          entry[:position] = e.transformation.origin.to_a if e.respond_to?(:transformation)
          collected << entry
        end

        { count: collected.length, instances: collected, truncated: collected.length >= limit }
      end

      def self.intersects_bounds?(bb, filter)
        return true unless filter
        min = filter["min"]
        max = filter["max"]
        return true unless min && max
        !(bb.max.x < min[0] || bb.min.x > max[0] ||
          bb.max.y < min[1] || bb.min.y > max[1] ||
          bb.max.z < min[2] || bb.min.z > max[2])
      end
    end
  end
end

SU_MCP::Dispatcher.register("measure")          { |params| SU_MCP::Tools::Query.measure(params) }
SU_MCP::Dispatcher.register("list_definitions") { |params| SU_MCP::Tools::Query.list_definitions(params) }
SU_MCP::Dispatcher.register("list_instances")   { |params| SU_MCP::Tools::Query.list_instances(params) }
