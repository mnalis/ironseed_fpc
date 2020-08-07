/* by y.salnikov, mnalis
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 */


//#define NO_OGL

#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include "SDL.h"
#include "SDL_mixer.h"
#include <time.h>
#include <sys/time.h>
#include <math.h>
#include <errno.h>
#ifndef NO_OGL
#    define GL_GLEXT_LEGACY
#    include "SDL_opengl.h"
#    include <GL/gl.h>
#endif


#define WIDTH 640
#ifdef NO_OGL
#    define HEIGHT 480
#    define Y0 40
#else
#    define HEIGHT 450
#    define Y0 25
#endif
#define X0 0
#define XSCALE 2
#define YSCALE 2
#define TIMESCALE 1.0
#define SOUNDS_VOLUME 128
#define SOUNDS_MAX_CHANNELS 16
#define SOUNDS_PATH "sound/"
#define TURBO_FACTOR 60

static const double ratio = 640.0 / 480;

static SDL_Surface *sdl_screen;
static SDL_Thread *events;
static Mix_Music *music = NULL;
static Mix_Chunk *raw_chunks[SOUNDS_MAX_CHANNELS];

/* pascal types definitions */
typedef uint8_t		fpc_char_t;
typedef	uint8_t		fpc_byte_t;
typedef	uint8_t		fpc_boolean_t;
//typedef	int16_t		fpc_smallint_t;
//typedef	int16_t		fpc_integer_t;
typedef	uint16_t	fpc_word_t;
typedef	uint32_t	fpc_dword_t;
typedef	uint64_t	fpc_qword_t;
typedef	char *		fpc_pchar_t;
typedef	fpc_byte_t *	fpc_screentype_t;	/* array of 320x200 bytes */

typedef struct {
	uint8_t r;
	uint8_t g;
	uint8_t b;
} pal_color_type;

static pal_color_type palette[256];

static uint8_t is_video_initialized = 0;
static uint8_t is_audio_initialized = 0;
static uint8_t *v_buf = NULL;
static uint8_t do_video_stop = 0;	// command video to stop
static uint8_t is_video_finished = 0;	// has video stopped? returns status
static uint8_t cur_color = 31;
static int audio_rate;
static Uint16 audio_format;
static int audio_channels;
static int audio_buffers;
static uint8_t audio_open = 0;
static uint8_t keypressed_;
static uint16_t key_, keymod_;
static uint16_t mouse_x, mouse_y;
static uint8_t mouse_buttons;
static uint8_t showmouse;
static uint8_t mouse_icon[256];
static uint8_t normal_exit = 1;
static uint8_t fill_color;
static uint16_t cur_x;
static uint16_t cur_y;
static uint8_t cur_writemode;
static uint8_t turbo_mode = 0;
#ifndef NO_OGL
static SDL_Surface *opengl_screen;
static GLuint main_texture;
#endif
static uint8_t resize;
static int resize_x = 640;
static int resize_y = 480;
static int wx0 = 0;
static int wy0 = 0;

static const uint16_t spec_keys[] = { SDLK_LEFT, SDLK_RIGHT, SDLK_UP, SDLK_DOWN, SDLK_DELETE, SDLK_HOME, SDLK_END, SDLK_END, SDLK_PAGEUP, SDLK_PAGEDOWN, SDLK_F1, SDLK_F1, SDLK_F2, SDLK_F3, SDLK_F4, SDLK_F5, SDLK_F6, SDLK_F10, SDLK_F10, SDLK_KP_PLUS, SDLK_KP_MINUS, SDLK_KP_PERIOD, SDLK_q, SDLK_x, SDLK_1, SDLK_2, SDLK_3, SDLK_4, SDLK_7, SDLK_0, SDLK_n, SDLK_p, SDLK_b, SDLK_s, SDLK_u, SDLK_i, 0 };
static const uint16_t spec_mod[] = { 0, 0, 0, 0, 0, 0, KMOD_CTRL, 0, 0, 0, KMOD_SHIFT, 0, 0, 0, 0, 0, 0, KMOD_CTRL, 0, 0, 0, 0, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT };
static const uint8_t spec_null[] = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 };
static const uint8_t spec_map[] = { 75, 77, 72, 80, 83, 71, 117, 79, 73, 81, 84, 59, 60, 61, 62, 63, 64, 103, 16, 43, 45, 10, 16, 45, 120, 121, 122, 123, 126, 129, 49, 25, 48, 31, 22, 23 };


static inline void _nanosleep(long nsec)
{
	struct timespec ts;
	ts.tv_sec = 0;
	ts.tv_nsec = nsec;
	nanosleep(&ts, NULL);
}


