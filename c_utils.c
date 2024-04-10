/*
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
 *
 *  On Debian systems, the complete text of the GNU General Public
 *  License, version 2, can be found in /usr/share/common-licenses/GPL-2.
 *
 *  Copyright:
 *   2013 y-salnikov
 *   2020,2024 Matija Nalis <mnalis-git@voyager.hr>
 */



#include <assert.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include "SDL.h"
#include "SDL_mixer.h"
#include <time.h>
#include <sys/time.h>
#include <math.h>
#include <errno.h>


// VGA screen used by original DOS game, i.e. 320x200
#define ORG_WIDTH 320
#define ORG_HEIGHT 200

#define WIDTH 640
#define HEIGHT 480
#define Y0 40
#define X0 0
#define XSCALE 2
#define YSCALE 2
#define TIMESCALE 1.0
#define SOUNDS_VOLUME 128
#define SOUNDS_MAX_CHANNELS 16
#define TURBO_FACTOR 7		// 2^7=64 - speed up by this factor if ScrollLock is pressed

static const double ratio = 640.0 / 480;

static Uint32 sdl_screen[640*480];		// FIXME SDL2 get rid of this (replace with static  memory buffer and remove Slock/Sunlock) to simplify
static SDL_Window *sdlWindow;
static SDL_Renderer *sdlRenderer;
static SDL_Texture *sdlTexture;
static SDL_Thread *_sdl_events;
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

static volatile uint8_t is_video_initialized = 0;
static volatile uint8_t is_audio_initialized = 0;
static volatile uint8_t do_sdl_audio = 0;
static uint8_t *v_buf = NULL;			// FreePascal video buffer of 320x200 pixel, with 1 byte index to pallete[] for each pixel
static volatile uint8_t do_video_stop = 0;	// command video to stop
static volatile uint8_t is_video_finished = 0;	// has video stopped? returns status
static uint8_t cur_color = 31;
static const int audio_rate = 44100;
static uint8_t audio_open = 0;
static volatile uint8_t keypressed_;
static volatile SDL_Keycode key_;
static volatile SDL_Scancode keyscan_;
static volatile uint16_t keyutf8_,keymod_;
static volatile uint16_t mouse_x, mouse_y;
static volatile uint8_t mouse_buttons;
static uint8_t showmouse;
static uint8_t mouse_icon[256];
static volatile uint8_t normal_exit = 1;
static uint8_t fill_color;
static uint16_t cur_x;
static uint16_t cur_y;
static uint8_t cur_writemode;
static volatile uint8_t turbo_mode = 0;
static int is_sdl_fullscreen = 0;		// assume we're in windowed (not fullscreen) mode on startup
static uint8_t do_resize = 0;
static volatile int resize_x = 640;
static volatile int resize_y = 480;
static volatile int wx0 = 0;
static volatile int wy0 = 0;

