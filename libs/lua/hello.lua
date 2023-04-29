--[[
------------------------------------------------------------------------------
Hello is a very simple graphics API for GeeXLab written in Lua.

Version history:

2018.09.10
- added draw_3d_with_lighthing()
- updated draw_3d(): no texturing and no lighting
- added print_xy() and print_xy_rgb()

2018.05.31
- initial draft

------------------------------------------------------------------------------
--]]


------------------------------------------------------------------------------
------------------------------------------------------------------------------

hello_gpu_program = {
  num_items = 0,
  vertex_color = 0,
  phong_texture = 0,
  current_prog = 0,
  prev_prog = 0,
}






function hello_gpu_program.create(gpu_prog_name, vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
  local vs = ""
  local ps = ""
  if (gh_renderer.is_opengl_es() == 1) then
    vs = vs_gles2
    ps = ps_gles2
  else
    if (gh_renderer.get_api_version_major() > 3) then
      vs = "#version 150\n" .. vs_gl3
      ps = "#version 150\n" .. ps_gl3
    elseif (gh_renderer.get_api_version_major() == 3) then
      if (gh_renderer.get_api_version_minor() < 2) then
        vs = "#version 130\n" .. vs_gl3
        ps = "#version 130\n" .. ps_gl3
      else
        vs = "#version 150\n" .. vs_gl3
        ps = "#version 150\n" .. ps_gl3
      end
    elseif (gh_renderer.get_api_version_major() < 3) then
      vs = vs_gl2
      ps = ps_gl2
    end
  end
  local p = gh_gpu_program.create_v2(gpu_prog_name, vs, ps)
  if (p > 0) then
    hello_gpu_program.num_items = hello_gpu_program.num_items + 1
  end
  return p
end  

function hello_gpu_program.load(name, vs, ps)
  local p = gh_gpu_program.create_v2(name, vs, ps)
  if (p > 0) then
    hello_gpu_program.num_items = hello_gpu_program.num_items + 1
  end
  return p
end


function hello_gpu_program.save()
  hello_gpu_program.prev_prog = hello_gpu_program.current_prog
end

function hello_gpu_program.restore()
  hello_gpu_program.current_prog = hello_gpu_program.prev_prog
  gh_gpu_program.bind(hello_gpu_program.current_prog)
end



function hello_gpu_program.bind(p)
  if (p ~= hello_gpu_program.current_prog) then
    hello_gpu_program.current_prog = p
    gh_gpu_program.bind(p)
  end  
end

function hello_gpu_program.uniform1i(uname, x)
  gh_gpu_program.uniform1i(hello_gpu_program.current_prog, uname, x)
end

function hello_gpu_program.uniform4f(uname, x, y, z, w)
  gh_gpu_program.uniform4f(hello_gpu_program.current_prog, uname, x, y, z, w)
end


function hello_gpu_program.init_vertex_color_prog()

	if (hello_gpu_program.vertex_color > 0) then
		return
	end

  local vs_gl3= [[
  in vec4 gxl3d_Position; 
  in vec4 gxl3d_Color; 
  uniform mat4 gxl3d_ModelViewProjectionMatrix; 
  out vec4 v_color; 
  void main() 
  { 
    gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position; 
    v_color = gxl3d_Color; 
  } 
  ]]
  
  local ps_gl3= [[
  uniform vec4 color; 
  in vec4 v_color; 
  out vec4 Out_Color; 
  void main() 
  { 
    Out_Color = color * v_color; 
  }
  ]]

  local vs_gl2= [[
  #version 120 
  uniform mat4 gxl3d_ModelViewProjectionMatrix;
  varying vec4 v_color; 
  void main()
  {
    gl_Position = gxl3d_ModelViewProjectionMatrix * gl_Vertex;
    v_color = gl_Color; 
  }
  ]]
  
  
  local ps_gl2= [[
  #version 120 
  uniform vec4 color; 
  varying vec4 v_color; 
  void main() 
  { 
    gl_FragColor = color * v_color; 
  }
  ]]
  
  
  local vs_gles2 = [[
  precision highp float;
  attribute vec4 gxl3d_Position; 
  attribute vec4 gxl3d_Color; 
  uniform mat4 gxl3d_ModelViewProjectionMatrix;
  varying vec4 v_color;
  void main()
  {
    gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;
    v_color = gl_Color;
  }
  ]]
  
  local ps_gles2 = [[
  precision highp float;
  uniform vec4 color; 
  varying vec4 v_color; 
  void main() 
  { 
    gl_FragColor = color * v_color; 
  }
  ]]
  

	local p = hello_gpu_program.create("sgh_vertex_color_gpu_program", vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
  hello_gpu_program.vertex_color = p
	gh_gpu_program.uniform4f(p, "color", 1, 1, 1, 1)
end



------------------------------------------------------------------------------
function hello_gpu_program.init_phong_texture_prog()

	if (hello_gpu_program.phong_texture > 0) then
		return
	end

  local vs_gl3=[[ 
	in vec4 gxl3d_Position;
	in vec4 gxl3d_Normal; 
	in vec4 gxl3d_TexCoord0;
	in vec4 gxl3d_Color;
	out vec4 v_uv;
	out vec4 v_normal;
	out vec4 v_lightdir;
	out vec4 v_eyevec;
  out vec4 v_color;
	uniform mat4 gxl3d_ModelViewProjectionMatrix; // Automatically passed by GeeXLab
	uniform mat4 gxl3d_ModelViewMatrix; // Automatically passed by GeeXLab
	uniform mat4 gxl3d_ViewMatrix; // Automatically passed by GeeXLab
	uniform vec4 light_position;
	uniform vec4 uv_tiling;
	void main()
	{ 
	  vec4 P = gxl3d_Position;
	  P.w = 1.0;
	  gl_Position = gxl3d_ModelViewProjectionMatrix * P;
	  v_uv = gxl3d_TexCoord0 * uv_tiling;
	  v_normal = gxl3d_ModelViewMatrix  * gxl3d_Normal;
	  vec4 view_vertex = gxl3d_ModelViewMatrix * P;
	  vec4 lp = gxl3d_ViewMatrix * light_position; 
	  v_lightdir = lp - view_vertex;
	  v_eyevec = -view_vertex;
    v_color = gxl3d_Color;
	}
  ]]
	
	local ps_gl3= [[
	uniform sampler2D tex0;
  uniform vec4 light_ambient;
	uniform vec4 light_diffuse; 
	uniform vec4 material_diffuse;
	uniform vec4 light_specular;
	uniform vec4 material_specular;
	uniform float material_shininess;
	uniform int do_texturing;
	uniform int do_lighting;
  uniform vec4 color; 
	in vec4 v_uv;
	in vec4 v_normal;
	in vec4 v_lightdir;
	in vec4 v_eyevec;
  in vec4 v_color;
	out vec4 FragColor;
	void main()
	{
    vec4 tex01_color = vec4(1.0);
    if (do_texturing == 1)
    {
      vec2 uv = v_uv.xy;
      uv.y *= -1.0;
      tex01_color = texture(tex0, uv).rgba;
    }

	  vec4 final_color = tex01_color; 
    
    if (do_lighting == 1)
    {
      final_color *= light_ambient;
      vec4 N = normalize(v_normal);
      vec4 L = normalize(v_lightdir);
      float lambertTerm = dot(N,L);
      if (lambertTerm > 0.0)
      { 
        final_color += light_diffuse * material_diffuse * lambertTerm * tex01_color;
        vec4 E = normalize(v_eyevec);
        vec4 R = reflect(-L, N);
        float specular = pow( max(dot(R, E), 0.0), material_shininess); 
        final_color += light_specular * material_specular * specular;	
      } 
    }
	  FragColor.rgb = final_color.rgb * v_color.rgb * color.rgb;
	  FragColor.a = v_color.a * color.a;
	}
  ]]

	local vs_gl2=[[ 
	#version 120 
	varying vec4 v_uv; 
	varying vec4 v_normal; 
	varying vec4 v_lightdir; 
	varying vec4 v_eyevec; 
  varying vec4 v_color;
	uniform mat4 gxl3d_ModelViewProjectionMatrix; // Automatically passed by GeeXLab 
	uniform mat4 gxl3d_ModelViewMatrix; // Automatically passed by GeeXLab 
	uniform mat4 gxl3d_ViewMatrix; // Automatically passed by GeeXLab 
	uniform vec4 light_position; 
	uniform vec4 uv_tiling; 
	void main() 
	{ 
	  vec4 P = gl_Vertex; 
	  P.w = 1.0; 
	  gl_Position = gxl3d_ModelViewProjectionMatrix * P; 
	  v_uv = gl_MultiTexCoord0 * uv_tiling; 
	  v_normal = gxl3d_ModelViewMatrix  * vec4(gl_Normal, 0.0); 
	  vec4 view_vertex = gxl3d_ModelViewMatrix * P; 
	  vec4 lp = gxl3d_ViewMatrix * light_position; 
	  v_lightdir = lp - view_vertex; 
	  v_eyevec = -view_vertex; 
    v_color = gl_Color;
	}
  ]]

	local ps_gl2=[[
	#version 120 
	uniform sampler2D tex0; 
  uniform vec4 light_ambient;
	uniform vec4 light_diffuse; 
	uniform vec4 material_diffuse; 
	uniform vec4 light_specular; 
	uniform vec4 material_specular; 
	uniform float material_shininess; 
	uniform int do_texturing;
	uniform int do_lighting;
  uniform vec4 color; 
  varying vec4 v_uv; 
	varying vec4 v_normal; 
	varying vec4 v_lightdir; 
	varying vec4 v_eyevec; 
  varying vec4 v_color;
	void main() 
	{ 
    vec4 tex01_color = vec4(1.0);
    if (do_texturing == 1)
    {
      vec2 uv = v_uv.xy;
      uv.y *= -1.0;
      tex01_color = texture2D(tex0, uv).rgba;
    }

	  vec4 final_color = tex01_color; 
    
    if (do_lighting == 1)
    {
      final_color *= light_ambient;
      vec4 N = normalize(v_normal); 
      vec4 L = normalize(v_lightdir); 
      float lambertTerm = dot(N,L); 
      if (lambertTerm > 0.0) 
      { 
        final_color += light_diffuse * material_diffuse * lambertTerm * tex01_color;
        vec4 E = normalize(v_eyevec); 
        vec4 R = reflect(-L, N); 
        float specular = pow( max(dot(R, E), 0.0), material_shininess); 
        final_color += light_specular * material_specular * specular;	 
      } 
    }
	  gl_FragColor.rgb = final_color.rgb * v_color.rgb * color.rgb; 
	  gl_FragColor.a = v_color.a * color.a; 
	}
  ]]
  
  
  local vs_gles2=[[ 
  precision highp float;
	attribute vec4 gxl3d_Position;
	attribute vec4 gxl3d_Normal; 
	attribute vec4 gxl3d_TexCoord0;
	attribute vec4 gxl3d_Color; 
	varying vec4 v_uv; 
	varying vec4 v_normal; 
	varying vec4 v_lightdir; 
	varying vec4 v_eyevec; 
  varying vec4 v_color;
	uniform mat4 gxl3d_ModelViewProjectionMatrix; // Automatically passed by GeeXLab
	uniform mat4 gxl3d_ModelViewMatrix; // Automatically passed by GeeXLab
	uniform mat4 gxl3d_ViewMatrix; // Automatically passed by GeeXLab
	uniform vec4 light_position;
	uniform vec4 uv_tiling;
	void main()
	{ 
	  vec4 P = gxl3d_Position;
	  P.w = 1.0;
	  gl_Position = gxl3d_ModelViewProjectionMatrix * P;
	  v_uv = gxl3d_TexCoord0 * uv_tiling;
	  v_normal = gxl3d_ModelViewMatrix  * gxl3d_Normal;
	  vec4 view_vertex = gxl3d_ModelViewMatrix * P;
	  vec4 lp = gxl3d_ViewMatrix * light_position; 
	  v_lightdir = lp - view_vertex;
	  v_eyevec = -view_vertex;
    v_color = gxl3d_Color;
	}
  ]]
	
	local ps_gles2= [[
  precision highp float;
	uniform sampler2D tex0;
  uniform vec4 light_ambient;
	uniform vec4 light_diffuse; 
	uniform vec4 material_diffuse;
	uniform vec4 light_specular;
	uniform vec4 material_specular;
	uniform float material_shininess;
	uniform int do_texturing;
	uniform int do_lighting;
  uniform vec4 color; 
	varying vec4 v_uv; 
	varying vec4 v_normal; 
	varying vec4 v_lightdir; 
	varying vec4 v_eyevec; 
  varying vec4 v_color;
	void main()
	{
    vec4 tex01_color = vec4(1.0);
    if (do_texturing == 1)
    {
      vec2 uv = v_uv.xy;
      uv.y *= -1.0;
      tex01_color = texture2D(tex0, uv).rgba;
    }

	  vec4 final_color = tex01_color; 
    
    if (do_lighting == 1)
    {
      final_color *= light_ambient;
      vec4 N = normalize(v_normal);
      vec4 L = normalize(v_lightdir);
      float lambertTerm = dot(N,L);
      if (lambertTerm > 0.0)
      { 
        final_color += light_diffuse * material_diffuse * lambertTerm * tex01_color;
        vec4 E = normalize(v_eyevec);
        vec4 R = reflect(-L, N);
        float specular = pow( max(dot(R, E), 0.0), material_shininess); 
        final_color += light_specular * material_specular * specular;	
      } 
    }
	  gl_FragColor.rgb = final_color.rgb * v_color.rgb * color.rgb;
	  gl_FragColor.a = v_color.a * color.a;
	}
  ]]
  

	local p = hello_gpu_program.create("sgh_phong_texture_gpu_program", vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
	hello_gpu_program.phong_texture = p

	gh_gpu_program.uniform4f(p, "light_position", 0.0, 100, 50, 1.0)
	gh_gpu_program.uniform4f(p, "uv_tiling", 1.0, 1.0, 0.0, 1.0)
	gh_gpu_program.uniform1i(p, "tex0", 0)
	gh_gpu_program.uniform1i(p, "do_texturing", 1)
	gh_gpu_program.uniform1i(p, "do_lighting", 1)
	gh_gpu_program.uniform4f(p, "light_ambient", 0.4, 0.4, 0.4, 1.0)
	gh_gpu_program.uniform4f(p, "light_diffuse", 1.0, 1.0, 0.9, 1.0)
	gh_gpu_program.uniform4f(p, "light_specular", 0.8, 0.8, 0.9, 1.0)
	gh_gpu_program.uniform4f(p, "material_diffuse", 0.9, 0.9, 0.9, 1.0)
	gh_gpu_program.uniform4f(p, "material_specular", 0.1, 0.1, 0.1, 1.0)
	gh_gpu_program.uniform1f(p, "material_shininess", 10.0)
	gh_gpu_program.uniform4f(p, "color", 1.0, 1.0, 1.0, 1.0)

end







------------------------------------------------------------------------------
------------------------------------------------------------------------------

hello_camera = {
  num_items = 0,
  camera_3d_gx = 0,
  camera_2d = 0,
  curr_camera = 0,

}

function hello_camera.create_3d(fov)
  local win_w, win_h = gh_window.getsize(0)
  local znear = 0.1
  local zfar = 1000.0
  local c = gh_camera.create_persp(fov, win_w / win_h, znear, zfar)
  gh_camera.set_viewport(c, 0, 0, win_w, win_h)
  gh_camera.set_position(c, 0, 10, 50)
  gh_camera.set_lookat(c, 0, 0, 0, 1)
  gh_camera.setupvec(c, 0, 1, 0, 0)
  
  hello_camera.num_items = hello_camera.num_items + 1
  
  return c
end

function hello_camera.resize_3d(cam)
  local win_w, win_h = gh_window.getsize(0)
  local znear = 0.1
  local zfar = 1000.0
  local fov = gh_camera.get_fov(cam)
  gh_camera.update_persp(cam, fov, win_w / win_h, znear, zfar)
  gh_camera.set_viewport(cam, 0, 0, win_w, win_h)
end

function hello_camera.create_3d_gx(fov)
  local win_w, win_h = gh_window.getsize(0)
  local znear = 0.1
  local zfar = 1000.0
  local is_vertical_fov = 1
  local cam = gx_camera.create_perspective(fov, is_vertical_fov, 0, 0, win_w, win_h, znear, zfar)
  gh_camera.set_position(cam, 0, 0, 50)
  gx_camera.init_orientation(cam, 0, 0, 0, 30, 90)
  gx_camera.set_mode_orbit()
  gx_camera.set_keyboard_speed(10.0)

  hello_camera.num_items = hello_camera.num_items + 1

  return cam
end


function hello_camera.get3d()
  return hello_camera.camera_3d_gx
end  

function hello_camera.get2d()
  return hello_camera.camera_2d
end  


function hello_camera.set_position(cam, x, y, z)
  gh_camera.set_position(cam, x, y, z)
end  

function hello_camera.init_orientation(cam, ang_x_axis, ang_y_axis)
  gx_camera.init_orientation(cam, 0, 0, 0, ang_x_axis, ang_y_axis)
end  

function hello_camera.set_keyboard_speed(speed)
  gx_camera.set_keyboard_speed(speed)
end  

function hello_camera.set_mode(mode)
  if (mode == "orbit") then
    gx_camera.set_mode_orbit()
  elseif (mode == "fly") then
    gx_camera.set_mode_fly()
  end
end  




function hello_camera.resize_3d_gx(cam) 
  local win_w, win_h = gh_window.getsize(0)
  local znear = 0.1
  local zfar = 1000.0
  local fov = gh_camera.get_fov(cam)
  local is_vertical_fov = 1
  gx_camera.update_perspective(cam, fov, is_vertical_fov, 0, 0, win_w, win_h, znear, zfar)
  --print("sgh_resize_3d_camera_gx OK - w:" .. win_w .. " h:" .. win_h)
end

function hello_camera.update_3d_gx(cam, dt) 
  gx_camera.update(cam, dt)
end

function hello_camera.bind(cam) 
  if (cam ~= curr_camera) then
    curr_camera = cam
    gh_camera.bind(cam)
  end
end

function hello_camera.create_2d()
  local win_w, win_h = gh_window.getsize(0)
  local c = gh_camera.create_ortho(-win_w/2, win_w/2, -win_h/2, win_h/2, 1.0, 10.0)
  gh_camera.set_viewport(c, 0, 0, win_w, win_h)
  gh_camera.set_position(c, 0, 0, 4)
  hello_camera.num_items = hello_camera.num_items + 1
  return c
end


function hello_camera.resize_2d(cam)
  local win_w, win_h = gh_window.getsize(0)
  gh_camera.update_ortho(cam, -win_w/2, win_w/2, -win_h/2, win_h/2, 1.0, 10.0)
  gh_camera.set_viewport(cam, 0, 0, win_w, win_h)
end









------------------------------------------------------------------------------
------------------------------------------------------------------------------

hello_image = {
  num_items = 0,
  curr_texture = {}
}

function hello_image.texture_load(filename, pixel_format, gen_mipmaps)
  local PF_U8_RGB = 1
  local PF_U8_BGR = 2
  local PF_U8_RGBA = 3
  local PF_U8_BGRA = 4
  local PF_F32_RGB = 5
  local PF_F32_RGBA = 6
  local PF_F32_R = 7
  local PF_F16_RGB = 8
  local PF_F16_RGBA = 9
  local PF_F16_R = 10
  local PF_U8_R = 11

  local pf = PF_U8_RGBA
  if (pixel_format == "rgb_u8") then
    pf = PF_U8_RGB 
  elseif (pixel_format == "bgr_u8") then
    pf = PF_U8_BGR
  elseif (pixel_format == "rgba_u8") then
    pf = PF_U8_RGBA
  elseif (pixel_format == "bgra_u8") then
    pf = PF_U8_BGRA
  elseif (pixel_format == "r_u8") then
    pf = PF_U8_R
  elseif (pixel_format == "rgb_f32") then
    pf = PF_F32_RGB
  elseif (pixel_format == "rgba_f32") then
    pf = PF_F32_RGBA
  elseif (pixel_format == "r_f32") then
    pf = PF_F32_R
  end
  local compressed_format = ""
  local t = gh_texture.create_from_file_v6(filename, pf, gen_mipmaps, compressed_format)
  
  if (gen_mipmaps == 1) then
    local SAMPLER_FILTERING_NEAREST = 1
    local SAMPLER_FILTERING_LINEAR = 2
    local SAMPLER_FILTERING_TRILINEAR = 3
    local SAMPLER_ADDRESSING_WRAP = 1
    local SAMPLER_ADDRESSING_CLAMP_TO_EDGE = 2
    local SAMPLER_ADDRESSING_MIRROR = 3
    gh_texture.bind(t, 0)
    gh_texture.set_sampler_params(t, SAMPLER_FILTERING_TRILINEAR, SAMPLER_ADDRESSING_WRAP, 16.0)
    gh_texture.bind(t, 0)
  end
  
  
  if (t > 0) then
    hello_image.num_items = hello_image.num_items + 1
  end
  
  return t
end  


function hello_image.load(filename)
  local t = hello_image.texture_load(filename, "rgb_u8", 1)
  return t
end

function hello_image.bind(t, tu)
  if (t ~= curr_texture[tu+1]) then
    curr_texture[tu+1] = t
    gh_texture.bind(t, tu)
  end  
end


 ------------------------------------------------------------------------------
------------------------------------------------------------------------------

hello_object = {
  num_items = 0,
  refgrid = 0,
  cur_color={r=1.0, g=1.0, b=1.0, a=1.0}
}

function hello_object.quad(w, h)
  local obj = gh_mesh.create_quad(w, h)
  if (obj > 0) then
    hello_object.num_items = hello_object.num_items + 1
  end
  return obj
end  


function hello_object.set_vertices_color(obj, r, g, b, a)
  gh_object.set_vertices_color(obj, r, g, b, a)
end

function hello_object.color(r, g, b, a)
  hello_object.cur_color.r = r
  hello_object.cur_color.g = g
  hello_object.cur_color.b = b
  hello_object.cur_color.a = a
end


function hello_object.box(w, h, d)
  local obj = gh_mesh.create_box(w, h, d, 1, 1, 1)
  if (obj > 0) then
    hello_object.num_items = hello_object.num_items + 1
  end
  return obj
end  


function hello_object.torus(outer_radius, section_radius)
  local obj = gh_mesh.create_torus(outer_radius, section_radius, 40)
  if (obj > 0) then
    hello_object.num_items = hello_object.num_items + 1
  end
  return obj
end  

function hello_object.sphere(radius)
  local obj = gh_mesh.create_sphere(radius, 40, 40)
  if (obj > 0) then
    hello_object.num_items = hello_object.num_items + 1
  end
  return obj
end  

function hello_object.plane(width, height)
  local obj = gh_mesh.create_plane(width, height, 10, 10)
  if (obj > 0) then
    hello_object.num_items = hello_object.num_items + 1
  end
  return obj
end

function hello_object.set_position(obj, x, y, z)
  gh_object.set_position(obj, x, y, z)
end

function hello_object.set_rotation(obj, x, y, z)
  gh_object.set_euler_angles(obj, x, y, z)
end


function hello_object.draw_3d(obj)
  hello.camera.bind(hello.camera.camera_3d_gx) 
  local c = hello_object.cur_color
  hello.glsl.uniform4f("color", c.r, c.g, c.b, c.a)
	hello.glsl.uniform1i("do_lighting", 0)
  hello.glsl.uniform1i("do_texturing", 0)
  gh_object.render(obj)
end

function hello_object.draw_3d_with_lighthing(obj)
  hello.camera.bind(hello.camera.camera_3d_gx) 
  local c = hello_object.cur_color
  hello.glsl.uniform4f("color", c.r, c.g, c.b, c.a)
	hello.glsl.uniform1i("do_lighting", 1)
  hello.glsl.uniform1i("do_texturing", 0)
  gh_object.render(obj)
end

function hello_object.draw_3d_with_texture(obj, texture, u, v)
  hello.camera.bind(hello.camera.camera_3d_gx) 
  local c = hello_object.cur_color
  hello.glsl.uniform4f("color", c.r, c.g, c.b, c.a)
	hello.glsl.uniform1i("do_lighting", 1)
  if (texture > 0) then
    gh_texture.bind(texture, 0)
    hello.glsl.uniform1i("do_texturing", 1)
    --gh_gpu_program.uniform1i(hello.glsl.phong_texture, "do_texturing", 1)
    hello.glsl.uniform4f("uv_tiling", u, v, 0, 1)
    --gh_gpu_program.uniform4f(hello.glsl.phong_texture, "uv_tiling", u, v, 0, 1)
  else
    hello.glsl.uniform1i("do_texturing", 0)
    --gh_gpu_program.uniform1i(hello.glsl.phong_texture, "do_texturing", 0)
  end
  gh_object.render(obj)
end

function hello_object.render(obj)
  gh_object.render(obj)
end



function hello_object.draw_2d_with_texture(obj, texture, u, v)
  hello.camera.bind(hello.camera.camera_2d) 
  local c = hello_object.cur_color
  hello.glsl.uniform4f("color", c.r, c.g, c.b, c.a)
	hello.glsl.uniform1i("do_lighting", 0)
  if (texture > 0) then
    gh_texture.bind(texture, 0)
    hello.glsl.uniform1i("do_texturing", 1)
    hello.glsl.uniform4f("uv_tiling", u, v, 0, 1)
  else
    hello.glsl.uniform1i("do_texturing", 0)
  end
  gh_object.render(obj)
end

function hello_object.draw_2d(obj)
  hello.camera.bind(hello.camera.camera_2d) 
  local c = hello_object.cur_color
  hello.glsl.uniform4f("color", c.r, c.g, c.b, c.a)
	hello.glsl.uniform1i("do_lighting", 0)
  hello.glsl.uniform1i("do_texturing", 0)
  gh_object.render(obj)
end



function hello_object.init_reference_grid(size_x, size_z)

	local grid = gh_utils.grid_create()
	gh_utils.grid_set_geometry_params(grid, size_x, size_z, 30, 30)
	gh_utils.grid_set_lines_color(grid, 0.7, 0.7, 0.7, 1.0)
	gh_utils.grid_set_main_lines_color(grid, 1.0, 1.0, 0.0, 1.0)
	gh_utils.grid_set_main_x_axis_color(grid, 1.0, 0.0, 0.0, 1.0)
	gh_utils.grid_set_main_z_axis_color(grid, 0.0, 0.0, 1.0, 1.0)
	local display_main_lines = 1
	local display_lines = 1
	gh_utils.grid_set_display_lines_options(grid, display_main_lines, display_lines)

	hello_object.refgrid = grid

end





------------------------------------------------------------------------------
------------------------------------------------------------------------------

hello_light = {
  num_items = 0,
  lights = { }
}

function hello_light.create()
  local light = { x=0, y=50, z=20, r=1.0, g=1.0, b=1.0 }
  return light
end  

function hello_light.set_position(light_index, x, y, z)
  local n = #hello_light.lights
  if (light_index <= n) then
    local light = hello_light.lights[light_index]
    light.x = x
    light.y = y
    light.z = z
  end
end

function hello_light.set_color(light_index, r, g, b)
  local n = #hello_light.lights
  if (light_index <= n) then
    local light = hello_light.lights[light_index]
    light.r = r
    light.g = g
    light.b = b
  end
end


------------------------------------------------------------------------------
------------------------------------------------------------------------------

hello_window = { }

function hello_window.size()
  local win_w, win_h = gh_window.getsize(0)
  return win_w, win_h
end



------------------------------------------------------------------------------
------------------------------------------------------------------------------

hello_blending = { 
  s = 1,
  d = 1
}

function hello_blending.enable(state)
  gh_renderer.set_blending_state(state)
end

function hello_blending.factors(s, d)
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
  --]]
  hello_blending.s = s
  hello_blending.d = d
  gh_renderer.set_blending_factors(s, d)
end



------------------------------------------------------------------------------
------------------------------------------------------------------------------

hello_renderer = { 
}

function hello_renderer.api()
  return gh_renderer.get_api_version()
end

function hello_renderer.model()
  return gh_renderer.get_renderer_model()
end


------------------------------------------------------------------------------
------------------------------------------------------------------------------


hello_graphics = { 
  blending = hello_blending,
  gpu = hello_renderer,
}


function hello_graphics.vsync(state)
  gh_renderer.set_vsync(state)
end

function hello_graphics.depthtest(state)
  gh_renderer.set_depth_test_state(state)
end



------------------------------------------------------------------------------
------------------------------------------------------------------------------

hello = {
  name = "Hello",
  version_major = 0,
  version_minor = 1,
  version_patch = 0,
  is_opengl_es = 0,
  tex_y_offset = 0,
  elapsed_time = 0,
  last_time = 0,
  time_step = 0,
  time_step_sum = 0,
  time_step_avg = 0,
  fps = 0,
  frames = 0,
  last_fps_time = 0.0,
  can_update_3d_cam_gx = 1,
  
  camera = hello_camera,
  image = hello_image,
  object = hello_object,
  light = hello_light,
  glsl = hello_gpu_program,
  window = hello_window,
  graphics = hello_graphics,
}

function hello.get_version()
  return hello.version_major, hello.version_minor, hello.version_patch
end

function hello.get_name()
  return hello.name
end

function hello.init()
  local lib_dir = gh_utils.get_scripting_libs_dir()     
  dofile(lib_dir .. "lua/libfont/libfont1.lua")   
  dofile(lib_dir .. "lua/gx_cam_lib_v1.lua")

  hello.glsl.init_vertex_color_prog()
  hello.glsl.init_phong_texture_prog()
  
  hello.camera.camera_3d_gx = hello.camera.create_3d_gx(60.0)
  hello_camera.camera_2d = hello_camera.create_2d()

  
  hello.light.lights[1] = hello.light.create()

  hello.is_opengl_es = gh_renderer.is_opengl_es()
  
  hello_object.init_reference_grid(50, 50)
end


function hello.terminate()

  
end


function hello.resize()

  hello.camera.resize_3d_gx(hello.camera.camera_3d_gx) 
  hello_camera.resize_2d(hello_camera.camera_2d)
  
end

function hello.begin_frame(r, g, b)

	local elapsed_time = gh_utils.get_elapsed_time()
	local dt = elapsed_time - hello.last_time
  hello.time_step = dt
  hello.time_step_sum = hello.time_step_sum + dt
  hello.elapsed_time = hello.elapsed_time + dt
	hello.last_time = elapsed_time
  
  hello.frames = hello.frames + 1
  
  if ((elapsed_time - hello.last_fps_time) >= 1.0) then
    hello.last_fps_time = elapsed_time
    hello.fps = hello.frames
    hello.time_step_avg = hello.time_step_sum / hello.frames
    hello.time_step_sum = 0
    hello.frames = 0
  end

  if (hello.can_update_3d_cam_gx == 1) then
    hello.camera.update_3d_gx(hello.camera.camera_3d_gx, dt) 
  end
  
	gh_renderer.clear_color_depth_buffers(r, g, b, 1.0, 1.0)
	gh_renderer.set_depth_test_state(1)

	hello.glsl.bind(0)
	hello.glsl.bind(hello.glsl.phong_texture)
  
  hello.camera.bind(0)

  local light = hello.light.lights[1]
	hello.glsl.uniform4f("light_position", light.x, light.y, light.z, 1.0)
	hello.glsl.uniform4f("light_diffuse", light.r, light.g, light.b, 1.0)
	hello.glsl.uniform1i("do_lighting", 1)
  
  libfont_clear()
  hello.tex_y_offset = 20

end

function hello.end_frame()

  libfont_render()

end


function hello.draw_ref_grid()
  hello.object.draw_3d(hello_object.refgrid)
end




function hello.can_update_3d_camera(state)
  hello.can_update_3d_cam_gx = state
end



function hello.get_fps()
  return hello.fps
end

function hello.get_dt()
  return hello.time_step
end

function hello.time()
  return hello.elapsed_time
end


function hello.print_lib_info()
  libfont_print(10, hello.tex_y_offset, 1.0, 1.0, 0.0, 1.0, string.format("%s v%d.%d.%d", hello.name, hello.version_major, hello.version_minor, hello.version_patch))
  hello.tex_y_offset = hello.tex_y_offset + 25
end

function hello.print_fps()
  libfont_print(10, hello.tex_y_offset, 0.7, 0.7, 0.2, 1.0, string.format("%d FPS (%.2fms)", hello.fps, hello.time_step_avg * 1000.0))
  hello.tex_y_offset = hello.tex_y_offset + 25
end

function hello.print(text)
  if (text ~= "") then
    libfont_print(10, hello.tex_y_offset, 1.0, 1.0, 1.0, 1.0, text)
  end
  hello.tex_y_offset = hello.tex_y_offset + 25
end

function hello.print_rgb(text, r, g, b)
  if (text ~= "") then
    libfont_print(10, hello.tex_y_offset, r, g, b, 1.0, text)
  end
  hello.tex_y_offset = hello.tex_y_offset + 25
end

function hello.print_xy(text, x, y)
  libfont_print(x, y, 1.0, 1.0, 1.0, 1.0, text)
end

function hello.print_xy_rgb(text, x, y, r, g, b)
  libfont_print(x, y, r, g, b, 1.0, text)
end



function hello.enable_color_blending(s, d)
end

function hello.disable_color_blending()
  gh_renderer.set_blending_state(0)
end