/* ------------------------------------------------------ */
static void Slock(SDL_Surface * screen)
{

	if (SDL_MUSTLOCK(screen)) {
		if (SDL_LockSurface(screen) < 0) {
			return;
		}
	}

}

/* ------------------------------------------------------ */
static void Sulock(SDL_Surface * screen)
{

	if (SDL_MUSTLOCK(screen)) {
		SDL_UnlockSurface(screen);
	}

}

#ifndef NO_OGL
static void set_perspective(void)
{
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0.0, 1.0, 0.0, 1.0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}
#endif




static int resizeWindow(int width, int height)
{
	int x0, y0, WWIDTH, WHEIGHT;
	WWIDTH = width;
	WHEIGHT = height;
	if (width / ratio > height) {
		WWIDTH = (int) (height * ratio);	// always fits double in int
		WHEIGHT = height;
		x0 = (width - WWIDTH) / 2;
		y0 = 0;
	} else {
		WWIDTH = width;
		WHEIGHT = (int) (width / ratio);
		x0 = 0;
		y0 = (height - WHEIGHT) / 2;
	}
	assert(x0 >= 0);
	assert(y0 >= 0);

#ifndef NO_OGL
	opengl_screen = SDL_SetVideoMode(width, height, 0, SDL_OPENGL | SDL_RESIZABLE | SDL_GL_DOUBLEBUFFER);
	glViewport(x0, y0, (GLsizei) WWIDTH, (GLsizei) WHEIGHT);
	set_perspective();
#endif

	wx0 = x0;
	wy0 = y0;
	return 1;
}





static void DrawPixel(SDL_Surface * screen, int x, int y, Uint8 R, Uint8 G, Uint8 B)
{

	Uint32 color = SDL_MapRGB(screen->format, R, G, B);
	switch (screen->format->BytesPerPixel) {
	case 1:					// Assuming 8-bpp 
		{
			Uint8 *bufp;
			bufp = (Uint8 *) screen->pixels + y * screen->pitch + x;
			*bufp = (Uint8) color;		// 8 bits per color
		}
		break;
	case 2:					// Probably 15-bpp or 16-bpp 
		{
			Uint16 *bufp;
			bufp = (Uint16 *) screen->pixels + y * screen->pitch / 2 + x;
			*bufp = (Uint16) color;		// 16 bits per color
		}
		break;
	case 3:					// Slow 24-bpp mode, usually not used 
		{
			Uint8 *bufp;
			bufp = (Uint8 *) screen->pixels + y * screen->pitch + x * 3;
			if (SDL_BYTEORDER == SDL_LIL_ENDIAN) {
				bufp[0] = (Uint8) color;		// always 8 bits per R/G/B value
				bufp[1] = (Uint8) (color >> 8);
				bufp[2] = (Uint8) (color >> 16);
			} else {
				bufp[2] = (Uint8) color;
				bufp[1] = (Uint8) (color >> 8);
				bufp[0] = (Uint8) (color >> 16);
			}
		}
		break;
	case 4:					// Probably 32-bpp 
		{
			Uint32 *bufp;
			bufp = (Uint32 *) screen->pixels + y * screen->pitch / 4 + x;
			*bufp = color;
		}
		break;
	}

}

fpc_char_t mouse_get_status(void)
{
	uint8_t t;
	t = mouse_buttons;
	mouse_buttons = 0;
	//if (t) printf ("mouse buttons=%d, coords=%d,%d\r\n", t, mouse_get_x(), mouse_get_y());
	return t;
}

fpc_dword_t mouse_get_x(void)
{
	uint32_t x;
	double rx, rx0;
	if (resize_x == 0)
		return 0;
	rx = (double) (mouse_x) / (double) (resize_x);
	rx0 = (double) (wx0) / (double) (resize_x);
	x = (uint32_t) (WIDTH * ((rx - rx0) / (1 - 2 * rx0)));
	x = (x - X0) / XSCALE;
	if (x > 319)
		x = 319;
	return x;
}

fpc_dword_t mouse_get_y(void)
{
	uint32_t y;
	double ry, ry0;
	if (resize_y == 0)
		return 0;
	ry = (double) (mouse_y) / (double) (resize_y);
	ry0 = (double) (wy0) / (double) (resize_y);
	y = (uint32_t) (HEIGHT * ((ry - ry0) / (1 - 2 * ry0)));		// we are ok here with potential precision loss
	y = (y - Y0) / YSCALE;
	if (y > 199)
		y = 199;
	return y;
}


