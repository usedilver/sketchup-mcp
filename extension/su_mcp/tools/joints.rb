module SU_MCP
  module Tools
    module Joints
      # ──────────────────────────────────────────────────────────────────
      # Mortise & tenon
      # ──────────────────────────────────────────────────────────────────
      #
      # Auto-detects the closest face between the two boards and cuts a
      # rectangular pocket in the mortise board / extrudes a matching
      # block on the tenon board.
      def self.mortise_tenon(params)
        mortise = SU_MCP::Entities.find_solid!(params["mortise_id"], "mortise board")
        tenon   = SU_MCP::Entities.find_solid!(params["tenon_id"],   "tenon board")

        width  = (params["width"]  || 1.0).to_f
        height = (params["height"] || 1.0).to_f
        depth  = (params["depth"]  || 1.0).to_f
        offset = [params["offset_x"] || 0.0, params["offset_y"] || 0.0, params["offset_z"] || 0.0]

        direction       = tenon.bounds.center - mortise.bounds.center
        mortise_face    = closest_face(direction)
        tenon_face      = closest_face(direction.reverse)

        cut_pocket(mortise, mortise_face, width, height, depth, offset)
        extrude_tenon(tenon, tenon_face, width, height, depth, offset)

        { success: true, mortise_id: mortise.entityID, tenon_id: tenon.entityID }
      end

      # ──────────────────────────────────────────────────────────────────
      # Dovetail
      # ──────────────────────────────────────────────────────────────────
      def self.dovetail(params)
        tail_board = SU_MCP::Entities.find_solid!(params["tail_id"], "tail board")
        pin_board  = SU_MCP::Entities.find_solid!(params["pin_id"],  "pin board")

        width     = (params["width"]     || 1.0).to_f
        height    = (params["height"]    || 2.0).to_f
        depth     = (params["depth"]     || 1.0).to_f
        angle     = (params["angle"]     || 15.0).to_f
        num_tails = (params["num_tails"] || 3).to_i
        offset    = [params["offset_x"] || 0.0, params["offset_y"] || 0.0, params["offset_z"] || 0.0]

        build_tails(tail_board, width, height, depth, angle, num_tails, offset)
        build_pins(pin_board,   width, height, depth, angle, num_tails, offset)

        { success: true, tail_id: tail_board.entityID, pin_id: pin_board.entityID }
      end

      # ──────────────────────────────────────────────────────────────────
      # Finger joint
      # ──────────────────────────────────────────────────────────────────
      def self.finger_joint(params)
        board1 = SU_MCP::Entities.find_solid!(params["board1_id"], "board 1")
        board2 = SU_MCP::Entities.find_solid!(params["board2_id"], "board 2")

        width       = (params["width"]       || 1.0).to_f
        height      = (params["height"]      || 2.0).to_f
        depth       = (params["depth"]       || 1.0).to_f
        num_fingers = (params["num_fingers"] || 5).to_i
        offset      = [params["offset_x"] || 0.0, params["offset_y"] || 0.0, params["offset_z"] || 0.0]

        build_fingers(board1, width, height, depth, num_fingers, offset)
        cut_finger_slots(board2, width, height, depth, num_fingers, offset)

        { success: true, board1_id: board1.entityID, board2_id: board2.entityID }
      end

      # ──────────────────────────────────────────────────────────────────
      # Internals — mortise & tenon
      # ──────────────────────────────────────────────────────────────────

      def self.closest_face(vec)
        vec = vec.normalize
        ax, ay, az = vec.x.abs, vec.y.abs, vec.z.abs
        if ax >= ay && ax >= az
          vec.x > 0 ? :east : :west
        elsif ay >= az
          vec.y > 0 ? :north : :south
        else
          vec.z > 0 ? :top : :bottom
        end
      end

      def self.face_origin(face, bounds, w, h, d, off)
        cx, cy, cz = bounds.center.x, bounds.center.y, bounds.center.z
        case face
        when :east   then [bounds.max.x,         cy - w / 2 + off[1], cz - h / 2 + off[2]]
        when :west   then [bounds.min.x,         cy - w / 2 + off[1], cz - h / 2 + off[2]]
        when :north  then [cx - w / 2 + off[0], bounds.max.y,         cz - h / 2 + off[2]]
        when :south  then [cx - w / 2 + off[0], bounds.min.y,         cz - h / 2 + off[2]]
        when :top    then [cx - w / 2 + off[0], cy - h / 2 + off[1], bounds.max.z]
        when :bottom then [cx - w / 2 + off[0], cy - h / 2 + off[1], bounds.min.z]
        end
      end

      def self.cut_pocket(board, face, w, h, d, off)
        ents = SU_MCP::Entities.contents(board)
        pos  = face_origin(face, board.bounds, w, h, d, off)
        pocket = ents.add_group
        rect_face = pocket_face(pocket.entities, face, pos, w, h)
        rect_face.pushpull(pocket_depth(face, d))
        ents.subtract(pocket.entities)
        pocket.erase!
      end

      def self.extrude_tenon(board, face, w, h, d, off)
        ents = SU_MCP::Entities.contents(board)
        pos  = face_origin(face, board.bounds, w, h, d, off)
        tenon = ents.add_group
        rect_face = pocket_face(tenon.entities, face, pos, w, h)
        rect_face.pushpull(-pocket_depth(face, d))
      end

      def self.pocket_face(entities, face, pos, w, h)
        case face
        when :east, :west
          entities.add_face(
            [pos[0], pos[1],     pos[2]],
            [pos[0], pos[1] + w, pos[2]],
            [pos[0], pos[1] + w, pos[2] + h],
            [pos[0], pos[1],     pos[2] + h],
          )
        when :north, :south
          entities.add_face(
            [pos[0],     pos[1], pos[2]],
            [pos[0] + w, pos[1], pos[2]],
            [pos[0] + w, pos[1], pos[2] + h],
            [pos[0],     pos[1], pos[2] + h],
          )
        when :top, :bottom
          entities.add_face(
            [pos[0],     pos[1],     pos[2]],
            [pos[0] + w, pos[1],     pos[2]],
            [pos[0] + w, pos[1] + h, pos[2]],
            [pos[0],     pos[1] + h, pos[2]],
          )
        end
      end

      # Pocket extrudes inward, tenon outward — direction flips per face.
      def self.pocket_depth(face, depth)
        case face
        when :east, :north, :top then -depth
        else depth
        end
      end

      # ──────────────────────────────────────────────────────────────────
      # Internals — dovetail
      # ──────────────────────────────────────────────────────────────────

      def self.build_tails(board, width, height, depth, angle, num_tails, off)
        ents   = SU_MCP::Entities.contents(board)
        bounds = board.bounds
        cx     = bounds.center.x + off[0]
        cy     = bounds.center.y + off[1]
        cz     = bounds.center.z + off[2]
        tail_w = width / (2 * num_tails - 1)
        rad    = angle * Math::PI / 180.0
        bottom = tail_w + 2 * depth * Math.tan(rad)
        group  = ents.add_group

        num_tails.times do |i|
          tx = cx - width / 2 + tail_w * (2 * i)
          face = group.entities.add_face(
            [tx - tail_w / 2, cy - height / 2, cz],
            [tx + tail_w / 2, cy - height / 2, cz],
            [tx + bottom / 2, cy - height / 2, cz - depth],
            [tx - bottom / 2, cy - height / 2, cz - depth],
          )
          face.pushpull(height)
        end
      end

      def self.build_pins(board, width, height, depth, angle, num_tails, off)
        ents   = SU_MCP::Entities.contents(board)
        bounds = board.bounds
        cx     = bounds.center.x + off[0]
        cy     = bounds.center.y + off[1]
        cz     = bounds.center.z + off[2]
        tail_w = width / (2 * num_tails - 1)
        rad    = angle * Math::PI / 180.0
        bottom = tail_w + 2 * depth * Math.tan(rad)
        pins   = ents.add_group

        base = pins.entities.add_face(
          [cx - width / 2, cy - height / 2, cz],
          [cx + width / 2, cy - height / 2, cz],
          [cx + width / 2, cy + height / 2, cz],
          [cx - width / 2, cy + height / 2, cz],
        )
        base.pushpull(depth)

        num_tails.times do |i|
          tx = cx - width / 2 + tail_w * (2 * i)
          cutout = ents.add_group
          face = cutout.entities.add_face(
            [tx - tail_w / 2, cy - height / 2, cz],
            [tx + tail_w / 2, cy - height / 2, cz],
            [tx + bottom / 2, cy - height / 2, cz - depth],
            [tx - bottom / 2, cy - height / 2, cz - depth],
          )
          face.pushpull(height)
          pins.entities.subtract(cutout.entities)
          cutout.erase!
        end
      end

      # ──────────────────────────────────────────────────────────────────
      # Internals — finger joint
      # ──────────────────────────────────────────────────────────────────

      def self.build_fingers(board, width, height, depth, num_fingers, off)
        ents   = SU_MCP::Entities.contents(board)
        bounds = board.bounds
        cx     = bounds.center.x + off[0]
        cy     = bounds.center.y + off[1]
        cz     = bounds.center.z + off[2]
        finger_w = width / num_fingers
        group  = ents.add_group

        base = group.entities.add_face(
          [cx - width / 2, cy - height / 2, cz],
          [cx + width / 2, cy - height / 2, cz],
          [cx + width / 2, cy + height / 2, cz],
          [cx - width / 2, cy + height / 2, cz],
        )

        (num_fingers / 2).times do |i|
          ccx = cx - width / 2 + finger_w * (2 * i + 1)
          cutout = ents.add_group
          face = cutout.entities.add_face(
            [ccx - finger_w / 2, cy - height / 2, cz],
            [ccx + finger_w / 2, cy - height / 2, cz],
            [ccx + finger_w / 2, cy + height / 2, cz],
            [ccx - finger_w / 2, cy + height / 2, cz],
          )
          face.pushpull(depth)
          group.entities.subtract(cutout.entities)
          cutout.erase!
        end

        base.pushpull(depth)
      end

      def self.cut_finger_slots(board, width, height, depth, num_fingers, off)
        ents   = SU_MCP::Entities.contents(board)
        bounds = board.bounds
        cx     = bounds.center.x + off[0]
        cy     = bounds.center.y + off[1]
        cz     = bounds.center.z + off[2]
        finger_w = width / num_fingers

        ((num_fingers + 1) / 2).times do |i|
          ccx = cx - width / 2 + finger_w * (2 * i)
          cutout = ents.add_group
          face = cutout.entities.add_face(
            [ccx - finger_w / 2, cy - height / 2, cz],
            [ccx + finger_w / 2, cy - height / 2, cz],
            [ccx + finger_w / 2, cy + height / 2, cz],
            [ccx - finger_w / 2, cy + height / 2, cz],
          )
          face.pushpull(depth)
          ents.subtract(cutout.entities)
          cutout.erase!
        end
      end
    end
  end
end

SU_MCP::Dispatcher.register("create_mortise_tenon") { |params| SU_MCP::Tools::Joints.mortise_tenon(params) }
SU_MCP::Dispatcher.register("create_dovetail")      { |params| SU_MCP::Tools::Joints.dovetail(params) }
SU_MCP::Dispatcher.register("create_finger_joint")  { |params| SU_MCP::Tools::Joints.finger_joint(params) }
