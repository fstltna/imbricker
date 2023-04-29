--[[
Quick tutorial:

- In the INIT script: 

local lib_dir = gh_utils.get_scripting_libs_dir()     
dofile(lib_dir .. "lua/vklibfont/vklibfont1.lua")    

vklibfont_init_font_height(20) -- optional
vklibfont_init_font_ttf_file(demo_dir .. "fonts/arial.ttf") -- optional
vklibfont_init_dynamic_text(0|1) -- optional


- In the FRAME script:

vklibfont_begin()
vklibfont_print(20, 20, 1, 1, 0, 1, "Hello in Yellow")
vklibfont_print(20, 40, 1, 0, 0, 1, "Hello in Red")
vklibfont_end()

vklibfont_render()


- In the SIZE script:

winW, winH = gh_window.getsize(0)
vklibfont_resize(winW, winH)

--]]




local lib_dir = gh_utils.get_lib_dir() 		
dofile(lib_dir .. "lua/vk.lua")


    


_vklibfont_initialized = false
_vklibfont_font = 0
_vklibfont_font_height = 20
_vklibfont_font_ttf_file = lib_dir .. "lua/libfont/Roboto/Roboto-Medium.ttf"
_vklibfont_dir = ""
_vklibfont_texture = 0
_vklibfont_camera_ortho = 0
_vklibfont_gpu_program = 0
_vklibfont_ub = 0
_vklibfont_sampler = 0
_vklibfont_ds = 0
_vklibfont_pipeline = 0
_vklibfont_pipeline_valid = 0
_vklibfont_dynamic_text = 1




function _vklibfont_UpdateFontUniformBuffer(width, height)
  local vec4_size = 4*4 -- one vec4
	local mat4x4_size = 16*4 -- one matrix
	local buffer_offset_bytes = 0

	gh_gpu_buffer.map(_vklibfont_ub)
	
	local vp = {x=0, y=0, w=width, h=height}
  gh_gpu_buffer.set_value_4f(_vklibfont_ub, buffer_offset_bytes, vp.x, vp.y, vp.w, vp.h)
	
	buffer_offset_bytes = vec4_size
	gh_gpu_buffer.set_matrix4x4(_vklibfont_ub, buffer_offset_bytes, _vklibfont_camera_ortho, "camera_view_projection")
	
	buffer_offset_bytes = vec4_size + mat4x4_size
	gh_gpu_buffer.set_matrix4x4(_vklibfont_ub, buffer_offset_bytes, _vklibfont_font, "object_global_transform")

	gh_gpu_buffer.unmap(_vklibfont_ub)

end


function vklibfont_init_dynamic_text(state)
	_vklibfont_dynamic_text = state
end	

function vklibfont_init_font_height(h)
	_vklibfont_font_height = h
end	

function vklibfont_init_font_ttf_file(f)
	_vklibfont_font_ttf_file = f
end	


function vklibfont_is_initialized()
	return _vklibfont_initialized
end



