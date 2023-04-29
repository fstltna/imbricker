--[[
Quick tutorial:

- In the INIT script: 

local lib_dir = gh_utils.get_scripting_libs_dir()     
dofile(lib_dir .. "lua/libfont/libfont2.lua")    

font = libfont2_new_font(font_filename, font_height, tex_size)


- In the FRAME script:

libfont2_clear(font)
libfont2_print(font, 20, 20, 1, 1, 0, 1, "Hello in Yellow")
libfont2_print(font, 20, 40, 1, 0, 0, 1, "Hello in Red")

-- UTF8
libfont2_wprint(font, 20, 40, 1, 0, 0, 1, "Héllô UTF8")

libfont2_render(font)
--]]



_libfont2_initialized = 0
_libfont2_camera_ortho = 0
_libfont2_gpu_program = 0

_libfont2_fonts = {}
_libfont2_num_fonts = 0
--_libfont2_font0 = 0 -- default font




function _libfont2_init_gpu_program()
  if (_libfont2_gpu_program > 0) then
    return
  end
  
  local vs_gl3=" \
  in vec4 gxl3d_Position; \
  in vec4 gxl3d_TexCoord0; \
  in vec4 gxl3d_Color; \
  uniform mat4 gxl3d_ModelViewProjectionMatrix; \
  uniform vec4 gxl3d_Viewport; \
  out vec4 Vertex_UV; \
  out vec4 Vertex_Color; \
  void main() \
  { \
    vec4 V = vec4(gxl3d_Position.xyz, 1); \
    V.x = V.x - gxl3d_Viewport.z / 2.0; \
    V.y = V.y + gxl3d_Viewport.w / 2.0; \
    gl_Position = gxl3d_ModelViewProjectionMatrix * V; \
    Vertex_UV = gxl3d_TexCoord0; \
    Vertex_Color = gxl3d_Color; \
  }"
    
  local ps_gl3=" \
  uniform sampler2D tex0; \
  in vec4 Vertex_UV; \
  in vec4 Vertex_Color; \
  out vec4 FragColor; \
  void main (void) \
  { \
    vec2 uv = Vertex_UV.xy; \
    float t = texture(tex0,uv).r; \
    FragColor = vec4(t * Vertex_Color.rgb, Vertex_Color.a * t); \
  }"
    
  local vs_gl2=" \
  #version 120 \
  attribute vec4 gxl3d_Position; \
  attribute vec4 gxl3d_TexCoord0; \
  attribute vec4 gxl3d_Color; \
  uniform mat4 gxl3d_ModelViewProjectionMatrix; \
  uniform vec4 gxl3d_Viewport; \
  varying vec4 Vertex_UV; \
  varying vec4 Vertex_Color; \
  void main() \
  { \
    vec4 V = vec4(gxl3d_Position.xyz, 1); \
    V.x = V.x - gxl3d_Viewport.z / 2.0; \
    V.y = V.y + gxl3d_Viewport.w / 2.0; \
    gl_Position = gl_ModelViewProjectionMatrix * V;		 \
    Vertex_UV = gxl3d_TexCoord0; \
    Vertex_Color = gxl3d_Color; \
  }"
    
  local ps_gl2=" \
  #version 120 \
  uniform sampler2D tex0; \
  varying vec4 Vertex_UV; \
  varying vec4 Vertex_Color; \
  void main (void) \
  { \
    vec2 uv = Vertex_UV.xy; \
    float t = texture2D(tex0,uv).r; \
    gl_FragColor = vec4(t * Vertex_Color.rgb, Vertex_Color.a * t); \
  }"
  
  
  
  local vs_gles2=" \
  attribute vec4 gxl3d_Position; \
  attribute vec4 gxl3d_TexCoord0; \
  attribute vec4 gxl3d_Color; \
  uniform mat4 gxl3d_ModelViewProjectionMatrix; \
  uniform vec4 gxl3d_Viewport; \
  varying vec4 Vertex_UV; \
  varying vec4 Vertex_Color; \
  void main() \
  { \
    vec4 V = vec4(gxl3d_Position.xyz, 1.0); \
    V.x = V.x - gxl3d_Viewport.z / 2.0; \
    V.y = V.y + gxl3d_Viewport.w / 2.0; \
    gl_Position = gxl3d_ModelViewProjectionMatrix * V;		 \
    Vertex_UV = gxl3d_TexCoord0; \
    Vertex_Color = gxl3d_Color; \
  }"
    
  local ps_gles2=" \
  uniform sampler2D tex0; \
  varying highp vec4 Vertex_UV; \
  varying highp vec4 Vertex_Color; \
  void main (void) \
  { \
    highp vec2 uv = Vertex_UV.xy; \
    highp float t = texture2D(tex0,uv).r; \
    gl_FragColor = vec4(t * Vertex_Color.rgb, Vertex_Color.a * t); \
  }"
  
  if ((gh_utils.get_platform() == 4) and (gh_renderer.is_opengl_es() == 1)) then
    -- Raspberry Pi
    _libfont2_gpu_program = gh_gpu_program.create_v2("libfont2_gpu_program",vs_gles2, ps_gles2)
  else
    local vs = ""
    local ps = ""
    if (gh_renderer.get_api_version_major() > 3) then
      vs = "#version 150\n" .. vs_gl3
      ps = "#version 150\n" .. ps_gl3
      _libfont2_gpu_program = gh_gpu_program.create_v2("libfont2_gpu_program", vs, ps)
    
    elseif (gh_renderer.get_api_version_major() == 3) then
    
      if (gh_renderer.is_opengl_es() == 1) then
          vs = vs_gles2
          ps = ps_gles2
      else
        if (gh_renderer.get_api_version_minor() < 2) then
          vs = "#version 130\n" .. vs_gl3
          ps = "#version 130\n" .. ps_gl3
        else
          vs = "#version 150\n" .. vs_gl3
          ps = "#version 150\n" .. ps_gl3
        end
      end
      _libfont2_gpu_program = gh_gpu_program.create_v2("libfont2_gpu_program", vs, ps)
    else
      _libfont2_gpu_program = gh_gpu_program.create_v2("libfont2_gpu_program", vs_gl2, ps_gl2)
    end
  end

  gh_gpu_program.uniform1i(_libfont2_gpu_program, "tex0", 0)

