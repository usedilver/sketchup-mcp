module SU_MCP
  module Tools
    module Scene
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
    end
  end
end

SU_MCP::Dispatcher.register("get_scene_info") { |params| SU_MCP::Tools::Scene.info(params) }
SU_MCP::Dispatcher.register("get_selection") { |params| SU_MCP::Tools::Scene.selection(params) }
