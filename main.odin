package main

import "core:time"
// import "core:time"
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

screen_width :f32 = 1280.0
screen_height :f32 = 720.0

main :: proc() {
  if glfw.Init() == false {
    panic("Failed to init GLFW")
  }
  defer glfw.Terminate()

  glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

  window := glfw.CreateWindow(i32(screen_width), i32(screen_height), "Odin + GLFW", nil, nil)
  if window == nil {
    panic("Failed to create window")
  }
  defer glfw.DestroyWindow(window)

  glfw.MakeContextCurrent(window)

  // Enable vsync
	// https://www.glfw.org/docs/3.3/group__context.html#ga6d4e0cdf151b5e579bd67f13202994ed
  glfw.SwapInterval(1)

  glfw.SetKeyCallback(window, key_callback)

  gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

  vertices : [12]f32 = {
    // Coordinates
    -1, 1,
    0, 0,
    -1, 0,

    -1, 1,
    0, 1,
    0, 0,
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

  // start_tick := time.tick_now()
  last_tick := time.tick_now()

  for glfw.WindowShouldClose(window) == false {
    current_tick := time.tick_now()
    delta_tick := time.tick_diff(last_tick, current_tick)
    delta_time := f32(time.duration_seconds(delta_tick))
    last_tick = current_tick

    glfw.PollEvents()

    render_screen(window, global_vao, delta_time)

    glfw.SwapBuffers(window)
  }
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	// Exit program on escape pressed
	if key == glfw.KEY_LEFT {
    player_x -= 100
	} else if key == glfw.KEY_RIGHT {
    player_x += 100
  } else if key == glfw.KEY_UP {
    player_y += 100
  } else if key == glfw.KEY_DOWN {
    player_y -= 100
  }
}

camera_x := screen_width / 2
camera_y := screen_height / 2

target_camera_x := screen_width / 2
target_camera_y := screen_height / 2

player_x :f32 = 0
player_y :f32 = 0
render_screen :: proc(window: glfw.WindowHandle, vao: VAO, delta_time: f32) {
  gl.BindVertexArray(vao)
  defer gl.BindVertexArray(0)

  // Draw commands
  gl.ClearColor(0.1, 0.1, 0.1, 1)
  gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

  target_camera_x = player_x - (screen_width / 2)
  target_camera_y = player_y - (screen_height / 2)

  camera_x += (target_camera_x - camera_x) * delta_time
  camera_y += (target_camera_y - camera_y) * delta_time
  
  projection := glm.mat4Ortho3d(0, screen_width, 0, screen_height, -1, 1)
  view := glm.mat4Translate({-camera_x, -camera_y, 0})

  model := glm.mat4Translate({ player_x, player_y, 0 }) * glm.mat4Scale({ 100, screen_height / 2, 1 })
  u_transform := projection * view * model
  gl.UniformMatrix4fv(gl.GetUniformLocation(global_shader, "projection"), 1, false, &u_transform[0,0])
  gl.Uniform4f(gl.GetUniformLocation(global_shader, "color"), 1, 1, 1, 1)
  gl.Uniform1f(gl.GetUniformLocation(global_shader, "zIndex"), 1)
  gl.DrawArrays(
    gl.TRIANGLES, // Draw triangles
    0,  // Begin drawing at index 0
    6,   // Use 3 indices
  )

  model = glm.mat4Translate({ screen_width / 2, -screen_height / 2, 0 }) * glm.mat4Scale({ screen_width, 50, 1 })
  u_transform = projection * view * model
  gl.UniformMatrix4fv(gl.GetUniformLocation(global_shader, "projection"), 1, false, &u_transform[0,0])
  gl.Uniform4f(gl.GetUniformLocation(global_shader, "color"), 0, 0, 0, 1)
  gl.Uniform1f(gl.GetUniformLocation(global_shader, "zIndex"), 1)
  gl.DrawArrays(
    gl.TRIANGLES, // Draw triangles
    0,  // Begin drawing at index 0
    6,   // Use 3 indices
  )

}