end  


function _libfont2_init()
  if (_libfont2_initialized == 0) then
    _libfont2_init_gpu_program()

    local win_w, win_h = gh_window.getsize(0)
    _libfont2_camera_ortho = gh_camera.create_ortho(-win_w/2, win_w/2, -win_h/2, win_h/2, 1.0, 10.0)
    gh_camera.set_viewport(_libfont2_camera_ortho, 0, 0, win_w, win_h)
    gh_camera.set_position(_libfont2_camera_ortho, 0, 0, 4)
    gh_camera.set_lookat(_libfont2_camera_ortho, 0, 0, 0, 1)


    --local lib_dir = gh_utils.get_scripting_libs_dir()     
    --_libfont2_font0 = libfont2_new_font(lib_dir .. "lua/libfont/consolasboldmod8.2.ttf", 20, 512)

    _libfont2_initialized = 1
  end
end


--[[
-- libfont_kill is not necessary.
--
function libfont_kill()
  if (_libfont_font > 0) then
    gh_utils.ftgl_font_kill(_libfont_font)
  end
end
--]]



function _libfont2_resize(w, h)
  gh_camera.update_ortho(_libfont2_camera_ortho, -w/2, w/2, -h/2, h/2, 1.0, 10.0)
  gh_camera.set_viewport(_libfont2_camera_ortho, 0, 0, w, h)
end




function libfont2_new_font(font_filename, font_height, tex_size)
  local font = {fid=0, texture=0, height=font_height, filename=font_filename}
  _libfont2_num_fonts = _libfont2_num_fonts + 1
  _libfont2_fonts[_libfont2_num_fonts] = font

  font.fid = gh_font.create(font_filename, font_height, tex_size, tex_size)
    
  gh_font.build_texture(font.fid)
  font.texture = gh_font.get_texture(font.fid)

  return font
end  






