
--[[
-----------------------------------------------------------------------
Available GPU programs:

"color"
"vertex_color"
"texture"
"phong"
"phong_texture"
"font"

--]]

shaderlib = {
  _gpu_programs_list = {},
}


--------------------------------------------------------
function shaderlib.add(gpu_prog_name, p)
  shaderlib._gpu_programs_list[gpu_prog_name] = p
end

function shaderlib.bind_by_name(gpu_prog_name)
  local p = shaderlib._gpu_programs_list[gpu_prog_name]
  gh_gpu_program.bind(p)
  --gh_gpu_program.uniform4f(gfx._color_program, "color", r, g, b, a)
end

function shaderlib.bind(p)
  gh_gpu_program.bind(p)
end

function shaderlib.getid(gpu_prog_name)
  local p = shaderlib._gpu_programs_list[gpu_prog_name]
  return p
end


--------------------------------------------------------
function shaderlib.create_gpu_program(gpu_prog_name, vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
  local vs = ""
  local ps = ""
  local gs = ""
  local tcs = ""
  local tes = ""
  local cs = ""
  
  if (gh_renderer.is_opengl_es() == 1) then
    vs = vs_gles2
    ps = ps_gles2
  
  else
    local vmajor = gh_renderer.get_api_version_major()
    local vminor = gh_renderer.get_api_version_minor()
    local glver = vmajor*10 + vminor

    if (glver == 21) then
      vs = vs_gl2
      ps = ps_gl2
    elseif (glver <= 31) then
      vs = "#version 130\n" .. vs_gl3
      ps = "#version 130\n" .. ps_gl3
    elseif (glver >= 32) then
      vs = "#version 150\n" .. vs_gl3
      ps = "#version 150\n" .. ps_gl3
    end
  end

  local p = gh_gpu_program.create_v2(gpu_prog_name, vs, ps, gs, tcs, tes, cs)
  return p
end  

--------------------------------------------------------
function shaderlib.init_gpu_program_color()

  local vs_gl3=" \
in vec4 gxl3d_Position;\
uniform mat4 gxl3d_ModelViewProjectionMatrix; \
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
}"

  local ps_gl3=" \
uniform vec4 color;\
out vec4 FragColor;\
void main() \
{ \
  FragColor = color;  \
}"
  
  local vs_gl2=" \
void main() \
{ \
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;\
}"

  local ps_gl2=" \
uniform vec4 color;\
void main() \
{ \
  gl_FragColor = color;  \
}"

  local vs_gles2=" \
attribute vec4 gxl3d_Position;\
uniform mat4 gxl3d_ModelViewProjectionMatrix; \
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
}"

  local ps_gles2=" \
uniform highp vec4 color;\
void main() \
{ \
  gl_FragColor = color;  \
}"

  local p = shaderlib.create_gpu_program("shaderlib_color_program", vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
  gh_gpu_program.uniform4f(p, "color", 1.0, 1.0, 1.0, 1.0)
  shaderlib.add("color", p)
end  

--------------------------------------------------------------------
function shaderlib.init_gpu_program_vertex_color()

  local vs_gl3=" \
in vec4 gxl3d_Position;\
in vec4 gxl3d_Color;\
uniform mat4 gxl3d_ModelViewProjectionMatrix; \
out vec4 v_color;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  v_color = gxl3d_Color;\
}"

  local ps_gl3=" \
in vec4 v_color;\
out vec4 FragColor;\
uniform vec4 color;\
void main() \
{ \
  FragColor = v_color * color;  \
}"
  
  local vs_gl2=" \
varying vec4 v_color;\
void main() \
{ \
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;\
  v_color = gl_Color;\
}"

  local ps_gl2=" \
varying vec4 v_color;\
uniform vec4 color;\
void main() \
{ \
  gl_FragColor = v_color * color;  \
}"

  local vs_gles2=" \
attribute vec4 gxl3d_Position;\
attribute vec4 gxl3d_Color;\
uniform mat4 gxl3d_ModelViewProjectionMatrix; \
varying vec4 v_color;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  v_color = gxl3d_Color;\
}"

  local ps_gles2=" \
varying highp vec4 v_color;\
uniform highp vec4 color;\
void main() \
{ \
  gl_FragColor = v_color * color;  \
}"

  local p = shaderlib.create_gpu_program("shaderlib_vertex_color_program", vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
  gh_gpu_program.uniform4f(p, "color", 1.0, 1.0, 1.0, 1.0)

  --shaderlib._vertex_color_program = p
  shaderlib.add("vertex_color", p)
end  


--------------------------------------------------------
function shaderlib.init_gpu_program_texture()

  local vs_gl3=" \
in vec4 gxl3d_Position;\
in vec4 gxl3d_TexCoord0;\
uniform mat4 gxl3d_ModelViewProjectionMatrix; \
out vec4 Vertex_UV;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  Vertex_UV = gxl3d_TexCoord0;\
}"

  local ps_gl3=" \
uniform sampler2D tex0;\
uniform vec2 uv_tiling;\
in vec4 Vertex_UV;\
out vec4 FragColor;\
uniform vec4 color;\
uniform vec4 emissive;\
uniform int neg_uv_y;\
void main() \
{ \
  vec2 uv = Vertex_UV.xy * uv_tiling;\
  if (neg_uv_y == 1) uv.y *= -1.0;\
  vec4 t = texture(tex0,uv);\
  FragColor = t * color + emissive;  \
}"
  
  local vs_gl2=" \
varying vec4 Vertex_UV;\
void main() \
{ \
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;\
  Vertex_UV = gl_MultiTexCoord0;\
}"

  local ps_gl2=" \
uniform sampler2D tex0;\
uniform vec2 uv_tiling;\
uniform int neg_uv_y;\
varying vec4 Vertex_UV;\
uniform vec4 color;\
uniform vec4 emissive;\
void main() \
{ \
  vec2 uv = Vertex_UV.xy * uv_tiling;\
  if (neg_uv_y == 1) uv.y *= -1.0;\
  vec4 t = texture2D(tex0,uv);\
  gl_FragColor = t * color + emissive;  \
}"

  local vs_gles2=" \
attribute vec4 gxl3d_Position;\
attribute vec4 gxl3d_TexCoord0;\
uniform mat4 gxl3d_ModelViewProjectionMatrix; \
varying vec4 Vertex_UV;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  Vertex_UV = gxl3d_TexCoord0;\
}"

  local ps_gles2=" \
uniform sampler2D tex0;\
uniform highp vec2 uv_tiling;\
uniform highp vec4 color;\
uniform highp vec4 emissive;\
uniform int neg_uv_y;\
varying highp vec4 Vertex_UV;\
void main() \
{ \
  highp vec2 uv = Vertex_UV.xy * uv_tiling;\
  if (neg_uv_y == 1) uv.y *= -1.0;\
  highp vec4 t = texture2D(tex0,uv);\
  gl_FragColor = t * color + emissive;  \
}"

  local p = shaderlib.create_gpu_program("shaderlib_texture_program", vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
  gh_gpu_program.uniform1i(p, "tex0", 0)
  gh_gpu_program.uniform1i(p, "neg_uv_y", 1)
  gh_gpu_program.uniform2f(p, "uv_tiling", 1.0, 1.0)
  gh_gpu_program.uniform4f(p, "color", 1.0, 1.0, 1.0, 1.0)
  gh_gpu_program.uniform4f(p, "emissive", 0.0, 0.0, 0.0, 0.0)

  --shaderlib._texture_program = p
  shaderlib.add("texture", p)
end  


--------------------------------------------------------
function shaderlib.init_gpu_program_phong_texture()

  local vs_gl3=" \
in vec4 gxl3d_Position;\
in vec3 gxl3d_Normal; \
in vec4 gxl3d_TexCoord0;\
uniform mat4 gxl3d_ModelViewProjectionMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ModelViewMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ViewMatrix; // Automatically passed by GeeXLab \
uniform vec4 light_position; \
out vec4 v_uv;\
out vec4 v_normal;\
out vec4 v_lightdir;\
out vec4 v_eye;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  v_uv = gxl3d_TexCoord0;\
  v_normal = gxl3d_ModelViewMatrix  * vec4(gxl3d_Normal.xyz, 0.0);\
  vec4 view_vertex = gxl3d_ModelViewMatrix * gxl3d_Position;\
  vec4 LP = gxl3d_ViewMatrix * light_position;\
  v_lightdir = LP - view_vertex;\
  v_eye = -view_vertex;\
}"

  local ps_gl3=" \
uniform sampler2D tex0;\
uniform vec4 light_ambient;\
uniform vec4 light_diffuse;\
uniform vec4 material_diffuse;\
uniform vec4 light_specular;\
uniform vec4 material_specular;\
uniform float material_shininess;\
uniform vec2 uv_tiling;\
uniform int neg_uv_y;\
in vec4 v_uv;\
in vec4 v_normal;\
in vec4 v_lightdir;\
in vec4 v_eye;\
out vec4 FragColor;\
void main() \
{ \
  vec2 uv = v_uv.xy * uv_tiling;\
  if (neg_uv_y == 1) uv.y *= -1.0;\
  vec4 tex0_color = texture(tex0, uv);\
  vec4 final_color = light_ambient * tex0_color; \
  vec4 N = normalize(v_normal);\
  vec4 L = normalize(v_lightdir);\
  float lambertTerm = dot(N,L);\
  if (lambertTerm > 0.0)\
  {\
    final_color += light_diffuse * material_diffuse * lambertTerm * tex0_color;	\
    vec4 E = normalize(v_eye);\
    vec4 R = reflect(-L, N);\
    float specular = pow( max(dot(R, E), 0.0), material_shininess);\
    final_color += light_specular * material_specular * specular;	\
  }\
  FragColor = final_color;\
}"
  

  local vs_gl2=" \
uniform mat4 gxl3d_ModelViewProjectionMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ModelViewMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ViewMatrix; // Automatically passed by GeeXLab \
uniform vec4 light_position; \
varying vec4 v_uv;\
varying vec4 v_normal;\
varying vec4 v_lightdir;\
varying vec4 v_eye;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gl_Vertex;\
  v_uv = gl_MultiTexCoord0;\
  v_normal = gxl3d_ModelViewMatrix  * vec4(gl_Normal.xyz, 0.0);\
  vec4 view_vertex = gxl3d_ModelViewMatrix * gl_Vertex;\
  vec4 LP = gxl3d_ViewMatrix * light_position;\
  v_lightdir = LP - view_vertex;\
  v_eye = -view_vertex;\
}"

  local ps_gl2=" \
uniform sampler2D tex0;\
uniform vec4 light_ambient;\
uniform vec4 light_diffuse;\
uniform vec4 material_diffuse;\
uniform vec4 light_specular;\
uniform vec4 material_specular;\
uniform float material_shininess;\
uniform vec2 uv_tiling;\
uniform int neg_uv_y;\
varying vec4 v_uv;\
varying vec4 v_normal;\
varying vec4 v_lightdir;\
varying vec4 v_eye;\
void main() \
{ \
  vec2 uv = v_uv.xy * uv_tiling;\
  if (neg_uv_y == 1) uv.y *= -1.0;\
  vec4 tex0_color = texture2D(tex0, uv);\
  vec4 final_color = light_ambient * tex0_color; \
  vec4 N = normalize(v_normal);\
  vec4 L = normalize(v_lightdir);\
  float lambertTerm = dot(N,L);\
  if (lambertTerm > 0.0)\
  {\
    final_color += light_diffuse * material_diffuse * lambertTerm * tex0_color;	\
    vec4 E = normalize(v_eye);\
    vec4 R = reflect(-L, N);\
    float specular = pow( max(dot(R, E), 0.0), material_shininess);\
    final_color += light_specular * material_specular * specular;	\
  }\
  gl_FragColor = final_color;\
}"


  local vs_gles2=" \
attribute vec4 gxl3d_Position;\
attribute vec4 gxl3d_Normal; \
attribute vec4 gxl3d_TexCoord0;\
uniform mat4 gxl3d_ModelViewProjectionMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ModelViewMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ViewMatrix; // Automatically passed by GeeXLab \
uniform vec4 light_position; \
varying vec4 v_uv;\
varying vec4 v_normal;\
varying vec4 v_lightdir;\
varying vec4 v_eye;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  v_uv = gxl3d_TexCoord0;\
  v_normal = gxl3d_ModelViewMatrix  * vec4(gxl3d_Normal.xyz, 0.0);\
  vec4 view_vertex = gxl3d_ModelViewMatrix * gxl3d_Position;\
  vec4 LP = gxl3d_ViewMatrix * light_position;\
  v_lightdir = LP - view_vertex;\
  v_eye = -view_vertex;\
}"

  local ps_gles2=" \
uniform sampler2D tex0;\
uniform highp vec4 light_ambient;\
uniform highp vec4 light_diffuse;\
uniform highp vec4 material_diffuse;\
uniform highp vec4 light_specular;\
uniform highp vec4 material_specular;\
uniform highp float material_shininess;\
uniform highp vec2 uv_tiling;\
uniform int neg_uv_y;\
varying highp vec4 v_uv;\
varying highp vec4 v_normal;\
varying highp vec4 v_lightdir;\
varying highp vec4 v_eye;\
void main() \
{ \
  highp vec2 uv = v_uv.xy * uv_tiling;\
  if (neg_uv_y == 1) uv.y *= -1.0;\
  highp vec4 tex0_color = texture2D(tex0, uv);\
  highp vec4 final_color = light_ambient * tex0_color; \
  highp vec4 N = normalize(v_normal);\
  highp vec4 L = normalize(v_lightdir);\
  highp float lambertTerm = dot(N,L);\
  if (lambertTerm > 0.0)\
  {\
    final_color += light_diffuse * material_diffuse * lambertTerm * tex0_color;	\
    highp vec4 E = normalize(v_eye);\
    highp vec4 R = reflect(-L, N);\
    highp float specular = pow( max(dot(R, E), 0.0), material_shininess);\
    final_color += light_specular * material_specular * specular;	\
  }\
  gl_FragColor = final_color;\
}"

  local p = shaderlib.create_gpu_program("shaderlib_phong_texture_program", vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
  gh_gpu_program.uniform1i(p, "tex0", 0)
  gh_gpu_program.uniform1i(p, "neg_uv_y", 1)
  gh_gpu_program.uniform2f(p, "uv_tiling", 1.0, 1.0)
  gh_gpu_program.uniform4f(p, "light_position", 20.0, 50.0, 100.0, 1.0)
  gh_gpu_program.uniform4f(p, "light_ambient", 0.4, 0.4, 0.4, 1.0)
  gh_gpu_program.uniform4f(p, "light_diffuse", 0.9, 0.9, 0.8, 1.0)
  gh_gpu_program.uniform4f(p, "material_diffuse", 0.9, 0.9, 0.9, 1.0)
  gh_gpu_program.uniform4f(p, "light_specular", 0.6, 0.6, 0.6, 1.0)
  gh_gpu_program.uniform4f(p, "material_specular", 0.6, 0.6, 0.6, 1.0)
  gh_gpu_program.uniform1f(p, "material_shininess", 60.0)
  --shaderlib._phong_texture_program = p
  shaderlib.add("phong_texture", p)
  
end  

--------------------------------------------------------------------------------
function shaderlib.init_gpu_program_phong()

  local vs_gl3=" \
in vec4 gxl3d_Position;\
in vec4 gxl3d_Normal; \
uniform mat4 gxl3d_ModelViewProjectionMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ModelViewMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ViewMatrix; // Automatically passed by GeeXLab \
uniform vec4 light_position; \
out vec4 v_normal;\
out vec4 v_lightdir;\
out vec4 v_eye;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  v_normal = gxl3d_ModelViewMatrix  * vec4(gxl3d_Normal.xyz, 0.0);\
  vec4 view_vertex = gxl3d_ModelViewMatrix * gxl3d_Position;\
  vec4 LP = gxl3d_ViewMatrix * light_position;\
  v_lightdir = LP - view_vertex;\
  v_eye = -view_vertex;\
}"

  local ps_gl3=" \
uniform vec4 light_diffuse;\
uniform vec4 light_ambient;\
uniform vec4 material_diffuse;\
uniform vec4 light_specular;\
uniform vec4 material_specular;\
uniform float material_shininess;\
in vec4 v_normal;\
in vec4 v_lightdir;\
in vec4 v_eye;\
out vec4 FragColor;\
void main() \
{ \
  vec4 final_color = light_ambient; \
  vec4 N = normalize(v_normal);\
  vec4 L = normalize(v_lightdir);\
  float lambertTerm = dot(N,L);\
  if (lambertTerm > 0.0)\
  {\
    final_color += light_diffuse * material_diffuse * lambertTerm;	\
    vec4 E = normalize(v_eye);\
    vec4 R = reflect(-L, N);\
    float specular = pow( max(dot(R, E), 0.0), material_shininess);\
    final_color += light_specular * material_specular * specular;	\
  }\
  FragColor = final_color;\
  //FragColor = vec4(vec3(L), 1.0);\
}"
  

  local vs_gl2=" \
uniform mat4 gxl3d_ModelViewProjectionMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ModelViewMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ViewMatrix; // Automatically passed by GeeXLab \
uniform vec4 light_position; \
varying vec4 v_normal;\
varying vec4 v_lightdir;\
varying vec4 v_eye;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gl_Vertex;\
  v_normal = gxl3d_ModelViewMatrix  * vec4(gl_Normal.xyz, 0.0);\
  vec4 view_vertex = gxl3d_ModelViewMatrix * gl_Vertex;\
  vec4 LP = gxl3d_ViewMatrix * light_position;\
  v_lightdir = LP - view_vertex;\
  v_eye = -view_vertex;\
}"

  local ps_gl2=" \
uniform vec4 light_diffuse;\
uniform vec4 light_ambient;\
uniform vec4 material_diffuse;\
uniform vec4 light_specular;\
uniform vec4 material_specular;\
uniform float material_shininess;\
varying vec4 v_normal;\
varying vec4 v_lightdir;\
varying vec4 v_eye;\
void main() \
{ \
  vec4 final_color = light_ambient; \
  vec4 N = normalize(v_normal);\
  vec4 L = normalize(v_lightdir);\
  float lambertTerm = dot(N,L);\
  if (lambertTerm > 0.0)\
  {\
    final_color += light_diffuse * material_diffuse * lambertTerm;	\
    vec4 E = normalize(v_eye);\
    vec4 R = reflect(-L, N);\
    float specular = pow( max(dot(R, E), 0.0), material_shininess);\
    final_color += light_specular * material_specular * specular;	\
  }\
  gl_FragColor = final_color;\
}"


  local vs_gles2=" \
attribute vec4 gxl3d_Position;\
attribute vec4 gxl3d_Normal; \
attribute vec4 gxl3d_TexCoord0;\
uniform mat4 gxl3d_ModelViewProjectionMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ModelViewMatrix; // Automatically passed by GeeXLab \
uniform mat4 gxl3d_ViewMatrix; // Automatically passed by GeeXLab \
uniform vec4 light_position; \
varying vec4 v_normal;\
varying vec4 v_lightdir;\
varying vec4 v_eye;\
void main() \
{ \
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  v_normal = gxl3d_ModelViewMatrix  * vec4(gxl3d_Normal.xyz, 0.0);\
  vec4 view_vertex = gxl3d_ModelViewMatrix * gxl3d_Position;\
  vec4 LP = gxl3d_ViewMatrix * light_position;\
  v_lightdir = LP - view_vertex;\
  v_eye = -view_vertex;\
}"

  local ps_gles2=" \
uniform highp vec4 light_diffuse;\
uniform highp vec4 light_ambient;\
uniform highp vec4 material_diffuse;\
uniform highp vec4 light_specular;\
uniform highp vec4 material_specular;\
uniform highp float material_shininess;\
varying highp vec4 v_normal;\
varying highp vec4 v_lightdir;\
varying highp vec4 v_eye;\
void main() \
{ \
  highp vec4 final_color = light_ambient; \
  highp vec4 N = normalize(v_normal);\
  highp vec4 L = normalize(v_lightdir);\
  highp float lambertTerm = dot(N,L);\
  if (lambertTerm > 0.0)\
  {\
    final_color += light_diffuse * material_diffuse * lambertTerm;	\
    highp vec4 E = normalize(v_eye);\
    highp vec4 R = reflect(-L, N);\
    highp float specular = pow( max(dot(R, E), 0.0), material_shininess);\
    highp final_color += light_specular * material_specular * specular;	\
  }\
  gl_FragColor = final_color;\
}"

  local p = shaderlib.create_gpu_program("shaderlib_phong_program", vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
  gh_gpu_program.uniform4f(p, "light_position", 20.0, 50.0, 100.0, 1.0)
  gh_gpu_program.uniform4f(p, "light_diffuse", 0.9, 0.9, 0.8, 1.0)
  gh_gpu_program.uniform4f(p, "light_ambient", 0.4, 0.4, 0.4, 1.0)
  gh_gpu_program.uniform4f(p, "material_diffuse", 0.9, 0.9, 0.9, 1.0)
  gh_gpu_program.uniform4f(p, "light_specular", 0.6, 0.6, 0.6, 1.0)
  gh_gpu_program.uniform4f(p, "material_specular", 0.6, 0.6, 0.6, 1.0)
  gh_gpu_program.uniform1f(p, "material_shininess", 60.0)
  --shaderlib._phong_program = p
  shaderlib.add("phong", p)
  
end


--------------------------------------------------------
function shaderlib.init_gpu_program_font()

  local vs_gl3=[[
in vec4 gxl3d_Position;
in vec4 gxl3d_TexCoord0;
in vec4 gxl3d_Color;
uniform mat4 gxl3d_ViewProjectionMatrix;
uniform mat4 gxl3d_ModelMatrix;
uniform vec4 gxl3d_Viewport;
out vec4 Vertex_UV;
out vec4 Vertex_Color;
void main()
{
  vec4 P = gxl3d_Position;
  vec4 Pw = gxl3d_ModelMatrix * P;
  Pw.x = Pw.x - gxl3d_Viewport.z/2;
  Pw.y = Pw.y + gxl3d_Viewport.w/2;
  gl_Position = gxl3d_ViewProjectionMatrix * Pw;		
  Vertex_UV = gxl3d_TexCoord0;
  Vertex_Color = gxl3d_Color;
}
]]

  local ps_gl3=[[
uniform sampler2D tex0;
uniform vec4 color;
in vec4 Vertex_UV;
in vec4 Vertex_Color;
out vec4 FragColor;
void main (void)
{
  vec2 uv = Vertex_UV.xy;
  float t = texture(tex0,uv).r;
  FragColor = vec4(t * Vertex_Color.rgb * color.rgb, t); 
}
]]


  local vs_gl2=[[
#version 120
uniform mat4 gxl3d_ViewProjectionMatrix;
uniform mat4 gxl3d_ModelMatrix;
uniform vec4 gxl3d_Viewport;
varying vec4 Vertex_UV;
varying vec4 Vertex_Color;
void main()
{
  vec4 P = gl_Vertex;
  vec4 Pw = gxl3d_ModelMatrix * P;
  Pw.x = Pw.x - gxl3d_Viewport.z/2;
  Pw.y = Pw.y + gxl3d_Viewport.w/2;
  gl_Position = gxl3d_ViewProjectionMatrix * Pw;		
  Vertex_UV = gl_MultiTexCoord0;
  Vertex_Color = gl_Color;
}
]]

  local ps_gl2=[[
#version 120
uniform sampler2D tex0;
uniform vec4 color;
varying vec4 Vertex_UV;
varying vec4 Vertex_Color;
void main (void)
{
  vec2 uv = Vertex_UV.xy;
  float t = texture2D(tex0,uv).r;
  gl_FragColor = vec4(t * Vertex_Color.rgb * color.rgb, t); 
}
]]

  local vs_gles2=[[
attribute vec4 gxl3d_Position;
attribute vec4 gxl3d_TexCoord0;
attribute vec4 gxl3d_Color;
uniform mat4 gxl3d_ViewProjectionMatrix;
uniform mat4 gxl3d_ModelMatrix;
uniform vec4 gxl3d_Viewport;
varying vec4 Vertex_UV;
varying vec4 Vertex_Color;
void main()
{
  vec4 P = gxl3d_Position;
  vec4 Pw = gxl3d_ModelMatrix * P;
  Pw.x = Pw.x - gxl3d_Viewport.z/2;
  Pw.y = Pw.y + gxl3d_Viewport.w/2;
  gl_Position = gxl3d_ViewProjectionMatrix * Pw;		
  Vertex_UV = gxl3d_TexCoord0;
  Vertex_Color = gxl3d_Color;
}
]]


  local ps_gles2=[[
precision highp float;
uniform sampler2D tex0;
uniform vec4 color;
varying vec4 Vertex_UV;
varying vec4 Vertex_Color;
void main (void)
{
  vec2 uv = Vertex_UV.xy;
  float t = texture2D(tex0,uv).r;
  gl_FragColor = vec4(t * Vertex_Color.rgb * color.rgb, t); 
}
]]


  local p = shaderlib.create_gpu_program("shaderlib_font_program", vs_gl2, ps_gl2, vs_gl3, ps_gl3, vs_gles2, ps_gles2)
  gh_gpu_program.uniform1i(p, "tex0", 0)
  shaderlib.add("font", p)

end  



----------------------------------------------------------------------------------------
function shaderlib.init()

  shaderlib.init_gpu_program_color()
  shaderlib.init_gpu_program_vertex_color()
  shaderlib.init_gpu_program_texture()
  shaderlib.init_gpu_program_phong()
  shaderlib.init_gpu_program_phong_texture()
  shaderlib.init_gpu_program_font()    

end

----------------------------------------------------------------------------------------
function shaderlib.bind_color(r, g, b, a)
  local p = shaderlib.getid("color")
  gh_gpu_program.bind(p)
  gh_gpu_program.uniform4f(p, "color", r, g, b, a)
end

----------------------------------------------------------------------------------------
function shaderlib.bind_phong_texture(light_pos_x, light_pos_y, light_pos_z, light_diff_r, light_diff_g, light_diff_b)
  local p = shaderlib.getid("phong_texture")
  gh_gpu_program.bind(p)
  gh_gpu_program.uniform4f(p, "light_position", light_pos_x, light_pos_y, light_pos_z, 1.0)
  gh_gpu_program.uniform4f(p, "light_diffuse", light_diff_r, light_diff_g, light_diff_b, 1.0)
end

----------------------------------------------------------------------------------------
function shaderlib.bind_phong(light_pos_x, light_pos_y, light_pos_z, light_diff_r, light_diff_g, light_diff_b)
  local p = shaderlib.getid("phong")
  gh_gpu_program.bind(p)
  gh_gpu_program.uniform4f(p, "light_position", light_pos_x, light_pos_y, light_pos_z, 1.0)
  gh_gpu_program.uniform4f(p, "light_diffuse", light_diff_r, light_diff_g, light_diff_b, 1.0)
end

 


