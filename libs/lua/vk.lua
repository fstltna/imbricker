

POLYGON_MODE_POINT = 0
POLYGON_MODE_LINE = 1
POLYGON_MODE_SOLID = 2



POLYGON_FACE_NONE = 0
POLYGON_FACE_BACK = 1
POLYGON_FACE_FRONT = 2
POLYGON_FACE_BACK_FRONT = 3



PRIMITIVE_TRIANGLE = 0
PRIMITIVE_TRIANGLE_STRIP = 1
PRIMITIVE_LINE = 2
PRIMITIVE_LINE_STRIP = 3
PRIMITIVE_LINE_LOOP = 4
PRIMITIVE_LINE_ADJACENCY = 5
PRIMITIVE_LINE_STRIP_ADJACENCY = 6
PRIMITIVE_PATCH = 7
PRIMITIVE_POINT = 8



SHADER_STAGE_VERTEX = 1
SHADER_STAGE_TESSELLATION_CONTROL = 2
SHADER_STAGE_TESSELLATION_EVALUATION = 4
SHADER_STAGE_GEOMETRY = 8
SHADER_STAGE_FRAGMENT = 16
SHADER_STAGE_COMPUTE = 32
SHADER_STAGE_TASK = 64
SHADER_STAGE_MESH = 128


BLEND_FACTOR_ONE = 1
BLEND_FACTOR_SRC_ALPHA = 2
BLEND_FACTOR_ONE_MINUS_DST_ALPHA = 3
BLEND_FACTOR_ONE_MINUS_DST_COLOR = 4
BLEND_FACTOR_ONE_MINUS_SRC_ALPHA = 5
BLEND_FACTOR_DST_COLOR = 6
BLEND_FACTOR_DST_ALPHA = 7
BLEND_FACTOR_SRC_COLOR = 8
BLEND_FACTOR_ONE_MINUS_SRC_COLOR = 9




function vk_create_pipeline_v1(name, gpu_prog, descriptor_set)
  local pso01 = gh_vk.pipeline_create(name, gpu_prog, "")
  gh_vk.pipeline_set_attrib_4i(pso01, "DEPTH_TEST", 1, 0, 0, 0)
  gh_vk.pipeline_set_attrib_4i(pso01, "FILL_MODE", POLYGON_MODE_SOLID, 0, 0, 0)
  gh_vk.pipeline_set_attrib_4i(pso01, "PRIMITIVE_TYPE", PRIMITIVE_TRIANGLE, 0, 0, 0)
  gh_vk.pipeline_set_attrib_4i(pso01, "CULL_MODE", POLYGON_FACE_NONE, 0, 0, 0)
  gh_vk.pipeline_set_attrib_4i(pso01, "CCW", 0, 0, 0, 0)
  local pso_valid = gh_vk.pipeline_build(pso01, descriptor_set)
  if (pso_valid == 0) then
    --print("ERROR: pipeline " .. name .. " is not valid.")
    return 0
  end
  return pso01
end

function vk_create_pipeline_v2(name, gpu_prog, descriptor_set, wireframe, depth_test)
  local pso01 = gh_vk.pipeline_create(name, gpu_prog, "")
  gh_vk.pipeline_set_attrib_4i(pso01, "DEPTH_TEST", depth_test, 0, 0, 0)
  if (wireframe == 1) then
    gh_vk.pipeline_set_attrib_4i(pso01, "FILL_MODE", POLYGON_MODE_LINE, 0, 0, 0)
  else
    gh_vk.pipeline_set_attrib_4i(pso01, "FILL_MODE", POLYGON_MODE_SOLID, 0, 0, 0)
  end
  gh_vk.pipeline_set_attrib_4i(pso01, "PRIMITIVE_TYPE", PRIMITIVE_TRIANGLE, 0, 0, 0)
  gh_vk.pipeline_set_attrib_4i(pso01, "CULL_MODE", POLYGON_FACE_NONE, 0, 0, 0)
  gh_vk.pipeline_set_attrib_4i(pso01, "CCW", 0, 0, 0, 0)
  local pso_valid = gh_vk.pipeline_build(pso01, descriptor_set)
  if (pso_valid == 0) then
    --print("ERROR: pipeline " .. name .. " is not valid.")
    return 0
  end
  return pso01
end