function libfont2_get_text_width(font, text)
  _libfont2_init()
  return gh_font.get_text_width(font.fid, text)
end  


function libfont2_clear(font)
  _libfont2_init()
  gh_font.clear(font.fid)
end  

function libfont2_print(font, x, y, r, g, b, a, text)
  _libfont2_init()
  gh_font.text_2d(font.fid, x, y, r, g, b, a, text)
end  

function libfont2_print2(font, r, g, b, a, text)
  _libfont2_init()
  gh_font.text_2d_v2(font.fid, r, g, b, a, text)
end  

function libfont2_wprint(font, x, y, r, g, b, a, text)
  _libfont2_init()
  gh_font.wtext_2d(font.fid, x, y, r, g, b, a, text)
end  

function libfont2_wprint2(font, r, g, b, a, text)
  _libfont2_init()
  gh_font.wtext_2d_v2(font.fid, r, g, b, a, text)
end  

function libfont2_render(font)

  gh_renderer.set_blending_state(1)
  --[[
  BLEND_FACTOR_ZERO = 0
  BLEND_FACTOR_ONE = 1
  BLEND_FACTOR_SRC_ALPHA = 2
  BLEND_FACTOR_ONE_MINUS_DST_ALPHA = 3
  BLEND_FACTOR_ONE_MINUS_DST_COLOR = 4
  BLEND_FACTOR_ONE_MINUS_SRC_ALPHA = 5
  BLEND_FACTOR_DST_COLOR = 6
  BLEND_FACTOR_DST_ALPHA = 7
  BLEND_FACTOR_SRC_COLOR = 8
  BLEND_FACTOR_ONE_MINUS_SRC_COLOR = 9
  BLEND_FACTOR_CONSTANT_COLOR = 10
  BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR = 11
  BLEND_FACTOR_CONSTANT_ALPHA = 12
  BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA = 13
  BLEND_FACTOR_SRC_ALPHA_SATURATE = 14
  --]]
  gh_renderer.set_blending_factors(2, 5)

  libfont2_render_v2(font)  

  gh_renderer.set_blending_state(0)
end


function libfont2_render_v2(font)
  _libfont2_init()

  gh_renderer.set_depth_test_state(0)

  local win_w, win_h = gh_window.getsize(0)
  _libfont2_resize(win_w, win_h)

  gh_camera.bind(_libfont2_camera_ortho)
  gh_gpu_program.bind(_libfont2_gpu_program)

  gh_texture.bind(font.texture, 0)
  gh_font.update(font.fid, 0)
  gh_font.render(font.fid)

  gh_renderer.set_depth_test_state(1)
end





function libfont2_render_prepare()
  _libfont2_init()

  gh_renderer.set_depth_test_state(0)

  local win_w, win_h = gh_window.getsize(0)
  _libfont2_resize(win_w, win_h)

  gh_camera.bind(_libfont2_camera_ortho)
  gh_gpu_program.bind(_libfont2_gpu_program)
end


function libfont2_render_finish()
  gh_renderer.set_depth_test_state(1)
end

function libfont2_render_draw(font)
  gh_texture.bind(font.texture, 0)
  gh_font.update(font.fid, 0)
  gh_font.render(font.fid)
end





function libfont2_render_all()

  gh_renderer.set_blending_state(1)
  gh_renderer.set_blending_factors(2, 5)
  libfont2_render_all_v2()  
  gh_renderer.set_blending_state(0)
end


function libfont2_render_all_v2()
  _libfont2_init()


  gh_renderer.back_face_culling(0)
  gh_renderer.set_depth_test_state(0)

  local win_w, win_h = gh_window.getsize(0)
  _libfont2_resize(win_w, win_h)

  gh_camera.bind(_libfont2_camera_ortho)
  gh_gpu_program.bind(_libfont2_gpu_program)

  for i=1, _libfont2_num_fonts do
    local font = _libfont2_fonts[i]
    gh_texture.bind(font.texture, 0)
    gh_font.update(font.fid, 0)
    gh_font.render(font.fid)
  end

  gh_renderer.set_depth_test_state(1)
end