const SDL_Keycode spec_keys[] = {SDLK_KP_4, SDLK_LEFT, SDLK_KP_6, SDLK_RIGHT, SDLK_KP_8, SDLK_UP, SDLK_KP_2, SDLK_DOWN, SDLK_DELETE, SDLK_KP_7, SDLK_HOME, SDLK_END , SDLK_KP_1, SDLK_END, SDLK_KP_9, SDLK_PAGEUP, SDLK_KP_3, SDLK_PAGEDOWN, SDLK_KP_5, SDLK_F1   , SDLK_F1, SDLK_F2, SDLK_F3, SDLK_F4, SDLK_F5, SDLK_F6, SDLK_F10 , SDLK_F10, SDLK_KP_PLUS, SDLK_KP_MINUS, SDLK_j   , SDLK_q  , SDLK_x  , SDLK_1  , SDLK_2  , SDLK_3  , SDLK_4  , SDLK_7  , SDLK_0  , SDLK_n  , SDLK_p  , SDLK_b  , SDLK_s  , SDLK_u  , SDLK_i	, 0};
const uint16_t spec_mod[] =     {0        , 0        , 0        , 0         , 0        , 0      , 0        , 0        , 0          , 0        , 0        , KMOD_CTRL, 0        , 0       , 0        , 0          , 0        , 0            , 0        , KMOD_SHIFT, 0      , 0      , 0      , 0      , 0      , 0      , KMOD_CTRL, 0       , 0           , 0            , KMOD_CTRL, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT, KMOD_ALT};
const uint8_t  spec_null[] =    {0        , 1        , 0        , 1         , 0        , 1      , 0        , 1        , 1          , 0        , 1        , 1        , 0        , 1       , 0        , 1          , 0        , 1            , 0        , 1         , 1      , 1      , 1      , 1      , 1      , 1      , 1        , 1       , 0           , 0            , 0        , 1       , 1       , 1       , 1       , 1       , 1       , 1       , 1       , 1       , 1       , 1       , 1       , 1       , 1    };
const uint8_t  spec_map[] =     {52       , 75       , 54       , 77        , 56       , 72     , 50       , 80       , 83         , 55       , 71       , 117      , 49       , 79      , 57       , 73         , 51       , 81           , 53       , 84        , 59     , 60     , 61     , 62     , 63     , 64     , 103      , 16      , 43          , 45           , 10       , 16      , 45      , 120     , 121     , 122     , 123     , 126     , 129     , 49      , 25      , 48      , 31      , 22      , 23   };


static inline void _nanosleep(long nsec)
{
	struct timespec ts;
	ts.tv_sec = 0;
	ts.tv_nsec = nsec;
	nanosleep(&ts, NULL);
}


static void sdl_go_back_to_windowed_mode(void)
{
	if (!is_sdl_fullscreen)
		return;

	// FIXME SDL2 SDL_WM_ToggleFullScreen(sdl_screen);	// never check for error condition you don't know how to handle
	is_sdl_fullscreen = 0;
}




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

	//printf ("resizeWindow w=%d,h=%d; calc x0=%d, y0=%d, w=%d, h=%d\r\n", width, height, x0, y0, WWIDTH, WHEIGHT);
	if (is_sdl_fullscreen) {
		sdl_go_back_to_windowed_mode();
	} else {
		// FIXME SDL2 SDL_WM_ToggleFullScreen(sdl_screen);
		is_sdl_fullscreen = 1;
	}

	return 1;
}





