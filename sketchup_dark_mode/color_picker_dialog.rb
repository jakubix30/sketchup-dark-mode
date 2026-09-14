# frozen_string_literal: true

require 'fiddle'

module SketchupDarkMode
  module ColorPickerDialog
    extend self

    CHOOSECOLOR_SIZE = 72 # 64-bit

    CC_RGBINIT   = 0x00000001
    CC_FULLOPEN  = 0x00000002

    @cust_colors = nil
    @fn_choose_color = nil
    @dialog = nil

    def init_win32
      return if @fn_choose_color

      @cust_colors = Fiddle::Pointer.malloc(16 * 4)
      (16 * 4).times { |i| @cust_colors[i] = 0xFF }

      comdlg32 = Fiddle.dlopen('comdlg32.dll')
      @fn_choose_color = Fiddle::Function.new(
        comdlg32['ChooseColorW'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_INT
      )
    rescue StandardError => e
      puts "[Dark Mode] Windows ChooseColorW unavailable: #{e.message}"
    end

    # Opens native Windows Color dialog (comdlg32)
    def pick_windows_color(current_hex)
      init_win32
      return nil unless @fn_choose_color

      r = 30
      g = 30
      b = 32
      if current_hex.to_s =~ /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i
        r = Regexp.last_match(1).to_i(16)
        g = Regexp.last_match(2).to_i(16)
        b = Regexp.last_match(3).to_i(16)
      end

      rgb_init = r | (g << 8) | (b << 16)

      mem = Fiddle::Pointer.malloc(CHOOSECOLOR_SIZE)
      CHOOSECOLOR_SIZE.times { |i| mem[i] = 0 }

      # lStructSize (DWORD at offset 0)
      mem[0, 4] = [CHOOSECOLOR_SIZE].pack('L')
      # rgbResult (DWORD at offset 24)
      mem[24, 4] = [rgb_init].pack('L')
      # lpCustColors (pointer at offset 32)
      mem[32, 8] = [@cust_colors.to_i].pack('Q')
      # Flags (DWORD at offset 40)
      mem[40, 4] = [CC_RGBINIT | CC_FULLOPEN].pack('L')

      res = @fn_choose_color.call(mem)
      if res != 0
        rgb = mem[24, 4].unpack1('L')
        res_r = rgb & 0xFF
        res_g = (rgb >> 8) & 0xFF
        res_b = (rgb >> 16) & 0xFF
        format('#%02x%02x%02x', res_r, res_g, res_b)
      else
        nil
      end
    rescue StandardError => e
      puts "[Dark Mode] Error in ChooseColorW: #{e.message}"
      nil
    end

    def show
      if @dialog && @dialog.visible?
        @dialog.bring_to_front
        return
      end

      title = I18n.t(:color_picker_title)
      @dialog = UI::HtmlDialog.new(
        dialog_title: title,
        preferences_key: 'SketchupDarkMode_ColorPicker',
        scrollable: true,
        resizable: true,
        width: 520,
        height: 640,
        min_width: 460,
        min_height: 520,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      @dialog.set_html(generate_html)

      # Register JS callbacks
      @dialog.add_action_callback('apply_live') do |_action_context, bg_hex, edge_hex|
        Config['viewport_bg_hex'] = bg_hex.to_s.strip
        Config['viewport_edge_hex'] = edge_hex.to_s.strip
        if Main.dark_mode_active? && Config['style_viewport']
          ViewportStyler.apply_dark_viewport(Sketchup.active_model)
        end
      end

      @dialog.add_action_callback('save_and_close') do |_action_context, bg_hex, edge_hex|
        Config['viewport_bg_hex'] = bg_hex.to_s.strip
        Config['viewport_edge_hex'] = edge_hex.to_s.strip
        if Main.dark_mode_active? && Config['style_viewport']
          ViewportStyler.apply_dark_viewport(Sketchup.active_model)
        end
        @dialog.close
      end

      @dialog.add_action_callback('pick_system_color') do |_action_context, target, current_hex|
        picked = pick_windows_color(current_hex)
        if picked
          @dialog.execute_script("onSystemColorPicked('#{target}', '#{picked}');")
        end
      end

      @dialog.add_action_callback('close_dialog') do |_action_context|
        @dialog.close
      end

      @dialog.center
      @dialog.show
    end

    private

    def generate_html
      is_pl = (Config['language'].to_s.downcase == 'pl') ||
              (Config['language'].to_s.downcase == 'auto' && I18n.system_language == 'pl')

      bg_val   = Config['viewport_bg_hex']   || '#1e1e20'
      edge_val = Config['viewport_edge_hex'] || '#dedee0'

      labels = if is_pl
                 {
                   header_title: 'Wybór kolorów widoku 3D',
                   header_sub: 'Dostosuj kolorystykę tła oraz krawędzi modeli w trybie ciemnym',
                   presets_label: 'Szybkie schematy (Presety):',
                   preset_default: 'Domyślny grafit',
                   preset_oled: 'Głęboka czerń (OLED)',
                   preset_nord: 'Nord Night',
                   preset_slate: 'Szary studyjny',
                   preset_blueprint: 'Granat architektoniczny',
                   preset_light: 'Klasyczny jasny',
                   bg_title: 'Kolor tła widoku (Background)',
                   bg_desc: 'Kolor tła przestrzeni modelowania 3D',
                   edge_title: 'Kolor krawędzi modeli (Edges)',
                   edge_desc: 'Kolor linii i konturów brył w widoku 3D',
                   preview_title: 'Podgląd na żywo',
                   btn_system: 'Paleta Windows...',
                   btn_apply: 'Zastosuj w SketchUp',
                   btn_save: 'Zapisz i zamknij',
                   btn_reset: 'Przywróć domyślne',
                   btn_cancel: 'Anuluj'
                 }
               else
                 {
                   header_title: '3D Viewport Color Picker',
                   header_sub: 'Customize canvas background and model edge colors for Dark Mode',
                   presets_label: 'Color Presets:',
                   preset_default: 'Default Graphite',
                   preset_oled: 'OLED Pitch Black',
                   preset_nord: 'Nord Night',
                   preset_slate: 'Studio Slate',
                   preset_blueprint: 'Architectural Navy',
                   preset_light: 'Classic Light',
                   bg_title: 'Canvas Background Color',
                   bg_desc: 'Background color of the 3D modeling space',
                   edge_title: 'Model Edges Color',
                   edge_desc: 'Contour and line color of 3D geometry',
                   preview_title: 'Live Preview',
                   btn_system: 'Windows Palette...',
                   btn_apply: 'Apply to SketchUp',
                   btn_save: 'Save & Close',
                   btn_reset: 'Reset Defaults',
                   btn_cancel: 'Cancel'
                 }
               end

      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <title>#{labels[:header_title]}</title>
          <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              background-color: #1e1e1e;
              color: #e0e0e0;
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
              font-size: 13px;
              padding: 16px;
              user-select: none;
            }
            .header {
              border-bottom: 1px solid #333333;
              padding-bottom: 12px;
              margin-bottom: 16px;
            }
            .header h1 {
              font-size: 16px;
              font-weight: 600;
              color: #ffffff;
              display: flex;
              align-items: center;
              gap: 8px;
            }
            .header p {
              color: #888888;
              font-size: 11px;
              margin-top: 4px;
            }
            .section-title {
              font-size: 12px;
              font-weight: 600;
              color: #cccccc;
              text-transform: uppercase;
              letter-spacing: 0.5px;
              margin-bottom: 8px;
            }
            /* Presets Bar */
            .presets-grid {
              display: grid;
              grid-template-columns: repeat(3, 1fr);
              gap: 8px;
              margin-bottom: 16px;
            }
            .preset-btn {
              background-color: #252526;
              border: 1px solid #3e3e42;
              border-radius: 4px;
              padding: 6px 8px;
              cursor: pointer;
              display: flex;
              align-items: center;
              gap: 8px;
              transition: all 0.15s ease;
              color: #d4d4d4;
              font-size: 11px;
            }
            .preset-btn:hover {
              background-color: #2d2d30;
              border-color: #007acc;
              color: #ffffff;
            }
            .preset-pill {
              width: 18px;
              height: 18px;
              border-radius: 50%;
              border: 1px solid rgba(255,255,255,0.2);
              flex-shrink: 0;
            }
            /* Color Pickers Card */
            .card {
              background-color: #252526;
              border: 1px solid #333333;
              border-radius: 6px;
              padding: 12px;
              margin-bottom: 14px;
            }
            .picker-row {
              display: flex;
              align-items: center;
              justify-content: space-between;
              padding: 8px 0;
            }
            .picker-row:not(:last-child) {
              border-bottom: 1px solid #2e2e30;
            }
            .picker-info h3 {
              font-size: 13px;
              font-weight: 500;
              color: #ffffff;
            }
            .picker-info p {
              font-size: 11px;
              color: #888888;
            }
            .picker-controls {
              display: flex;
              align-items: center;
              gap: 8px;
            }
            input[type="color"] {
              -webkit-appearance: none;
              border: 1px solid #555555;
              border-radius: 4px;
              width: 34px;
              height: 28px;
              cursor: pointer;
              background: transparent;
              padding: 0;
            }
            input[type="color"]::-webkit-color-swatch-wrapper {
              padding: 0;
            }
            input[type="color"]::-webkit-color-swatch {
              border: none;
              border-radius: 3px;
            }
            .hex-input {
              width: 75px;
              background-color: #1e1e1e;
              border: 1px solid #3e3e42;
              border-radius: 4px;
              color: #ffffff;
              font-family: monospace;
              font-size: 12px;
              padding: 4px 6px;
              text-transform: uppercase;
              text-align: center;
            }
            .hex-input:focus {
              border-color: #007acc;
              outline: none;
            }
            .btn-mini {
              background-color: #333337;
              border: 1px solid #444448;
              border-radius: 4px;
              color: #cccccc;
              font-size: 10px;
              padding: 5px 7px;
              cursor: pointer;
              white-space: nowrap;
            }
            .btn-mini:hover {
              background-color: #3e3e42;
              color: #ffffff;
              border-color: #555555;
            }
            /* Preview Canvas Box */
            .preview-box {
              background-color: #252526;
              border: 1px solid #333333;
              border-radius: 6px;
              padding: 10px;
              margin-bottom: 16px;
              display: flex;
              flex-direction: column;
              align-items: center;
            }
            #previewCanvas {
              border-radius: 4px;
              box-shadow: 0 2px 8px rgba(0,0,0,0.5);
              transition: background-color 0.2s ease;
            }
            /* Action Buttons */
            .actions {
              display: flex;
              align-items: center;
              justify-content: flex-end;
              gap: 8px;
              padding-top: 8px;
            }
            .btn {
              padding: 7px 14px;
              border-radius: 4px;
              font-size: 12px;
              font-weight: 500;
              cursor: pointer;
              transition: all 0.15s ease;
            }
            .btn-primary {
              background-color: #0e639c;
              border: 1px solid #1177bb;
              color: #ffffff;
            }
            .btn-primary:hover {
              background-color: #1177bb;
            }
            .btn-secondary {
              background-color: #333337;
              border: 1px solid #3e3e42;
              color: #cccccc;
            }
            .btn-secondary:hover {
              background-color: #3e3e42;
              color: #ffffff;
            }
            .btn-default {
              margin-right: auto;
              background-color: transparent;
              border: 1px solid #3e3e42;
              color: #888888;
            }
            .btn-default:hover {
              color: #cccccc;
              border-color: #555555;
            }
          </style>
        </head>
        <body>

          <div class="header">
            <h1>🎨 #{labels[:header_title]}</h1>
            <p>#{labels[:header_sub]}</p>
          </div>

          <div class="section-title">#{labels[:presets_label]}</div>
          <div class="presets-grid">
            <button class="preset-btn" onclick="applyPreset('#1e1e20', '#dedee0')">
              <span class="preset-pill" style="background:#1e1e20; border-color:#dedee0;"></span>
              #{labels[:preset_default]}
            </button>
            <button class="preset-btn" onclick="applyPreset('#0f0f10', '#ffffff')">
              <span class="preset-pill" style="background:#0f0f10; border-color:#ffffff;"></span>
              #{labels[:preset_oled]}
            </button>
            <button class="preset-btn" onclick="applyPreset('#2e3440', '#eceff4')">
              <span class="preset-pill" style="background:#2e3440; border-color:#eceff4;"></span>
              #{labels[:preset_nord]}
            </button>
            <button class="preset-btn" onclick="applyPreset('#252526', '#cccccc')">
              <span class="preset-pill" style="background:#252526; border-color:#cccccc;"></span>
              #{labels[:preset_slate]}
            </button>
            <button class="preset-btn" onclick="applyPreset('#1a2634', '#a8c5e2')">
              <span class="preset-pill" style="background:#1a2634; border-color:#a8c5e2;"></span>
              #{labels[:preset_blueprint]}
            </button>
            <button class="preset-btn" onclick="applyPreset('#ffffff', '#000000')">
              <span class="preset-pill" style="background:#ffffff; border-color:#000000;"></span>
              #{labels[:preset_light]}
            </button>
          </div>

          <div class="card">
            <!-- Background Color -->
            <div class="picker-row">
              <div class="picker-info">
                <h3>#{labels[:bg_title]}</h3>
                <p>#{labels[:bg_desc]}</p>
              </div>
              <div class="picker-controls">
                <input type="color" id="bgColor" value="#{bg_val}" oninput="onBgChange(this.value)">
                <input type="text" id="bgHex" class="hex-input" value="#{bg_val}" onchange="onHexChange('bg', this.value)">
                <button class="btn-mini" onclick="pickSystemColor('bg')">#{labels[:btn_system]}</button>
              </div>
            </div>

            <!-- Edge Color -->
            <div class="picker-row">
              <div class="picker-info">
                <h3>#{labels[:edge_title]}</h3>
                <p>#{labels[:edge_desc]}</p>
              </div>
              <div class="picker-controls">
                <input type="color" id="edgeColor" value="#{edge_val}" oninput="onEdgeChange(this.value)">
                <input type="text" id="edgeHex" class="hex-input" value="#{edge_val}" onchange="onHexChange('edge', this.value)">
                <button class="btn-mini" onclick="pickSystemColor('edge')">#{labels[:btn_system]}</button>
              </div>
            </div>
          </div>

          <!-- Live 3D Preview Box -->
          <div class="preview-box">
            <canvas id="previewCanvas" width="460" height="150"></canvas>
          </div>

          <!-- Bottom Action Buttons -->
          <div class="actions">
            <button class="btn btn-default" onclick="resetDefaults()">#{labels[:btn_reset]}</button>
            <button class="btn btn-secondary" onclick="applyLive()">#{labels[:btn_apply]}</button>
            <button class="btn btn-primary" onclick="saveAndClose()">#{labels[:btn_save]}</button>
            <button class="btn btn-secondary" onclick="cancel()">#{labels[:btn_cancel]}</button>
          </div>

          <script>
            let curBg = "#{bg_val}";
            let curEdge = "#{edge_val}";

            function onBgChange(val) {
              curBg = val.toLowerCase();
              document.getElementById('bgHex').value = curBg;
              drawPreview();
            }

            function onEdgeChange(val) {
              curEdge = val.toLowerCase();
              document.getElementById('edgeHex').value = curEdge;
              drawPreview();
            }

            function onHexChange(target, hex) {
              if (!hex.startsWith('#')) hex = '#' + hex;
              if (/^#[0-9a-f]{6}$/i.test(hex)) {
                if (target === 'bg') {
                  curBg = hex.toLowerCase();
                  document.getElementById('bgColor').value = curBg;
                  document.getElementById('bgHex').value = curBg;
                } else {
                  curEdge = hex.toLowerCase();
                  document.getElementById('edgeColor').value = curEdge;
                  document.getElementById('edgeHex').value = curEdge;
                }
                drawPreview();
              }
            }

            function applyPreset(bg, edge) {
              curBg = bg;
              curEdge = edge;
              document.getElementById('bgColor').value = bg;
              document.getElementById('bgHex').value = bg;
              document.getElementById('edgeColor').value = edge;
              document.getElementById('edgeHex').value = edge;
              drawPreview();
              applyLive();
            }

            function pickSystemColor(target) {
              const cur = (target === 'bg') ? curBg : curEdge;
              sketchup.pick_system_color(target, cur);
            }

            function onSystemColorPicked(target, hex) {
              if (target === 'bg') {
                onBgChange(hex);
              } else {
                onEdgeChange(hex);
              }
            }

            function applyLive() {
              sketchup.apply_live(curBg, curEdge);
            }

            function saveAndClose() {
              sketchup.save_and_close(curBg, curEdge);
            }

            function cancel() {
              sketchup.close_dialog();
            }

            function resetDefaults() {
              applyPreset('#1e1e20', '#dedee0');
            }

            // Draw 3D Isometric Viewport Preview
            function drawPreview() {
              const canvas = document.getElementById('previewCanvas');
              const ctx = canvas.getContext('2d');
              const w = canvas.width;
              const h = canvas.height;

              // Fill background
              ctx.fillStyle = curBg;
              ctx.fillRect(0, 0, w, h);

              // Draw subtle ground horizon
              ctx.strokeStyle = 'rgba(128,128,128,0.2)';
              ctx.lineWidth = 1;
              ctx.beginPath();
              ctx.moveTo(0, h * 0.65);
              ctx.lineTo(w, h * 0.65);
              ctx.stroke();

              // Draw Isometric Cube
              const cx = w / 2;
              const cy = h / 2 + 10;
              const size = 48;

              // Top vertex
              const top = { x: cx, y: cy - size };
              const right = { x: cx + size * 0.866, y: cy - size * 0.5 };
              const left = { x: cx - size * 0.866, y: cy - size * 0.5 };
              const center = { x: cx, y: cy };
              const botRight = { x: cx + size * 0.866, y: cy + size * 0.5 };
              const botLeft = { x: cx - size * 0.866, y: cy + size * 0.5 };
              const bottom = { x: cx, y: cy + size };

              // Shaded faces
              // Top face
              ctx.fillStyle = 'rgba(255, 255, 255, 0.15)';
              ctx.beginPath();
              ctx.moveTo(top.x, top.y);
              ctx.lineTo(right.x, right.y);
              ctx.lineTo(center.x, center.y);
              ctx.lineTo(left.x, left.y);
              ctx.closePath();
              ctx.fill();

              // Left face
              ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
              ctx.beginPath();
              ctx.moveTo(left.x, left.y);
              ctx.lineTo(center.x, center.y);
              ctx.lineTo(bottom.x, bottom.y);
              ctx.lineTo(botLeft.x, botLeft.y);
              ctx.closePath();
              ctx.fill();

              // Right face
              ctx.fillStyle = 'rgba(0, 0, 0, 0.08)';
              ctx.beginPath();
              ctx.moveTo(center.x, center.y);
              ctx.lineTo(right.x, right.y);
              ctx.lineTo(botRight.x, botRight.y);
              ctx.lineTo(bottom.x, bottom.y);
              ctx.closePath();
              ctx.fill();

              // Edges in chosen color!
              ctx.strokeStyle = curEdge;
              ctx.lineWidth = 1.6;
              ctx.beginPath();

              // Top face edges
              ctx.moveTo(top.x, top.y); ctx.lineTo(right.x, right.y);
              ctx.lineTo(center.x, center.y); ctx.lineTo(left.x, left.y);
              ctx.lineTo(top.x, top.y);

              // Vertical edges
              ctx.moveTo(left.x, left.y); ctx.lineTo(botLeft.x, botLeft.y);
              ctx.moveTo(center.x, center.y); ctx.lineTo(bottom.x, bottom.y);
              ctx.moveTo(right.x, right.y); ctx.lineTo(botRight.x, botRight.y);

              // Bottom face edges
              ctx.moveTo(botLeft.x, botLeft.y); ctx.lineTo(bottom.x, bottom.y);
              ctx.lineTo(botRight.x, botRight.y);
              ctx.stroke();

              // Watermark text in corner
              ctx.fillStyle = 'rgba(150,150,150,0.5)';
              ctx.font = '10px sans-serif';
              ctx.fillText("3D Viewport Live Simulation", 10, h - 10);
            }

            // Initial render
            drawPreview();
          </script>
        </body>
        </html>
      HTML
    end
  end
end
