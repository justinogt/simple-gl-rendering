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

Transform :: struct {
  position: [3]f32,
  size:    [3]f32,
}

Camera :: struct {
  position: [3]f32,
  zoom    : f32,
}

FollowCamera :: struct {
  speed :f32,
  offset: [3]f32,
}

Rect :: struct {
  transform: Transform,
  pivot    : [3]f32,
  color    : [4]f32,
}

get_camera_matrix :: proc(camera: Camera) -> glm.mat4 {
  return glm.mat4Translate(-camera.position) * glm.mat4Scale({ camera.zoom, camera.zoom, 1 })
}

render_rect :: proc(rect: Rect, view_matrix: glm.mat4) {
  transform := rect.transform
  model := glm.mat4Translate(transform.position + transform.size * -rect.pivot) *
    glm.mat4Scale(transform.size)
  u_transform := projection * view_matrix * model
  gl.UniformMatrix4fv(gl.GetUniformLocation(global_shader, "projection"), 1, false, &u_transform[0,0])
  gl.Uniform4f(gl.GetUniformLocation(global_shader, "color"), rect.color.r, rect.color.g, rect.color.b, rect.color.a)
  gl.DrawArrays(
    gl.TRIANGLES, // Draw triangles
    0,  // Begin drawing at index 0
    6,   // Use 3 indices
  )
}

update_follow_camera :: proc(camera: ^Camera, follow_camera: FollowCamera, target_position: [3]f32, delta_time: f32) {
  desired_position := target_position - follow_camera.offset
  camera.position += (desired_position - camera.position) * delta_time * follow_camera.speed
}

get_mouse_in_view :: proc(window: glfw.WindowHandle, view_matrix: glm.mat4) -> (x: f32, y: f32) {
  raw_mouse_x, raw_mouse_y: f64 = glfw.GetCursorPos(window)
  mouse_x := f32(raw_mouse_x)
  mouse_y := f32(raw_mouse_y)

  ndc_x := (2.0 * mouse_x / screen_width) - 1.0
  ndc_y := 1.0 - (2.0 * mouse_y / screen_height)
  ndc_z :f32 = 0.0

  clip := glm.vec4{ ndc_x, ndc_y, ndc_z, 1.0 }

  inv_proj := glm.inverse(projection * view_matrix)
  world := inv_proj * clip

  final := world.xyz / world.w
  fmt.printf("Mouse X: %f, Y: %f\n", final.x, final.y)

  return final.x, final.y
}

projection := glm.mat4Ortho3d(0, screen_width, 0, screen_height, -100, 100)
main_camera := Camera {
  position = { screen_width / 2, 55, 1 },
  zoom     = 1,
}
main_follow_camera := FollowCamera {
  speed = 2,
  offset = { screen_width / 2, 100, 1 },
}

player := Rect {
  transform = {
    position = { screen_width / 2, 55, 1 },
    size     = { 50, 100, 0 },
  },
  color = { 1, 1, 1, 1 },
}

simple_level := [3]Rect {
  {
    transform = {
      position = { 0, 0, 0 },
      size     = { screen_width, 50, 0 },
    },
    color = { 0.2, 0.1, 0.1, 1 },
  },
  {
    transform = {
      position = { 10, 0, 0 },
      size     = { 50, screen_height, 0 },
    },
    color = { 0.2, 0.1, 0.1, 1 },
  },
  {
    transform = {
      position = { screen_width - 50 - 10, 0, 0 },
      size     = { 50, screen_height, 0 },
    },
    color = { 0.2, 0.1, 0.1, 1 },
  },
}

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
    0, 1,
    0, 0,
    1, 0,

    1, 0,
    1, 1,
    0, 1,
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

    update_follow_camera(&main_camera, main_follow_camera, player.transform.position, delta_time)
    view := get_camera_matrix(main_camera)

    mouse_x, mouse_y := get_mouse_in_view(window, view)

    if mouse_x >= player.transform.position.x &&
       mouse_x <= player.transform.position.x + player.transform.size.x &&
       mouse_y >= player.transform.position.y &&
       mouse_y <= player.transform.position.y + player.transform.size.y {
      player.color = { 1, 0, 0, 1 }
    } else {
      player.color = { 1, 1, 1, 1 }
    }

    render_screen(window, global_vao, delta_time, view)

    glfw.SwapBuffers(window)
  }
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	// Exit program on escape pressed
	if key == glfw.KEY_LEFT {
    player.transform.position.x -= 100
	} else if key == glfw.KEY_RIGHT {
    player.transform.position.x += 100
  } else if key == glfw.KEY_UP {
    player.transform.position.y += 100
  } else if key == glfw.KEY_DOWN {
    player.transform.position.y -= 100
  }
}

render_screen :: proc(window: glfw.WindowHandle, vao: VAO, delta_time: f32, view: glm.mat4) {
  gl.BindVertexArray(vao)
  defer gl.BindVertexArray(0)

  // Draw commands
  gl.ClearColor(0.1, 0.1, 0.1, 1)
  gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

  render_rect(player, view)

  for rect in simple_level {
    render_rect(rect, view)
  }
}