function vklibfont_init()

	if (_vklibfont_initialized) then 
		return true
	end

	local win_w, win_h = gh_window.getsize(0)


	_vklibfont_camera_ortho = gh_camera.create_ortho(-win_w/2, win_w/2, -win_h/2, win_h/2, 1.0, 10.0)
	gh_camera.set_viewport(_vklibfont_camera_ortho, 0, 0, win_w, win_h)
	gh_camera.set_position(_vklibfont_camera_ortho, 0, 0, 4)


	--local demo_dir = gh_utils.get_demo_dir() 		
	local lib_dir = gh_utils.get_lib_dir() 		

	_vklibfont_dir = lib_dir .. "lua/libfont/"

	local vertex_shader = _vklibfont_dir .. "spirv/font-vs.spv"
	local pixel_shader = _vklibfont_dir .. "spirv/font-ps.spv"
	_vklibfont_gpu_program = gh_gpu_program.vk_create_from_spirv_module_file("vklibfont_gpu_program",   vertex_shader, "main",   pixel_shader, "main",   "", "",    "", "",     "", "",    "", "") 
	print("_vklibfont_gpu_program => " .. _vklibfont_gpu_program)

	local anisotropy = 1.0
	_vklibfont_sampler = gh_vk.sampler_create("LINEAR", "CLAMP", anisotropy, 0)

	_vklibfont_font = gh_font.create(_vklibfont_font_ttf_file, _vklibfont_font_height, 1024, 1024)
	print("_vklibfont_font => " .. _vklibfont_font)
	gh_font.build_texture(_vklibfont_font)
	_vklibfont_texture = gh_font.get_texture(_vklibfont_font)
	print("_vklibfont_texture => " .. _vklibfont_texture)

	gh_font.set_dynamic_state(_vklibfont_font, _vklibfont_dynamic_text)

	-- r, g, b = gh_utils.hex_color_to_rgb("#ffff00")
	-- gh_font.clear(font1)
	-- gh_font.text_2d(font1, 20, 60, r, g, b, 1.0, "-- GeeXLab --")
	-- gh_font.text_2d(font1, 20, 80, r, g, b, 1.0, "Mesh Shader demo")
	-- gh_font.update(font1, 0)





	local vec4_size = 4*4 -- one vec4
	local mat4x4_size = 16*4 -- one matrix
	local ub_size = vec4_size + (mat4x4_size * 2)
	_vklibfont_ub = gh_gpu_buffer.create("UNIFORM", "NONE", ub_size, "")
	gh_gpu_buffer.bind(_vklibfont_ub)
	_vklibfont_UpdateFontUniformBuffer(win_w, win_h)


	_vklibfont_ds = gh_vk.descriptorset_create()
	print("_vklibfont_ds => " .. _vklibfont_ds)
	local ub_binding_point = 0
	gh_vk.descriptorset_add_resource_gpu_buffer(_vklibfont_ds, _vklibfont_ub, ub_binding_point, SHADER_STAGE_VERTEX)
	local tex_binding_point = 1
	if (_vklibfont_texture > 0) then
  	tex_res_index = gh_vk.descriptorset_add_resource_texture(_vklibfont_ds, _vklibfont_texture, _vklibfont_sampler, tex_binding_point, SHADER_STAGE_FRAGMENT)
	end  
	gh_vk.descriptorset_build(_vklibfont_ds)
	gh_vk.descriptorset_update(_vklibfont_ds)


	_vklibfont_pipeline = gh_vk.pipeline_create("vklibfont_pipeline", _vklibfont_gpu_program, "")
	gh_vk.pipeline_set_attrib_4i(_vklibfont_pipeline, "DEPTH_TEST", 0, 0, 0, 0)
	gh_vk.pipeline_set_attrib_4i(_vklibfont_pipeline, "FILL_MODE", POLYGON_MODE_SOLID, 0, 0, 0)
	gh_vk.pipeline_set_attrib_4i(_vklibfont_pipeline, "PRIMITIVE_TYPE", PRIMITIVE_TRIANGLE, 0, 0, 0)
	gh_vk.pipeline_set_attrib_4i(_vklibfont_pipeline, "CULL_MODE", POLYGON_FACE_NONE, 0, 0, 0)
	gh_vk.pipeline_set_attrib_4i(_vklibfont_pipeline, "CCW", 0, 0, 0, 0)
	gh_vk.pipeline_set_attrib_4i(_vklibfont_pipeline, "BLENDING", 1, 0, 0, 0)
	gh_vk.pipeline_set_attrib_4i(_vklibfont_pipeline, "BLENDING_FACTORS_COLOR", BLEND_FACTOR_ONE, BLEND_FACTOR_ONE, 0, 0)

	_vklibfont_pipeline_valid = gh_vk.pipeline_build(_vklibfont_pipeline, _vklibfont_ds)
	if (_vklibfont_pipeline_valid == 1) then
		print("_vklibfont_pipeline_valid => " .. _vklibfont_pipeline_valid)
	else
		print("ERROR: vk font pipeline is not valid.")
	end


	if (_vklibfont_pipeline_valid == 1) then
		_vklibfont_initialized = true
		return true
	end

	return false
end



function vklibfont_begin()
  if (vklibfont_init()) then
		gh_font.clear(_vklibfont_font)
	end
end  

function vklibfont_print(x, y, r, g, b, a, text)
  if (vklibfont_init()) then
		gh_font.text_2d(_vklibfont_font, x, y, r, g, b, a, text)
	end
end  

function vklibfont_print2(r, g, b, a, text)
  if (vklibfont_init()) then
		gh_font.text_2d_v2(_vklibfont_font, r, g, b, a, text)
	end
end  



function vklibfont_end()
  if (vklibfont_init()) then
		gh_font.update(_vklibfont_font, 0)
	end
end


function vklibfont_render()
	if (_vklibfont_initialized) then
		gh_vk.descriptorset_bind(_vklibfont_ds)
		gh_vk.pipeline_bind(_vklibfont_pipeline)
		gh_font.render(_vklibfont_font)
	end
end

function vklibfont_resize(w, h)
	if (_vklibfont_initialized) then
		gh_camera.update_ortho(_vklibfont_camera_ortho, -w/2, w/2, -h/2, h/2, 1.0, 10.0)
		gh_camera.set_viewport(_vklibfont_camera_ortho, 0, 0, w, h)
		_vklibfont_UpdateFontUniformBuffer(w, h)
	end
end