static void show_cursor(void)
{
	uint16_t mx, my, mw, mh, mx0, my0;
	uint8_t b;
	pal_color_type c;

	if (showmouse) {
		mx0 = (uint16_t) mouse_get_x();		// 16 bits are always more than enough
		my0 = (uint16_t) mouse_get_y();
		assert (mx0 < 320);
		mw = (uint16_t) (319 - mx0);
		if (mw > 15)
			mw = 15;
		assert (my0 < 200);
		mh = (uint16_t) (199 - my0);
		if (mh > 15)
			mh = 15;
		for (my = 0; my <= mh; my++)
			for (mx = 0; mx <= mw; mx++) {
				b = mouse_icon[mx + 16 * my];
				if (b != 255) {
					c = palette[b];
					assert (c.r < 64);
					assert (c.g < 64);
					assert (c.b < 64);
					DrawPixel(sdl_screen, X0 + (mx0 + mx) * XSCALE, Y0 + (my0 + my) * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
					DrawPixel(sdl_screen, X0 + 1 + (mx0 + mx) * XSCALE, Y0 + (my0 + my) * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
					DrawPixel(sdl_screen, X0 + 1 + (mx0 + mx) * XSCALE, Y0 + 1 + (my0 + my) * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
					DrawPixel(sdl_screen, X0 + (mx0 + mx) * XSCALE, Y0 + 1 + (my0 + my) * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
				}
			}

	}

}

void musicDone(void)
{
	if (audio_open) {
		Mix_HaltMusic();
		Mix_FreeMusic(music);
	}
	music = NULL;
}

/* stops audio and video. 
 * Normal exit from pascal calls this before finishing.
 * Must not terminate program - just stop all activities, wait for threads to finish, and free resources.
 * Pascal code must not call anything from c_utils.c ever again after this is called!
 */
void all_done(void)
{
	musicDone();

	do_video_stop = 1;
	while (!is_video_finished)
		sleep(0);
	SDL_Quit();
}

/* initiate exit from inside event_thread(), due to same error or forced close window event
 * event_thread() then must finish its near-infinite loop, set is_video_finished=1, and terminate thread  */
static int initiate_abnormal_exit(void)
{
	normal_exit = 0;
	musicDone();
	do_video_stop = 1;
	return 0;
}

/* called from main pascal thread on delay() or SDL_init_video() and possibly other often used functions, to abort cleanly if abnormal condition was detected */
static void abort_if_abnormal_exit(void)
{
	if (is_video_finished && !normal_exit) {
		SDL_Quit();
		exit(4);
	}
}


/*
 * real video hardware initialization.
 * must be only called from event_thread() thread which did SDL_SetVideoMode() - not from main pascal thread!
 */
static int SDL_init_video_real(void)		/* called from event_thread() if it was never called before (on startup only) */
{
	uint16_t x, y;

	if (SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO) != 0) {
		printf("Unable to initialize SDL: %s\n", SDL_GetError());
		return initiate_abnormal_exit();
	}
	is_audio_initialized = 1;

#ifdef NO_OGL
	sdl_screen = SDL_SetVideoMode(WIDTH, HEIGHT, 32, SDL_HWSURFACE | SDL_DOUBLEBUF);
#else
	if (SDL_BYTEORDER == SDL_LIL_ENDIAN) {
		sdl_screen = SDL_CreateRGBSurface(SDL_SWSURFACE, WIDTH, HEIGHT, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
	} else
		sdl_screen = SDL_CreateRGBSurface(SDL_SWSURFACE, WIDTH, HEIGHT, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
#endif

	if (sdl_screen == NULL) {
		printf("Unable to set %dx%d video: %s\n", WIDTH, HEIGHT, SDL_GetError());
		return initiate_abnormal_exit();
	}
	SDL_ShowCursor(SDL_DISABLE);
	Slock(sdl_screen);
	for (y = 0; y < HEIGHT; y++)
		for (x = 0; x < WIDTH; x++) {
			DrawPixel(sdl_screen, x, y, 0, 0, 0);
		}
	Sulock(sdl_screen);
	SDL_Flip(sdl_screen);
//   ---- copy - paste ----
	Slock(sdl_screen);
	for (y = 0; y < HEIGHT; y++)
		for (x = 0; x < WIDTH; x++) {
			DrawPixel(sdl_screen, x, y, 0, 0, 0);
		}
	Sulock(sdl_screen);
	SDL_Flip(sdl_screen);
//   -------------------------

#ifndef NO_OGL
	SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
	if (NULL == (opengl_screen = SDL_SetVideoMode(resize_x, resize_y, 0, SDL_OPENGL | SDL_RESIZABLE | SDL_GL_DOUBLEBUFFER))) {
		printf("Can't set OpenGL mode: %s\n", SDL_GetError());
		return initiate_abnormal_exit();
	}
	glClearColor(0.0, 0.0, 0.0, 0.0);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	SDL_WM_SetCaption("Ironseed", NULL);
	glViewport(0, 0, WIDTH, HEIGHT);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POINT_SMOOTH);
	glShadeModel(GL_SMOOTH);
	glClearStencil(0);
	glClearDepth(1.0f);
	resizeWindow(resize_x, resize_y);

	glGenTextures(1, &main_texture);
#endif

	return 1;	// init OK
}

static int video_output_once(void)
{
	uint16_t vga_x, vga_y;
	pal_color_type c;

	if (!is_video_initialized) {
		SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);
		if (!SDL_init_video_real())
			return 0;
		is_video_initialized = 1;
	}
	if (resize) {
		resize = 0;
		resizeWindow(resize_x, resize_y);
	}
	Slock(sdl_screen);
	for (vga_y = 0; vga_y < 200; vga_y++)
		for (vga_x = 0; vga_x < 320; vga_x++) {
			c = palette[v_buf[vga_x + 320 * vga_y]];
			assert (c.r < 64);
			assert (c.g < 64);
			assert (c.b < 64);
			DrawPixel(sdl_screen, X0 + vga_x * XSCALE, Y0 + vga_y * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
			DrawPixel(sdl_screen, X0 + 1 + vga_x * XSCALE, Y0 + vga_y * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
			DrawPixel(sdl_screen, X0 + vga_x * XSCALE, Y0 + 1 + vga_y * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
			DrawPixel(sdl_screen, X0 + 1 + vga_x * XSCALE, Y0 + 1 + vga_y * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
		}


	show_cursor();
	Sulock(sdl_screen);
	SDL_Flip(sdl_screen);	// FIXME: shouldn't use with opengl? http://lazyfoo.net/SDL_tutorials/lesson36/index.php
#ifndef NO_OGL
	glLoadIdentity();
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);	// clear buffers
	glEnable(GL_TEXTURE_2D);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

	glBindTexture(GL_TEXTURE_2D, main_texture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, WIDTH, HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, sdl_screen->pixels);

	glBegin(GL_QUADS);
	glTexCoord2f(0.0, 1.0);
	glVertex2f(0.0, 0.0);
	glTexCoord2f(1.0, 1.0);
	glVertex2f(1.0, 0.0);
	glTexCoord2f(1.0, 0.0);
	glVertex2f(1.0, 1.0);
	glTexCoord2f(0.0, 0.0);
	glVertex2f(0.0, 1.0);
	glEnd();
	glFlush();
	SDL_GL_SwapBuffers();
#endif
	return 1;	// no errors
}




static int handle_events_once(void)
{
	SDL_Event event;
	assert(is_video_initialized);
	while (SDL_PollEvent(&event)) {
		if (event.type == SDL_QUIT) {
			return initiate_abnormal_exit();
		}
		if (event.type == SDL_KEYDOWN) {
			if (event.key.keysym.sym == SDLK_SCROLLOCK) {
				turbo_mode = 1;
			} else {
				uint8_t key_found = 0, key_index = 0;
				uint16_t event_mod = event.key.keysym.mod & (uint16_t) (~(KMOD_CAPS | KMOD_NUM));	/* ignore state of CapsLock / NumLock */
				//printf ("SDL_KEYDOWN keysym.sym: %"PRIu16" keysym.mod:%"PRIu16"\t", event.key.keysym.sym, event.key.keysym.mod);

				/* traverse list of all special keys and their modifiers, and verify if we match */
				while (spec_keys[key_index]) {
					//printf (" check key_index=%"PRIu8", spec_mod[key_index]=%"PRIu16" AND=%"PRIu16" -- ", key_index, spec_mod[key_index], event_mod & spec_mod[key_index]);
					if ((spec_mod[key_index] == 0) || (event_mod & spec_mod[key_index]))
						if (spec_keys[key_index] == event.key.keysym.sym)
							key_found = 2;
					key_index++;
					//if (!key_found) printf (" No match.\r\n");
				}

				if ((event.key.keysym.sym <= 255) && (event_mod == 0)) {	/* regular ASCII key, and no modifiers, process as normal */
					key_found = 1;
				}

				if (key_found) {	/* only return key pressed if it is either regular ASCII key, or extended key we know about */
					keypressed_ = 1;
					key_ = event.key.keysym.sym;
					keymod_ = event_mod;

				}
				//printf(" END key_found=%"PRIu8" keypressed_=%"PRIu8" key_=%"PRIu16" keymod_=%"PRIu16"\r\n", key_found, keypressed_, key_, keymod_);
			}
		}
		if (event.type == SDL_KEYUP) {
			if (event.key.keysym.sym == SDLK_SCROLLOCK) {
				turbo_mode = 0;
			}
		}

		if (event.type == SDL_MOUSEMOTION) {
			int32_t ex, ey;
			ex = event.motion.x;
			ey = event.motion.y;
			assert (ex >= 0);
			assert (ex < UINT16_MAX);
			assert (ey >= 0);
			assert (ey < UINT16_MAX);
			mouse_x = (uint16_t) ex;
			mouse_y = (uint16_t) ey;
		}
		if (event.type == SDL_MOUSEBUTTONDOWN) {	//If the left mouse button was pressed
			if (event.button.button == SDL_BUTTON_LEFT) {
				mouse_buttons = 0x01;
			}
		}
		if (event.type == SDL_VIDEORESIZE) {
			resize = 1;
			resize_x = event.resize.w;
			resize_y = event.resize.h;
		}
	}
	return 1; 	// events without error
}


static int event_thread(void *notused)
{
	while (!do_video_stop) {
		if (!video_output_once())	/* updates screen, and on startup initializes all of SDL if not done already */
			break;			/* some error, probably video/audio failed to initialize or something, abort */
		if (!handle_events_once())	/* keyboard, mouse, windows resize/close, and more */
			break;			/* some error like SDL_QUIT, abort */

		SDL_Delay(10);			/* give up some time to other threads */
	}
	is_video_finished = 1;
	//_nanosleep(10000000);
	return 0;	// and thread terminates
}



void SDL_init_video(fpc_screentype_t vga_buf)	/* called from pascal; vga_buf is 320x200 bytes */
{
	v_buf = vga_buf;
	do_video_stop = 0;
	is_video_finished = 0;
	events = SDL_CreateThread(event_thread, NULL);
	while (!(is_video_initialized || is_video_finished))
		SDL_Delay(100);
}


void setrgb256(const fpc_byte_t palnum, const fpc_byte_t r, const fpc_byte_t g, const fpc_byte_t b)	// set palette
{
	palette[palnum].r = r;
	palette[palnum].g = g;
	palette[palnum].b = b;
}

void getrgb256_(const fpc_byte_t palnum, fpc_byte_t * r, fpc_byte_t * g, fpc_byte_t * b)	// get palette
{
	*r = palette[palnum].r;
	*g = palette[palnum].g;
	*b = palette[palnum].b;
}

void set256colors(pal_color_type * pal)	// set all palette
{
//      uint16_t i;
//      for(i=0; i<256;i++)
//      {
//              palette[i].r=pal[i].r;
//              palette[i].g=pal[i].g;
//              palette[i].b=pal[i].b;
//      }
	memcpy(palette, pal, 256 * 3);
}

void sdl_mixer_init(void)
{
	assert (is_audio_initialized);
	audio_rate = 44100;
	audio_format = AUDIO_S16;
	audio_channels = 2;
	audio_buffers = 4096;
	if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers)) {
		audio_open = 0;
		printf("Unable to open audio!\n");
	} else {
		audio_open = 1;
	}
}


void play_mod(const fpc_byte_t loop, const fpc_pchar_t filename)
{
	int l;

	if (music != NULL)
		musicDone();

	if (!audio_open)
		return;

	music = Mix_LoadMUS(filename);
	/* This begins playing the music - the first argument is a
	   pointer to Mix_Music structure, and the second is how many
	   times you want it to loop (use -1 for infinite, and 0 to
	   have it just play once) */
	if (music == NULL)
		printf("load music error %s\n", filename);
	if (loop)
		l = -1;
	else
		l = 0;
	Mix_PlayMusic(music, l);

	/* We want to know when our music has stopped playing so we
	   can free it up and set 'music' back to NULL.  SDL_Mixer
	   provides us with a callback routine we can use to do
	   exactly that */
	Mix_HookMusicFinished(musicDone);
	Mix_VolumeMusic(128);
}

void haltmod(void)
{
	if (!audio_open)
		return;
	Mix_HaltMusic();
}


static uint64_t delta_usec(void)
{
	uint64_t cur_usec, tmp;
	static uint64_t old_usec;
	struct timeval tv;

	gettimeofday(&tv, NULL);
	cur_usec = (uint64_t) tv.tv_sec * 1000000L + (uint64_t) tv.tv_usec;	// struct timeval elements should never be negative
	tmp = cur_usec - old_usec;
	old_usec = cur_usec;
	return tmp;
}

void delay(const fpc_word_t ms)
{
	static uint64_t err;
	int64_t us = 1;
	delta_usec();
	us = (int64_t) (ms * 1000 * TIMESCALE) - (int64_t) err;	// we're always small enough so convert to int64 is not a problem
	if (turbo_mode)
		us /= TURBO_FACTOR;
	while (us > 0) {
		us -= (int64_t) delta_usec();	// delta_usec() will always be small, so 63bits are always OK
		_nanosleep(5000);
	}
	err = (uint64_t) -us;		// while(us>0) guarantees that "us <= 0" now
	abort_if_abnormal_exit();
}

void upscroll(const fpc_screentype_t img)	// 320x200 bytes 
{
	uint16_t y;
	for (y = 1; y < 100; y++) {
		memmove(v_buf + (320 * (200 - y)), img, 320U * y);
		delay(5);
	}
}

void scale_img(const fpc_word_t x0s, const fpc_word_t y0s, const fpc_word_t widths, const fpc_word_t heights, const fpc_word_t x0d, const fpc_word_t y0d, const fpc_word_t widthd, const fpc_word_t heightd, const fpc_screentype_t s, fpc_screentype_t d)
{
	uint16_t xd, yd;
	double kx, ky;
	kx = (double) widths / (double) widthd;
	ky = (double) heights / (double) heightd;
	for (yd = 0; yd < heightd; yd++)
		for (xd = 0; xd < widthd; xd++) {
			d[((x0d + xd) + 320 * (yd + y0d))] = s[(x0s + (uint16_t) (xd * kx) + 320 * (y0s + (uint16_t) (yd * ky)))];
		}

}

void setcolor(const fpc_word_t color)
{
	assert(color < 256);
	cur_color = (uint8_t) color;
}

static void draw_pixel(int16_t x, int16_t y)
{
	assert (x >= 0);
	assert (x < 320);
	assert (y >= 0);
	assert (y < 200);
	if (cur_writemode)
		v_buf[x + 320 * y] = v_buf[x + 320 * y] ^ cur_color;
	else
		v_buf[x + 320 * y] = cur_color;
}

void circle(const fpc_word_t x, const fpc_word_t y, const fpc_word_t r)
{
	int16_t xx, yy;
	const double E = 0.9;
	xx = 0;
	yy =(int16_t) r;	// we're confident it will always fit in < 32767. Also, draw_pixel() does sanity checks.
	draw_pixel((int16_t) (x + xx), (int16_t) (y + yy * E));
	draw_pixel((int16_t) (x - xx), (int16_t) (y + yy * E));
	draw_pixel((int16_t) (x + xx), (int16_t) (y - yy * E));
	draw_pixel((int16_t) (x - xx), (int16_t) (y - yy * E));
	while (yy >= 1) {
		yy = (int16_t) (yy - 1);
		if ((xx * xx) + (yy * yy) < (r * r))
			xx = (int16_t) (xx + 1);
		if ((xx * xx) + (yy * yy) < (r * r))
			yy = (int16_t) (yy + 1);
		draw_pixel((int16_t) (x + xx), (int16_t) (y + yy * E));
		draw_pixel((int16_t) (x - xx), (int16_t) (y + yy * E));
		draw_pixel((int16_t) (x + xx), (int16_t) (y - yy * E));
		draw_pixel((int16_t) (x - xx), (int16_t) (y - yy * E));
	}
}

fpc_byte_t key_pressed(void)
{
	uint8_t k;
	k = keypressed_;
//      keypressed=0;
	_nanosleep(500000);
	return k;
}

fpc_char_t readkey(void)
{
	static uint8_t null_key, key_index;
	uint8_t key;

	if (null_key) {
		key = spec_map[key_index];
		null_key = 0;
	} else {
		key_index = 0;
		while (spec_keys[key_index]) {
			if ((spec_mod[key_index] == 0) || (keymod_ & spec_mod[key_index]))	/* if special key requires no modifier, of if modifier match ... */
				if (spec_keys[key_index] == key_) {	/* ... and the key itself matches ... */
					null_key = spec_null[key_index];	/* ... then generate extended keycode */
					break;
				}
			key_index++;
		}

		if (spec_keys[key_index] == 0) {	/* no special keys matched; so it is regular ASCII key without modifiers */
			assert(key_ < 256);
			key = (uint8_t) key_;
		} else {				/* we matched some special key, translate it as regular or extended keycode */
			if (!null_key)
				key = spec_map[key_index];
			else
				key = 0;
		}
	}
	keypressed_ = 0;
	_nanosleep(500000);
	return key;
}


void rectangle(const fpc_word_t x1, const fpc_word_t y1, const fpc_word_t x2, const fpc_word_t y2)
{
	int16_t i;
//      printf("rect : %d %d %d %d  color %d\n",x1,y1,x2,y2,cur_color);
	assert (x1 < 320);
	assert (x2 < 320);
	assert (y1 < 200);
	assert (y2 < 200);
	if (x2 > x1)
		for (i = (int16_t) x1; i < (int16_t) x2; i++) {
			draw_pixel(i, (int16_t) y1);
			draw_pixel(i, (int16_t) y2);
	} else
		for (i = (int16_t) x2; i < (int16_t) x1; i++) {
			draw_pixel(i, (int16_t) y1);
			draw_pixel(i, (int16_t) y2);
		}
	if (y2 > y1)
		for (i = (int16_t) y1; i < (int16_t) y2; i++) {
			draw_pixel((int16_t) x1, i);
			draw_pixel((int16_t) x2, i);
	} else
		for (i = (int16_t) y2; i < (int16_t) y1; i++) {
			draw_pixel((int16_t) x1, i);
			draw_pixel((int16_t) x2, i);
		}


}

void mousehide(void)
{
	showmouse = 0;
}

void mouseshow(void)
{
	showmouse = 1;
}

void mousesetcursor(uint8_t * icon)
{
	memcpy(mouse_icon, icon, 16*16);
}


void setmodvolumeto(const fpc_word_t vol)
{
	if (!audio_open)
		return;
	Mix_VolumeMusic(vol / 2);
}

void move_mouse(const fpc_word_t x, const fpc_word_t y)
{
	double rx0, ry0;
	fpc_word_t xx, yy;
	xx = x;
	yy = y;

	if (xx > 319)
		xx = 319;
	xx = (fpc_word_t) (xx * XSCALE + X0);	// we should always fit into < 32767 (famous last words)
	rx0 = (double) (wx0) / (double) (resize_x);
	mouse_x = (uint16_t) (((double) xx * (1 - 2 * rx0) / (double) WIDTH + rx0) * (double) (resize_x));	// we don't really care about possible precission loss here

	if (yy > 199)
		yy = 199;
	yy = (fpc_word_t) (yy * YSCALE + Y0);
	ry0 = (double) (wy0) / (double) (resize_y);
	mouse_y = (uint16_t) (((double) yy * (1 - 2 * ry0) / (double) HEIGHT + ry0) * (double) (resize_y));

	SDL_WarpMouse(mouse_x, mouse_y);
}

void play_sound(const fpc_pchar_t filename, const fpc_word_t rate)
{
	FILE *f;
	long l;
	uint32_t i;
	size_t length, loaded, r, remains;
	int8_t *sound_raw, chan;
	float k;
	int16_t *sound, smp;
	char *fn, *s, *s1;

	if (!audio_open)
		return;

	fn = malloc(256);
	assert(fn != NULL);
	s1 = strdup(filename);
	assert(s1 != NULL);
	s = s1;
	while (*s) {
		*s = (char) toupper(*s);	// toupper(3) works with int, but only defined on char
		s++;
	}
	strcpy(fn, SOUNDS_PATH);
	strcat(fn, s1);
	f = fopen(fn, "rb");
	if (f == NULL) {
		printf("Can't open file %s\n", fn);
		free(fn);
		free(s1);
		return;
	}
	fseek(f, 0, SEEK_END);
	l = ftell(f);
	assert(l >= 0);
	length = (size_t) l;
	fseek(f, 0, SEEK_SET);
	sound_raw = malloc(length);
	assert(sound_raw != NULL);
	loaded = 0;
	while (loaded < length) {
		remains = length - loaded;
		r = fread(sound_raw + loaded, 1, remains, f);
		if (r > 0)	/* fread(3) returns 0 on error, as size_t is not signed */
			loaded += r;
		else {
			printf("Can't read %s @%ld error= %d\n", fn, ftell(f), errno);
			free(sound_raw);
			free(fn);
			free(s1);
			return;
		}
	}
	fclose(f);
	free(fn);
	free(s1);
// resample and play    
	k = (float) rate / (float) audio_rate;
	uint32_t qwords = (uint32_t) ((float)length / k);	// not really exact, so we'll allocate + 1 quadword extra
	sound = calloc(1 + qwords, 4);
	assert(sound != NULL);
	for (i = 0; i < qwords; i++) {
		uint32_t idx = (uint32_t) ((float) i * k);	// k is float, so this does not look really exact, but is seems to work...
		int32_t test_smp = (sound_raw[idx] * SOUNDS_VOLUME); assert (test_smp <= INT16_MAX && test_smp >= INT16_MIN);
		smp = (int16_t) (sound_raw[idx] * SOUNDS_VOLUME);
		sound[i * 2] = smp;
		sound[1 + i * 2] = smp;
//              printf("%d / %d, %d / %d\n\r",i,(uint32_t)(length/k),(int32_t)(i*k),length);
	}
	free(sound_raw);
	chan = -1;
	for (i = 0; i < SOUNDS_MAX_CHANNELS; i++) {
		if (!Mix_Playing((int) i)) {
			if (raw_chunks[i] != NULL) {
				Mix_FreeChunk(raw_chunks[i]);
				raw_chunks[i] = NULL;
			}
			assert(i < 256);
			chan = (int8_t) i;
			break;
		}
	}
	if (chan >= 0) {
		if (!(raw_chunks[chan] = Mix_QuickLoad_RAW((void *) sound, qwords * 4))) {
			printf("Mix_QuickLoad_RAW: %s\n", Mix_GetError());
		}
		Mix_PlayChannel(chan, raw_chunks[chan], 0);
	}
	if (sound != NULL)
		free(sound);
}


void pausemod(void)
{
	if (!audio_open)
		return;
	Mix_PauseMusic();
}

void continuemod(void)
{
	if (!audio_open)
		return;
	Mix_ResumeMusic();
}


void setfillstyle(const fpc_word_t style, const fpc_word_t f_color)
{
	assert(f_color < 256);
	fill_color = (uint8_t) f_color;
	if (style > 1)
		printf("setfillstyle style=%d\n", style);

}

void bar(const fpc_word_t x1, const fpc_word_t y1, const fpc_word_t x2, const fpc_word_t y2)
{
	uint16_t i, j, x, xe, y, ye;
//      printf("rect : %d %d %d %d  color %d\n",x1,y1,x2,y2,cur_color);
	if (x2 > x1) {
		x = x1;
		xe = x2;
	} else {
		x = x2;
		xe = x1;
	}
	if (y2 > y1) {
		y = y1;
		ye = y2;
	} else {
		y = y2;
		ye = y1;
	}
	assert (ye*320+xe < 320*200);
	for (j = y; j < ye; j++)
		for (i = x; i < xe; i++)
			v_buf[i + 320 * j] = fill_color;
}





void line(const fpc_word_t x1, const fpc_word_t y1, const fpc_word_t x2, const fpc_word_t y2)
{
//      printf("%d,%d - %d,%d\n",x1,y1,x2,y2);
	assert (x1 < 320);
	assert (x2 < 320);
	assert (y1 < 200);
	assert (y2 < 200);

	int i, dx, dy, sdx, sdy, dxabs, dyabs, x, y, px, py;
	dx = x2 - x1;				// the horizontal distance of the line
	dy = y2 - y1;				// the vertical distance of the line
	dxabs = abs(dx);
	dyabs = abs(dy);
	if (dx > 0)
		sdx = 1;
	else
		sdx = -1;
	if (dy > 0)
		sdy = 1;
	else
		sdy = -1;
	x = dyabs >> 1;
	y = dxabs >> 1;
	px = x1;
	py = y1;
	draw_pixel((int16_t) px, (int16_t) py);	// we trust line() calculations given asserts above and in draw_pixel()
	if (dxabs >= dyabs) {			// the line is more horizontal than vertical
		for (i = 0; i < dxabs; i++) {
			y += dyabs;
			if (y >= dxabs) {
				y -= dxabs;
				py += sdy;
			}
			px += sdx;
			draw_pixel((int16_t) px, (int16_t) py);
		}
	} else {				// the line is more vertical than horizontal
		for (i = 0; i < dyabs; i++) {
			x += dxabs;
			if (x >= dyabs) {
				x -= dyabs;
				px += sdx;
			}
			py += sdy;
			draw_pixel((int16_t) px, (int16_t) py);
		}
	}

	cur_x = x2;
	cur_y = y2;

}





void moveto(const fpc_word_t x, const fpc_word_t y)
{
	cur_x = x;
	cur_y = y;
}

void lineto(const fpc_word_t x, const fpc_word_t y)
{
	line(cur_x, cur_y, x, y);
}

void pieslice(const fpc_word_t x, const fpc_word_t y, const fpc_word_t phi0, const fpc_word_t phi1, const fpc_word_t r)
{
	int16_t i, j;
	int32_t pos;
	double f, f0, f1;
	const double E = 0.9;
	f0 = phi0 * M_PI / 180.0;
	f1 = phi1 * M_PI / 180.0;
	for (j = (int16_t) -r; j < r; j++)
		for (i = (int16_t) -r; i < r; i++) {
			f = atan2(j, i);
			if (f < 0)
				f += 2 * M_PI;
			if ((f >= f0) && (f < f1)) {
				if ((i * i + j * j) <= r * r) {
					pos = i + x + 320 * (y - (int) (j * E));
					assert(pos >= 0);
					assert(pos < 320*200);
					v_buf[pos] = fill_color;
				}
			}
		}
}

void setwritemode(const fpc_byte_t mode)	/* it can be CopyPut=0 or XorPut=1, so byte is ok, doesn't need to be SmallInt */
{
	cur_writemode = mode;
}

fpc_boolean_t playing(void)
{
	if (!audio_open)
		return 0;
	return (fpc_boolean_t) Mix_PlayingMusic();	/* Mix_PlayingMusic() returns 0 or 1, so it is OK for boolean */
}
