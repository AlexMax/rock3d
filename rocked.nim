import strformat, strutils

import opengl, glm, sdl2

type Shader = distinct GLuint
type Program = distinct GLuint

proc newShader(stype: GLenum, source: string): Shader =
  var str: array[1, string] = [source]
  var cs = allocCStringArray(str)
  defer: deallocCStringArray(cs)

  var shader = glCreateShader(stype)
  glShaderSource(shader, GLsizei(1), cs, nil)
  glCompileShader(shader)

  var status: GLint
  glGetShaderiv(shader, GL_COMPILE_STATUS, addr status)

  if status == GL_FALSE.GLint:
    var len: GLint
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, addr len)

    var log: cstring = cast[cstring](alloc(len))
    glGetShaderInfoLog(shader, len, nil, log)
    var err = "Shader compile error\n" & $log
    dealloc(log)
    raise newException(Exception, err)

  return shader.Shader

proc newProgram(shaders: openArray[Shader]): Program =
  var program = glCreateProgram()
  for shader in shaders:
    glAttachShader(program, shader.GLuint)
  glLinkProgram(program)

  var status: GLint
  glGetProgramiv(program, GL_LINK_STATUS, addr status)

  if status == GL_FALSE.GLint:
    raise newException(Exception, "Link Error")

  return program.Program

# Initialize SDL2
if sdl2.init(sdl2.INIT_VIDEO) == sdl2.SdlError:
  echo "sdl2.init: " & $sdl2.getError()
  quit(QuitFailure)

# Create the window
var window = sdl2.createWindow("RockED", sdl2.SDL_WINDOWPOS_CENTERED,
  sdl2.SDL_WINDOWPOS_CENTERED, 800, 500, sdl2.SDL_WINDOW_OPENGL)
if window == nil:
  echo "sdl2.createWindow: " & $sdl2.getError()
  quit(QuitFailure)

# Create the OpenGL context
discard sdl2.glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
discard sdl2.glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3)
discard sdl2.glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)

var context = sdl2.glCreateContext(window)
if context == nil:
  echo "sdl2.glCreateContext: " & $sdl2.getError()
  quit(QuitFailure)

var
  major: cint
  minor: cint
  profile: cint

discard sdl2.glGetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, major)
discard sdl2.glGetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, minor)
discard sdl2.glGetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, profile)

if (major == 3 and minor < 3) or (major < 3):
  echo "sdl2.glCreateContext: Couldn't get OpenGL 3.3 context"
  quit(QuitFailure)

#if profile != SDL_GL_CONTEXT_PROFILE_CORE:
#  echo "sdl2.glCreateContext: Couldn't get core profile"
#  quit(QuitFailure)

echo &"Initialized OpenGL {major}.{minor}"

opengl.loadExtensions()

const vert: string = staticRead("shader/vert.glsl")
var vs = newShader(GL_VERTEX_SHADER, vert)

const frag: string = staticRead("shader/frag.glsl")
var fs = newShader(GL_FRAGMENT_SHADER, frag)

var prog = newProgram(@[vs, fs])

var vertexes: array[9, GLfloat] = [
  -0.5'f32, -0.5'f32, 0.0'f32,
  0.5'f32, -0.5'f32, 0.0'f32,
  0.0'f32,  0.5'f32, 0.0'f32
]

var indexes: array[3, GLuint] = [
  0'u32, 1'u32, 2'u32
]

var vao: GLuint
glGenVertexArrays(1, addr vao)
glBindVertexArray(vao)

var vbo: GLuint
glGenBuffers(1, addr vbo)
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(vertexes), addr vertexes, GL_STATIC_DRAW)

var ebo: GLuint
glGenBuffers(1, addr ebo)
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), addr indexes, GL_STATIC_DRAW)

glVertexAttribPointer(0, 3, cGL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), nil)
glEnableVertexAttribArray(0);

glBindVertexArray(0)

#glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

# Render
glClearColor(0.0, 0.4, 0.4, 1.0)
glClear(GL_COLOR_BUFFER_BIT)

glUseProgram(prog.GLuint)
glBindVertexArray(vao)
glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, nil)

echo "OpenGL Error: " & $ord(glGetError())

#var perspective = glm.perspective(glm.radians(90.0), 800.0 / 500.0, 0.1, 1024.0)

sdl2.glSwapWindow(window)

sdl2.delay(3000)
