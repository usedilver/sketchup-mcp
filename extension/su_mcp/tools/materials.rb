module SU_MCP
  module Tools
    module Materials
      NAMED_COLORS = {
        "red"       => [255,   0,   0],
        "green"     => [  0, 255,   0],
        "blue"      => [  0,   0, 255],
        "yellow"    => [255, 255,   0],
        "cyan"      => [  0, 255, 255],
        "turquoise" => [  0, 255, 255],
        "magenta"   => [255,   0, 255],
        "purple"    => [255,   0, 255],
        "white"     => [255, 255, 255],
        "black"     => [  0,   0,   0],
        "brown"     => [139,  69,  19],
        "orange"    => [255, 165,   0],
        "gray"      => [128, 128, 128],
        "grey"      => [128, 128, 128],
        "wood"      => [184, 134,  72],
      }.freeze

      DEFAULT_RGB = [184, 134, 72].freeze # wood

      def self.set(params)
        entity = SU_MCP::Entities.find!(params["id"])
        name   = params["material"].to_s
        raise ArgumentError, "material is required" if name.empty?

        material = find_or_create_material(name)
        apply(entity, material)

        { success: true, id: entity.entityID, material: material.name }
      end

      def self.find_or_create_material(name)
        model = Sketchup.active_model
        existing = model.materials[name]
        return existing if existing

        material = model.materials.add(name)
        rgb = resolve_color(name)
        material.color = Sketchup::Color.new(*rgb)
        material
      end

      def self.resolve_color(name)
        NAMED_COLORS[name.downcase] || parse_hex(name) || DEFAULT_RGB
      end

      def self.parse_hex(name)
        return nil unless name.start_with?("#") && name.length == 7
        [name[1..2], name[3..4], name[5..6]].map { |hex| Integer(hex, 16) }
      rescue ArgumentError
        nil
      end

      # Materials apply to faces, not to groups/components directly. For
      # those, walk into the contained entities and paint each face.
      def self.apply(entity, material)
        if entity.is_a?(Sketchup::Group)
          entity.entities.grep(Sketchup::Face).each { |face| face.material = material }
        elsif entity.is_a?(Sketchup::ComponentInstance)
          entity.definition.entities.grep(Sketchup::Face).each { |face| face.material = material }
        elsif entity.respond_to?(:material=)
          entity.material = material
        else
          raise "Cannot apply material to #{entity.class}"
        end
      end
    end
  end
end

SU_MCP::Dispatcher.register("set_material") { |params| SU_MCP::Tools::Materials.set(params) }