static void DrawPixel(int x, int y, Uint8 R, Uint8 G, Uint8 B)
{

	Uint32 color = 0xff << 24 | R << 16 | G << 8 | B;  // for SDL_PIXELFORMAT_ARGB8888 
	// FIXME SDL2 little / big endian test - see https://afrantzis.com/pixel-format-guide/sdl2.html
	Uint32 *bufp;
	bufp = (Uint32 *) sdl_screen + y * WIDTH + x;
	*bufp = color;

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
	if (x > ORG_WIDTH-1)
		x = ORG_WIDTH-1;
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
	if (y > ORG_HEIGHT-1)
		y = ORG_HEIGHT-1;
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
		assert (mx0 < ORG_WIDTH);
		mw = (uint16_t) (ORG_WIDTH-1 - mx0);
		if (mw > 15)
			mw = 15;
		assert (my0 < ORG_HEIGHT);
		mh = (uint16_t) (ORG_HEIGHT-1 - my0);
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
					DrawPixel(X0 + (mx0 + mx) * XSCALE, Y0 + (my0 + my) * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
					DrawPixel(X0 + 1 + (mx0 + mx) * XSCALE, Y0 + (my0 + my) * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
					DrawPixel(X0 + 1 + (mx0 + mx) * XSCALE, Y0 + 1 + (my0 + my) * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
					DrawPixel(X0 + (mx0 + mx) * XSCALE, Y0 + 1 + (my0 + my) * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
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
	if (is_video_initialized)
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
	sdl_go_back_to_windowed_mode();		/* no-op if we're not in SDL fullscreen mode */
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
	uint32_t SDL_flags = SDL_INIT_VIDEO;
	static volatile uint8_t is_sdl_initialized = 0;

	//printf ("SDL_init_video_real called, is_sdl_initialized=%d, is_audio_initialized=%d, is_video_initialized=%d\r\n", is_sdl_initialized, is_audio_initialized, is_video_initialized);
	assert (!is_sdl_initialized);		/* do not allow double init, or terrible bugs happen down the line! */

	if (do_sdl_audio)
		SDL_flags |= SDL_INIT_AUDIO;

	if (SDL_Init(SDL_flags) != 0) {
		printf("Unable to initialize SDL: %s\r\n", SDL_GetError());
		return initiate_abnormal_exit();
	}
	is_sdl_initialized = 1;

	if (do_sdl_audio)
		is_audio_initialized = 1;

	// FIXME SDL2 SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);
	// FIXME SDL2 SDL_EnableUNICODE(1);

	sdlWindow = SDL_CreateWindow("Ironseed",
                          SDL_WINDOWPOS_UNDEFINED,
                          SDL_WINDOWPOS_UNDEFINED,
                          WIDTH, HEIGHT,
                          0);	// FIXME SDL2 which flags?  SDL_WINDOW_FULLSCREEN_DESKTOP ? start windowed as default?
//                          SDL_WINDOW_FULLSCREEN | SDL_WINDOW_OPENGL);	// FIXME SDL2 flags?
	// FIXME before SDL2 was: SDL_SetVideoMode(WIDTH, HEIGHT, 32, SDL_HWSURFACE | SDL_DOUBLEBUF);

	if (sdlWindow == NULL) {
		printf("Unable to set %dx%d video: %s\r\n", WIDTH, HEIGHT, SDL_GetError());
		return initiate_abnormal_exit();
	}
	
	sdlRenderer = SDL_CreateRenderer(sdlWindow, -1, 0);
	if (sdlRenderer == NULL) {
		printf("Unable to create renderer: %s\r\n", SDL_GetError());
		return initiate_abnormal_exit();
	}

	// FIXME SDL enable and use 320x200 and SDL native scaling!
	SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");  // make the scaled rendering look smoother.
	SDL_RenderSetLogicalSize(sdlRenderer, 640, 480);
	
	SDL_ShowCursor(SDL_DISABLE);

	// clear screen
	SDL_SetRenderDrawColor(sdlRenderer, 0, 0, 0, 255);
	SDL_RenderClear(sdlRenderer);
	SDL_RenderPresent(sdlRenderer);

	sdlTexture = SDL_CreateTexture(sdlRenderer,
                     SDL_PIXELFORMAT_ARGB8888,
                     SDL_TEXTUREACCESS_STREAMING,
                     WIDTH, HEIGHT);	// FIXME SDL2 - should we hardcode 320*200 here and let SDL handle all resizing?

	return 1;	// init OK
}

static int video_output_once(void)
{
	uint16_t vga_x, vga_y;
	pal_color_type c;

	if (!is_video_initialized) {
		if (!SDL_init_video_real())
			return 0;
		is_video_initialized = 1;
	}
	if (do_resize) {
		do_resize = 0;
		resizeWindow(resize_x, resize_y);
	}
	for (vga_y = 0; vga_y < ORG_HEIGHT; vga_y++)
		for (vga_x = 0; vga_x < ORG_WIDTH; vga_x++) {
			c = palette[v_buf[vga_x + ORG_WIDTH * vga_y]];
#ifndef NDEBUG
			if ((c.r >= 64) || (c.g >= 64) || (c.b >= 64))
				printf ("WARNING: RGB at %d,%d color=%d will overflow: %d,%d,%d\r\n", vga_x, vga_y, v_buf[vga_x + ORG_WIDTH * vga_y], c.r, c.g, c.b);
#endif
			DrawPixel(X0 + vga_x * XSCALE, Y0 + vga_y * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
			DrawPixel(X0 + 1 + vga_x * XSCALE, Y0 + vga_y * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
			DrawPixel(X0 + vga_x * XSCALE, Y0 + 1 + vga_y * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
			DrawPixel(X0 + 1 + vga_x * XSCALE, Y0 + 1 + vga_y * YSCALE, (Uint8) (c.r << 2), (Uint8) (c.g << 2), (Uint8) (c.b << 2));
		}


	show_cursor();

	SDL_UpdateTexture(sdlTexture, NULL, sdl_screen, WIDTH * sizeof (Uint32));
	SDL_RenderClear(sdlRenderer);
	SDL_RenderCopy(sdlRenderer, sdlTexture, NULL, NULL);
	SDL_RenderPresent(sdlRenderer);

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
			if (event.key.keysym.sym == 12345 /* // FIXME SDL2 SDLK_SCROLLOCK*/) {
				turbo_mode = 1;
			} else if (event.key.keysym.sym == SDLK_F11) {
				do_resize = 1;	// note: updating resize_x, resize_y only breaks the mouse movements.
			} else {
				uint8_t key_found = 0, key_index = 0;
				uint16_t event_mod = event.key.keysym.mod & (uint16_t) (~(KMOD_CAPS | KMOD_NUM));	/* ignore state of CapsLock / NumLock */
				//printf ("SDL_KEYDOWN keysym .sym: %"PRIu16" .scancode:%"PRIu8" .mod:%"PRIu16" .unicode:%"PRIu16"\t", event.key.keysym.sym, event.key.keysym.scancode, event.key.keysym.mod,  event.key.keysym.unicode);

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
				} else if ((event.key.keysym.sym <= 255) && ((event_mod & (~KMOD_SHIFT)) == 0)) {	/* regular ASCII key, and shift modifier, process as normal */
					key_found = 1;
				}

				if (key_found) {	/* only return key pressed if it is either regular ASCII key, or extended key we know about */
					keypressed_ = 1;
					key_ = event.key.keysym.sym;
					keyutf8_ = (SDL_Keycode) (key_ & 0x7f); // FIXME SDL2 replacement? keyutf8_ = event.key.keysym.unicode;
					keyscan_ = event.key.keysym.scancode;
					keymod_ = event_mod;

				}
				//printf(" END key_found=%"PRIu8" keypressed_=%"PRIu8" keyscan_=%"PRIu8" key_=%"PRIu16" keyutf8_=%"PRIu16" keymod_=%"PRIu16"\r\n", key_found, keypressed_, keyscan_, key_, keyutf8_, keymod_);
			}
		}
/* FIXME SDL2		if (event.type == SDL_KEYUP) {
			if (event.key.keysym.sym == SDLK_SCROLLOCK) {
				turbo_mode = 0;
			}
		}
*/

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
	sdl_go_back_to_windowed_mode();		/* no-op if we're not in SDL fullscreen mode */
	is_video_finished = 1;
	//_nanosleep(10000000);
	return 0;	// and thread terminates
}



void SDL_init_video(fpc_screentype_t vga_buf, const fpc_boolean_t use_audio)	/* called from pascal; vga_buf is 320x200 bytes */
{
	v_buf = vga_buf;
	do_sdl_audio = use_audio;
	do_video_stop = 0;
	is_video_finished = 0;
	_sdl_events = SDL_CreateThread(event_thread, NULL, NULL);
	while (!(is_video_initialized || is_video_finished))
		SDL_Delay(100);
}


void setrgb256(const fpc_byte_t palnum, const fpc_byte_t r, const fpc_byte_t g, const fpc_byte_t b)	// set palette
{
	assert (r<64);
	assert (g<64);
	assert (b<64);
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

void set256colors(const pal_color_type * pal)	// set all palette
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
	static const Uint16 audio_format = AUDIO_S16;
	static const int audio_channels = 2;
	static const int audio_buffers = 4096;

	//printf ("sdl_mixer_init called, is_audio_initialized=%d, audio_open=%d\r\n", is_audio_initialized, audio_open);
	assert (is_audio_initialized);
	//assert (!audio_open);
	if (audio_open)		/* avoid double initialization */
		return;

	if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers)) {
		audio_open = 0;
		printf("Unable to open audio!\r\n");
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
		printf("load music error %s\r\n", filename);
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
		us = us >> TURBO_FACTOR;
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
		memmove(v_buf + (ORG_WIDTH * (ORG_HEIGHT - y)), img, ORG_WIDTH * y);
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
			d[((x0d + xd) + ORG_WIDTH * (yd + y0d))] = s[(x0s + (uint16_t) (xd * kx) + ORG_WIDTH * (y0s + (uint16_t) (yd * ky)))];
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
	assert (x < ORG_WIDTH);
	assert (y >= 0);
	assert (y < ORG_HEIGHT);
	if (cur_writemode)
		v_buf[x + ORG_WIDTH * y] = v_buf[x + ORG_WIDTH * y] ^ cur_color;
	else
		v_buf[x + ORG_WIDTH * y] = cur_color;
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

/* like readkey(), but for standard letters returns UTF8 version
 * which takes into account shift and other modifiers used.
 * we actually only need it for ASCII uppercase/lowercase, and punctuations,
 * as the game does not support real UTF-8....
 *
 * Used only for typing activities, like crew/aliens chat, entering
 * savegame name or inputting astrogation coordinates manually.
 */
fpc_char_t readkey_utf8(void)
{
	fpc_char_t key = readkey();
	if ((key > 32) && (key < 127) && keyutf8_ < 255) {
		key = (fpc_char_t) keyutf8_;
	}
	return key;
}

/*
 * like readkey(), but never remaps keys, used for cube navigation and alike.
 * so third keyboard row is always "QWERTY" no matter what mapping OS does (AZERTY, QWERTZ etc).
 * actually we get remapped letter, and then try to unmap it for keys the game uses.
 */
fpc_char_t readkey_nomap(void)
{
	uint8_t key_index = 0;
	/*
	static const uint16_t spec_codes[] = { SDL_SCANCODE_GRAVE, SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3, SDL_SCANCODE_Q, SDL_SCANCODE_W, SDL_SCANCODE_E, SDL_SCANCODE_R, SDL_SCANCODE_T, SDL_SCANCODE_A, SDL_SCANCODE_S, SDL_SCANCODE_D,SDL_SCANCODE_F, SDL_SCANCODE_G, SDL_SCANCODE_Z, SDL_SCANCODE_X, SDL_SCANCODE_C, SDL_SCANCODE_V, SDL_SCANCODE_B, SDL_SCANCODE_P,	0 };	// SDL 2.x has names, and they should work?...
	//static const uint16_t spec_codes[] = { 53 , 30 , 31 , 32 , 20 , 26 ,  8 , 21 , 23 ,  4 , 22 ,  7 ,  9 , 10 , 29 , 27 ,  6 , 25 ,  5 , 19 ,	0 };	// SDL 1.2 does not have symbolic names for keycodes, those values from SDL2 do not work: https://wiki.libsdl.org/SDL_Keycode
	static const uint8_t  spec_unmap[] = { '`', '1', '2', '3', 'q', 'w', 'e', 'r', 't', 'a', 's', 'd', 'f', 'g', 'z', 'x', 'c', 'v', 'b', 'p' };

	// No-op for now. SDL1.2 says scancodes are not really supported and are is hardware dependent, and it seems to be true... https://www.libsdl.org/release/SDL-1.2.15/docs/html/guideinputkeyboard.html	
	*/

	static const uint16_t spec_codes[] = { 0 };
	static const uint8_t  spec_unmap[] = { 0 };

	fpc_char_t key = readkey();
	//printf ("unmapped b4: readkey()=%d >%c<, keyutf8_=%d, keyscan=%d\r\n", key, key, keyutf8_, keyscan_);
	if ((key > 32) && (key < 127)) {
		while (spec_codes[key_index]) {
			if (spec_codes[key_index] == keyscan_) {
				key = spec_unmap[key_index];
				//printf ("   unmap[%d]: readkey()=%d >%c<, keyutf8_=%d, keyscan=%d\r\n", key_index, key, key, keyutf8_, keyscan_);
				break;
			}
			key_index++;
		}
	}
	return key;
}

void rectangle(const fpc_word_t x1, const fpc_word_t y1, const fpc_word_t x2, const fpc_word_t y2)
{
	int16_t i;
//      printf("rect : %d %d %d %d  color %d\r\n",x1,y1,x2,y2,cur_color);
	assert (x1 < ORG_WIDTH);
	assert (x2 < ORG_WIDTH);
	assert (y1 < ORG_HEIGHT);
	assert (y2 < ORG_HEIGHT);
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

void mousesetcursor(const uint8_t * icon)
{
	memcpy(mouse_icon, icon, 16*16);
}


void setmodvolumeto(const fpc_word_t vol)
{
	if (!audio_open)
		return;
	assert (vol * 2 <= MIX_MAX_VOLUME);
	Mix_VolumeMusic(vol * 2);
}

void move_mouse(const fpc_word_t x, const fpc_word_t y)
{
	double rx0, ry0;
	fpc_word_t xx, yy;
	xx = x;
	yy = y;

	if (xx > ORG_WIDTH-1)
		xx = ORG_WIDTH-1;
	xx = (fpc_word_t) (xx * XSCALE + X0);	// we should always fit into < 32767 (famous last words)
	rx0 = (double) (wx0) / (double) (resize_x);
	mouse_x = (uint16_t) (((double) xx * (1 - 2 * rx0) / (double) WIDTH + rx0) * (double) (resize_x));	// we don't really care about possible precision loss here

	if (yy > ORG_HEIGHT-1)
		yy = ORG_HEIGHT-1;
	yy = (fpc_word_t) (yy * YSCALE + Y0);
	ry0 = (double) (wy0) / (double) (resize_y);
	mouse_y = (uint16_t) (((double) yy * (1 - 2 * ry0) / (double) HEIGHT + ry0) * (double) (resize_y));

	SDL_WarpMouseInWindow(sdlWindow, mouse_x & 0xffff, mouse_y & 0xffff);	// FIXME SDL2 kludges
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

	if (!audio_open)
		return;

	f = fopen(filename, "rb");
	if (f == NULL) {
		printf("Can't open file %s\r\n", filename);
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
			printf("Can't read %s @%ld error= %d\r\n", filename, ftell(f), errno);
			free(sound_raw);
			return;
		}
	}
	fclose(f);
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
//              printf("%d / %d, %d / %d\r\n",i,(uint32_t)(length/k),(int32_t)(i*k),length);
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
			printf("Mix_QuickLoad_RAW: %s\r\n", Mix_GetError());
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
		printf("setfillstyle style=%d\r\n", style);

}

void bar(const fpc_word_t x1, const fpc_word_t y1, const fpc_word_t x2, const fpc_word_t y2)
{
	uint16_t i, j, x, xe, y, ye;
//      printf("rect : %d %d %d %d  color %d\r\n",x1,y1,x2,y2,cur_color);
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
	assert (ye*ORG_WIDTH+xe < ORG_WIDTH*ORG_HEIGHT);
	for (j = y; j < ye; j++)
		for (i = x; i < xe; i++)
			v_buf[i + ORG_WIDTH * j] = fill_color;
}





void line(const fpc_word_t x1, const fpc_word_t y1, const fpc_word_t x2, const fpc_word_t y2)
{
//      printf("%d,%d - %d,%d\r\n",x1,y1,x2,y2);
	assert (x1 < ORG_WIDTH);
	assert (x2 < ORG_WIDTH);
	assert (y1 < ORG_HEIGHT);
	assert (y2 < ORG_HEIGHT);

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
					pos = i + x + ORG_WIDTH * (y - (int) (j * E));
					assert(pos >= 0);
					assert(pos < ORG_WIDTH*ORG_HEIGHT);
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
