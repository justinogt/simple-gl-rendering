package main

import "core:time"
import "core:fmt"
import "core:os"
import glm "core:math/linalg/glsl"
import "vendor:glfw"
import gl "vendor:OpenGL"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

VAO           :: u32
VBO           :: u32
ShaderProgram :: u32

global_vao    : VAO
global_shader : ShaderProgram
watch         : time.Stopwatch


main :: proc() {
  if glfw.Init() == false {
    panic("Failed to init GLFW")
  }
  defer glfw.Terminate()

  glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

  window := glfw.CreateWindow(1280, 720, "Odin + GLFW", nil, nil)
  if window == nil {
    panic("Failed to create window")
  }
  defer glfw.DestroyWindow(window)

  glfw.MakeContextCurrent(window)

  gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

  vertices : [12]f32 = {
    // Coordinates
    -1, 1,
    1, 0,
    -1, 0,

    -1, 1,
    1, 1,
    1, 0,
  }

  gl.GenVertexArrays(1, &global_vao)
  gl.BindVertexArray(global_vao)

  vbo : VBO
  gl.GenBuffers(1, &vbo)
  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

  // Describe GPU buffer
  gl.BufferData(
    gl.ARRAY_BUFFER,
    size_of(vertices),
    &vertices,
    gl.STATIC_DRAW,
  )

  program_ok : bool
  vertex_shader := string(#load("vertex.glsl"))
  fragment_shader := string(#load("fragment.glsl"))
  global_shader, program_ok = gl.load_shaders_source(vertex_shader, fragment_shader)
  if !program_ok {
    fmt.println("ERROR: Failed to load and compile shaders.")
    os.exit(1)
  }
  gl.UseProgram(global_shader)

  // Position and color attributes
  gl.VertexAttribPointer(
    0,  // index
    2,  // size
    gl.FLOAT, // type
    gl.FALSE, // normalized
    2 * size_of(f32), // stride
    0, // offset
  )
  gl.EnableVertexAttribArray(0)

  gl.Enable(gl.BLEND)
  gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

  gl.Enable(gl.DEPTH_TEST)

  time.stopwatch_start(&watch)

  for glfw.WindowShouldClose(window) == false {
    glfw.PollEvents()

    render_screen(window, global_vao)

    glfw.SwapBuffers(window)
  }
}

render_screen :: proc(window: glfw.WindowHandle, vao: VAO) {
  gl.BindVertexArray(vao)
  defer gl.BindVertexArray(0)

  // Draw commands
  gl.ClearColor(0.1, 0.1, 0.1, 1)
  gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

  screen_width :f32 = 1280.0
  screen_height :f32 = 720.0
  
  projection := glm.mat4Ortho3d(0, screen_width, 0, screen_height, -1, 1)
  view := glm.mat4(1.0) * glm.mat4Translate({ 640, 360, 0 })

  model := glm.mat4(1.0) * glm.mat4Translate({ -640, 0, 0 }) * glm.mat4Scale({ 100, 100, 1 })
  u_transform := projection * view * model
  gl.UniformMatrix4fv(gl.GetUniformLocation(global_shader, "projection"), 1, false, &u_transform[0,0])
  gl.Uniform4f(gl.GetUniformLocation(global_shader, "color"), 1, 1, 1, 1)
  gl.Uniform1f(gl.GetUniformLocation(global_shader, "zIndex"), 1)
  gl.DrawArrays(
    gl.TRIANGLES, // Draw triangles
    0,  // Begin drawing at index 0
    6,   // Use 3 indices
  )

  model = glm.mat4(1.0) * glm.mat4Translate({ 0, 100, 0 }) * glm.mat4Scale({ 50, 50, 1 })
  u_transform = projection * view * model
  gl.UniformMatrix4fv(gl.GetUniformLocation(global_shader, "projection"), 1, false, &u_transform[0,0])
  gl.Uniform4f(gl.GetUniformLocation(global_shader, "color"), 1, 0, 0, 1)
  gl.Uniform1f(gl.GetUniformLocation(global_shader, "zIndex"), 1)
  gl.DrawArrays(
    gl.TRIANGLES, // Draw triangles
    0,  // Begin drawing at index 0
    6,   // Use 3 indices
  )

  model = glm.mat4(1.0) * glm.mat4Translate({ 100, -100, 0 }) * glm.mat4Scale({ 50, 50, 1 })
  u_transform = projection * view * model
  gl.UniformMatrix4fv(gl.GetUniformLocation(global_shader, "projection"), 1, false, &u_transform[0,0])
  gl.Uniform4f(gl.GetUniformLocation(global_shader, "color"), 1, 0, 0.5, 1)
  gl.Uniform1f(gl.GetUniformLocation(global_shader, "zIndex"), 1)
  gl.DrawArrays(
    gl.TRIANGLES, // Draw triangles
    0,  // Begin drawing at index 0
    6,   // Use 3 indices
  )
}