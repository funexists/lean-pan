/*
 * MiniFB FFI bindings
 */
#include <MiniFB.h>
#include <assert.h>
#include <lean/lean.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct {
  struct mfb_window *window;
  struct mfb_timer *global_timer;
  uint32_t *render_buffer;
  uint32_t width;
  uint32_t height;
  uint32_t x_scale;
  uint32_t y_scale;
} core_data;

static core_data CORE = {0};

#define IO_UNIT (lean_io_result_mk_ok(lean_box(0)))
#define IO_ERROR(msg)                                                          \
  (lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string((msg)))))

/*
 * initWindow
 *  - width, height: pixel dimensions for the window
 *  - x_scale, y_scale: axes span (width, height) in world units
 *  - title: window title
 *
 *  Allocates a pixel buffer sized width*height*sizeof(uint32_t)
 */
lean_obj_res initWindow(lean_obj_arg width_obj, lean_obj_arg height_obj,
                        lean_obj_arg x_scale, lean_obj_arg y_scale,
                        b_lean_obj_arg title) {
  CORE.width = lean_uint32_of_nat_mk(width_obj);
  CORE.height = lean_uint32_of_nat_mk(height_obj);
  CORE.x_scale = lean_uint32_of_nat_mk(x_scale);
  CORE.y_scale = lean_uint32_of_nat_mk(y_scale);

  assert(CORE.width > 0 && CORE.height > 0 && CORE.x_scale > 0 && CORE.y_scale);
  CORE.window = mfb_open_ex(lean_string_cstr(title), CORE.width, CORE.height,
                            WF_RESIZABLE);
  if (!CORE.window) {
    return IO_ERROR("mfb_open_ex failed");
  }

  if (CORE.render_buffer) {
    free(CORE.render_buffer);
  }

  CORE.render_buffer =
      (uint32_t *)malloc(CORE.width * CORE.height * sizeof(uint32_t));

  if (!CORE.render_buffer) {
    return IO_ERROR("malloc render_buffer failed");
  }

  CORE.global_timer = mfb_timer_create();

  if (!CORE.global_timer) {
    return IO_ERROR("global timer creation failed");
  }

  mfb_set_target_fps(60);
  return IO_UNIT;
}

/*
 * windowShouldClose
 *  - eturns true when the window should close.
 */
lean_obj_res windowShouldClose(lean_obj_arg world) {
  (void)world;
  bool sync_exit = !mfb_wait_sync(CORE.window);
  return lean_io_result_mk_ok(lean_box(sync_exit));
}

/* The user should provide this function in lean to render each pixel in a frame
 */
extern uint32_t image_frame(b_lean_obj_arg state, double x, double y);

/*
 * render
 *  - Fills the render buffer by sampling world coordinates for each pixel
 *    and calling `image_frame`, then presents via MiniFB.
 *  - Mapping:
 *      sx = x_scale/width, sy = y_scale/height
 *      x_world = i*sx - x_scale/2
 *      y_world = y_scale/2 - j*sy
 */
lean_obj_res render(b_lean_obj_arg state, lean_obj_arg world) {
  (void)world;

  if (!CORE.window) {
    return IO_ERROR("Window is NULL");
  }

  if (!CORE.render_buffer) {
    return IO_ERROR("Render buffer is NULL");
  }

  mfb_timer_now(CORE.global_timer);

  uint32_t width = CORE.width;
  uint32_t height = CORE.height;

  double sx = CORE.x_scale / (double)width;
  double sy = CORE.y_scale / (double)height;
  double ox = CORE.x_scale / 2.0;
  double oy = CORE.y_scale / 2.0;

  size_t idx = 0;
  for (uint32_t j = 0; j < height; ++j) {
    double y_world = oy - (double)j * sy;
    for (uint32_t i = 0; i < width; ++i) {
      double x_world = (double)i * sx - ox;
      // The ref count for state must be incremented because the compiler
      // decrements the ref count for state after the call to image_frame
      lean_inc(state);
      uint32_t color = image_frame(state, x_world, y_world);
      CORE.render_buffer[idx++] = color;
    }
  }
  mfb_update_state st =
      mfb_update_ex(CORE.window, CORE.render_buffer, CORE.width, CORE.height);
  return lean_io_result_mk_ok(lean_box(st == 0));
}

/* Get current time in seconds */
lean_obj_res get_time(lean_obj_arg world) {
  (void)world;
  float time = mfb_timer_delta(CORE.global_timer);
  return lean_io_result_mk_ok(lean_box_float(time));
}

/* Latest mouse X position in window pixel coordinates. */
lean_obj_res get_mouse_pos_x(lean_obj_arg world) {
  (void)world;
  double x_pos = (double)mfb_get_mouse_x(CORE.window);
  double x_pos_scale =
      (x_pos / CORE.width) * CORE.x_scale - (CORE.x_scale / 2.0);
  return lean_io_result_mk_ok(lean_box_float(x_pos_scale));
}

/* Latest mouse Y position in window pixel coordinates. */
lean_obj_res get_mouse_pos_y(lean_obj_arg world) {
  (void)world;
  double y_pos = (double)mfb_get_mouse_y(CORE.window);
  double y_pos_scale =
      -((y_pos / CORE.height) * CORE.y_scale - (CORE.y_scale / 2.0));
  return lean_io_result_mk_ok(lean_box_float(y_pos_scale));
}

/* Key-down query */
lean_obj_res is_key_down(lean_obj_arg key_obj, lean_obj_arg world) {
  (void)world;
  uint32_t key = lean_uint32_of_nat_mk(key_obj);
  uint8_t down = 0;
  if (key < 512) {
    down = mfb_get_key_buffer(CORE.window)[key];
  }
  return lean_io_result_mk_ok(lean_box(down != 0));
}

uint32_t mfb_argb(uint8_t a, uint8_t r, uint8_t g, uint8_t b) {
  return MFB_ARGB(a, r, g, b);
}
