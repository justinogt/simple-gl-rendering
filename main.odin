package main

import "core:time"
import "core:math"
import "core:fmt"
import "core:os"
//import "core:mem"
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

  sq := math.sqrt(f32(3)) * 0.5
  vertices : [15]f32 = {
    // Coordinates ; Colors
     1.0,   0,       1, 0, 0,
    -0.5,  sq,       0, 1, 0,
    -0.5, -sq,       0, 0, 1,
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

  // Position and color attributes
  gl.VertexAttribPointer(
    0,  // index
    2,  // size
    gl.FLOAT, // type
    gl.FALSE, // normalized
    5 * size_of(f32), // stride
    0, // offset
  )
  gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 2 * size_of(f32))

  gl.EnableVertexAttribArray(0)
  gl.EnableVertexAttribArray(1)

  program_ok : bool
  vertex_shader := string(#load("vertex.glsl"))
  fragment_shader := string(#load("fragment.glsl"))
  global_shader, program_ok = gl.load_shaders_source(vertex_shader, fragment_shader)
  if !program_ok {
    fmt.println("ERROR: Failed to load and compile shaders.")
    os.exit(1)
  }

  gl.UseProgram(global_shader)

  time.stopwatch_start(&watch)

  for glfw.WindowShouldClose(window) == false {
    glfw.PollEvents()

    render_screen(window, global_vao)

    glfw.SwapBuffers(window)
  }
}

render_screen :: proc(window: glfw.WindowHandle, vao: VAO) {
  raw_duration := time.stopwatch_duration(watch)
  secs         := f32(time.duration_seconds(raw_duration))
  theta        := -secs
  gl.Uniform1f(gl.GetUniformLocation(global_shader, "theta"), theta)

  gl.BindVertexArray(vao)
  defer gl.BindVertexArray(0)

  // Draw commands
  gl.ClearColor(0.1, 0.1, 0.1, 1)
  gl.Clear(gl.COLOR_BUFFER_BIT)

  gl.DrawArrays(
    gl.TRIANGLES, // Draw triangles
    0,  // Begin drawing at index 0
    3,   // Use 3 indices
  )

  gl.Uniform1f(gl.GetUniformLocation(global_shader, "theta"), theta + 3)
  gl.DrawArrays(
    gl.TRIANGLES, // Draw triangles
    0,  // Begin drawing at index 0
    3,   // Use 3 indices
  )
}