require "fileutils"
require "tmpdir"

module SU_MCP
  module Tools
    module Scene
      EXPORT_SUBDIR = "sketchup_exports".freeze
      DEFAULT_IMG_W = 1920
      DEFAULT_IMG_H = 1080
      SUPPORTED_FORMATS = %w[skp obj dae stl png jpg jpeg].freeze

      def self.info(_params)
        model = Sketchup.active_model
        info_units = model.options["UnitsOptions"]

        {
          title:           model.title,
          path:            model.path,
          guid:            model.guid,
          modified:        model.modified?,
          length_unit:     info_units && info_units["LengthUnit"],
          length_format:   info_units && info_units["LengthFormat"],
          entity_count:    model.entities.length,
          selection_count: model.selection.length,
          layer_count:     model.layers.length,
          material_count:  model.materials.length,
          definition_count: model.definitions.length,
          active_view:     model.pages.selected_page&.name,
        }
      end

      def self.selection(_params)
        model = Sketchup.active_model
        entities = model.selection.map do |entity|
          {
            id:   entity.entityID,
            type: entity.typename.downcase,
            name: entity.respond_to?(:name) ? entity.name : nil,
          }
        end
        { count: entities.length, entities: entities }
      end

      def self.set_selection(params)
        ids = Array(params["ids"]).map(&:to_i)
        model = Sketchup.active_model
        model.selection.clear
        resolved = ids.map { |i| model.find_entity_by_id(i) }.compact
        model.selection.add(resolved) unless resolved.empty?
        { success: true, requested: ids.length, selected: resolved.length, missing: ids.length - resolved.length }
      end

      # Export the active model. Writes to a system-temp subdirectory by
      # default; pass `path` to override. For images (png/jpg) `width`
      # and `height` control the rendered size.
      def self.export(params)
        model  = Sketchup.active_model
        format = (params["format"] || "skp").to_s.downcase
        raise ArgumentError, "Unsupported export format: #{format}" unless SUPPORTED_FORMATS.include?(format)

        path = params["path"] || default_export_path(format)
        FileUtils.mkdir_p(File.dirname(path))

        case format
        when "skp"
          model.save(path)
        when "obj"
          model.export(path, triangulated_faces: true, double_sided_faces: true, edges: false, texture_maps: true)
        when "dae"
          model.export(path, triangulated_faces: true)
        when "stl"
          model.export(path, units: "model")
        when "png", "jpg", "jpeg"
          model.active_view.write_image(
            filename:    path,
            width:       (params["width"]  || DEFAULT_IMG_W).to_i,
            height:      (params["height"] || DEFAULT_IMG_H).to_i,
            antialias:   true,
            transparent: format == "png",
          )
        end

        { success: true, path: path, format: format }
      end

      def self.default_export_path(format)
        ext = format == "jpg" ? "jpeg" : format
        dir = File.join(Dir.tmpdir, EXPORT_SUBDIR)
        File.join(dir, "sketchup_export_#{Time.now.strftime('%Y%m%d_%H%M%S')}.#{ext}")
      end

      # Optionally aim the camera, then render the active view to PNG.
      # `camera` is `{eye, target, up, perspective?, fov?}` — all required
      # together if provided.
      def self.snapshot(params)
        width       = (params["width"]       || 1600).to_i
        height      = (params["height"]      || 1000).to_i
        antialias   = params["antialias"] != false
        compression = (params["compression"] || 0.9).to_f
        path        = params["path"] || File.join(Dir.tmpdir, EXPORT_SUBDIR, "snapshot_#{Time.now.strftime('%Y%m%d_%H%M%S')}.png")
        FileUtils.mkdir_p(File.dirname(path))

        view = Sketchup.active_model.active_view
        if (cam = params["camera"])
          eye    = cam["eye"]    && Geom::Point3d.new(*cam["eye"])
          target = cam["target"] && Geom::Point3d.new(*cam["target"])
          up     = cam["up"]     && Geom::Vector3d.new(*cam["up"])
          if eye && target && up
            view.camera = Sketchup::Camera.new(eye, target, up, cam.fetch("perspective", true), cam["fov"] || 50.0)
          end
        end

        view.write_image(path, width, height, antialias, compression)
        { success: true, path: path, width: width, height: height }
      end
    end
  end
end

SU_MCP::Dispatcher.register("get_scene_info") { |params| SU_MCP::Tools::Scene.info(params) }
SU_MCP::Dispatcher.register("get_selection")  { |params| SU_MCP::Tools::Scene.selection(params) }
SU_MCP::Dispatcher.register("set_selection")  { |params| SU_MCP::Tools::Scene.set_selection(params) }
SU_MCP::Dispatcher.register("export_scene")   { |params| SU_MCP::Tools::Scene.export(params) }
SU_MCP::Dispatcher.register("snapshot")       { |params| SU_MCP::Tools::Scene.snapshot(params) }
