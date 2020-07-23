/* by y.salnikov
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


#include <assert.h>
#include <string.h>
#include <stdio.h>
#include "SDL.h"
#include "SDL_mixer.h"
#include <sys/time.h>
#include <math.h>
#include <errno.h>
#include "SDL_opengl.h"
#include <GL/gl.h>


//#define NO_OGL

#define WIDTH 640
#ifdef NO_OGL
	#define HEIGHT 480
	#define Y0 40
#else
	#define HEIGHT 450
	#define Y0 25
#endif
#define X0 0
#define XSCALE 2
#define YSCALE 2
#define TIMESCALE 1.0
#define SOUNDS_VOLUME 128
#define SOUNDS_MAX_CHANNELS 16
#define SOUNDS_PATH "sound/"
#define TURBO_FACTOR 60

const double ratio=640.0/480;

SDL_Surface *sdl_screen, *opengl_screen;
SDL_Thread *video, *keyshandler;
Mix_Music *music = NULL;
Mix_Chunk *raw_chunks[SOUNDS_MAX_CHANNELS];



typedef struct
{
	uint8_t r;
	uint8_t g;
	uint8_t b;
} pal_color_type;

pal_color_type palette[256];

struct {
               time_t tv_sec;        /* seconds */
               long   tv_nsec;       /* nanoseconds */
           } ts;


uint8_t *v_buf;
uint8_t video_stop=0;
uint8_t video_done=0;
uint8_t keys_done=0;
uint16_t cur_color=31;
int audio_rate;
Uint16 audio_format;
int audio_channels;
int audio_buffers;
int looping;
int interactive;
uint8_t audio_open;
uint8_t keypressed_;
uint16_t key_;
int32_t mouse_x,mouse_y;
uint8_t mouse_buttons;
uint8_t showmouse;
uint8_t mouse_icon[256];
uint8_t normal_exit=1;
uint8_t fill_color;
uint16_t cur_x;
uint16_t cur_y;
uint8_t cur_writemode;
uint8_t turbo_mode=0;
GLuint main_texture;
uint8_t resize;
int resize_x=640;
int resize_y=480;
int wx0=0;
int wy0=0;

const uint16_t spec_keys[] = {SDLK_LEFT, SDLK_RIGHT, SDLK_UP, SDLK_DOWN, SDLK_DELETE, SDLK_HOME, SDLK_END, SDLK_PAGEUP, SDLK_PAGEDOWN, SDLK_F1, SDLK_F2, SDLK_F3, SDLK_F4, SDLK_F5, SDLK_F6, SDLK_F10, SDLK_KP_PLUS, SDLK_KP_MINUS	,0};
const uint8_t spec_null[] =  {1        , 1         , 1      , 1        , 1			, 1        , 1       , 1          , 1            , 1      , 1      , 1      , 1      , 1      , 1      , 1       , 0           , 0           };
const uint8_t spec_map[] =   {75       , 77        , 72     , 80       , 83         , 71       , 79      , 73         , 81           , 59     , 60     , 61     , 62     , 63     , 64     , 16		 , 43          , 45          };


int dummy(int w,int h);
int (*resize_callback)(int w,int h)=dummy;
int32_t mouse_get_x(void);
int32_t mouse_get_y(void);


void set_resize_callback(int (*callback)(int w,int h))
{
	resize_callback=callback;
}

int dummy(int w,int h)
{
	return 0;
}


void stop_video_thread(void);
void all_done(void);

void memmove_wrapper(void *dest, void *src, int n)
{
	memmove(dest,src,n);
}

void musicDone(void);

/* ------------------------------------------------------ */
void Slock(SDL_Surface *screen){ 

 if ( SDL_MUSTLOCK(screen) ){ 
   if ( SDL_LockSurface(screen) < 0 ){ 
     return; 
   } 
 } 

} 

/* ------------------------------------------------------ */
void Sulock(SDL_Surface *screen){

 if ( SDL_MUSTLOCK(screen) ){ 
   SDL_UnlockSurface(screen); 
 } 

}

void set_perspective(void)
{
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
    gluOrtho2D(0.0, 1.0, 0.0, 1.0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}





int resizeWindow( int width, int height )
{
    int x0,y0,WWIDTH,WHEIGHT;
    WWIDTH=width;
    WHEIGHT=height;
    if(width/ratio > height)
    {
        WWIDTH=height*ratio;
        WHEIGHT=height;
        x0=(width-WWIDTH)/2;
        y0=0;
    } else
    {
        WWIDTH=width;
        WHEIGHT=width/ratio;
        x0=0;
        y0=(height-WHEIGHT)/2;
    }

    opengl_screen = SDL_SetVideoMode(width, height, 0, SDL_OPENGL |SDL_RESIZABLE | SDL_GL_DOUBLEBUFFER );

    glViewport( x0, y0, ( GLsizei )WWIDTH, ( GLsizei )WHEIGHT );

    set_perspective();
    wx0=x0;
    wy0=y0;
    return 1;
}



void init_opengl(void)
{
    SDL_GL_SetAttribute( SDL_GL_STENCIL_SIZE, 8 );
    if (NULL == (opengl_screen = SDL_SetVideoMode(resize_x, resize_y, 0, SDL_OPENGL |SDL_RESIZABLE | SDL_GL_DOUBLEBUFFER )))
    {
        printf("Can't set OpenGL mode: %s\n", SDL_GetError());
        SDL_Quit();
        exit(1);
    } 
    glClearColor(0.0,0.0,0.0,0.0);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER,1);
    SDL_WM_SetCaption("Ironseed",NULL);
    glViewport(0,0,WIDTH,HEIGHT);
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_LINE_SMOOTH);
    glEnable(GL_POINT_SMOOTH);
    glShadeModel(GL_SMOOTH);
    glClearStencil(0);     
    glClearDepth(1.0f);
	resizeWindow(resize_x,resize_y);
    
}






void DrawPixel(SDL_Surface *screen, int x, int y, Uint8 R, Uint8 G, Uint8 B){ 

 Uint32 color = SDL_MapRGB(screen->format, R, G, B); 
 switch (screen->format->BytesPerPixel){ 
   case 1:  // Assuming 8-bpp 
   { 
     Uint8 *bufp; 
     bufp = (Uint8 *)screen->pixels + y*screen->pitch + x; *bufp = color; 
   } break; 
   case 2: // Probably 15-bpp or 16-bpp 
   { 
     Uint16 *bufp; 
     bufp = (Uint16 *)screen->pixels + y*screen->pitch/2 + x; *bufp = color; 
   } break; 
   case 3: // Slow 24-bpp mode, usually not used 
   { 
     Uint8 *bufp; 
     bufp = (Uint8 *)screen->pixels + y*screen->pitch + x * 3; 
     if(SDL_BYTEORDER == SDL_LIL_ENDIAN){ 
       bufp[0] = color; 
       bufp[1] = color >> 8; 
       bufp[2] = color >> 16; 
     }else{ 
       bufp[2] = color; 
       bufp[1] = color >> 8; 
       bufp[0] = color >> 16; 
     } 
   } break; 
   case 4: // Probably 32-bpp 
   { 
     Uint32 *bufp; 
     bufp = (Uint32 *)screen->pixels + y*screen->pitch/4 + x; 
     *bufp = color; 
   } break; 
 } 

} 

void show_cursor(void)
{
	uint16_t mx,my,mw,mh,mx0,my0;
	uint8_t b;
	pal_color_type c;

	if(showmouse)
			{
				mx0=mouse_get_x();
				my0=mouse_get_y();
				mw=(319-mx0); if(mw>15) mw=15;
				mh=(199-my0); if(mh>15) mh=15;
				for(my=0;my<=mh;my++)
					for(mx=0;mx<=mw;mx++)
						{   b=mouse_icon[mx+16*my];
							if(b!=255)
							{
								c=palette[b];
								DrawPixel(sdl_screen,X0+(mx0+mx)*XSCALE,Y0+(my0+my)*YSCALE,c.r<<2, c.g<<2, c.b<<2);
								DrawPixel(sdl_screen,X0+1+(mx0+mx)*XSCALE,Y0+(my0+my)*YSCALE,c.r<<2, c.g<<2, c.b<<2);
								DrawPixel(sdl_screen,X0+1+(mx0+mx)*XSCALE,Y0+1+(my0+my)*YSCALE,c.r<<2, c.g<<2, c.b<<2);
								DrawPixel(sdl_screen,X0+(mx0+mx)*XSCALE,Y0+1+(my0+my)*YSCALE,c.r<<2, c.g<<2, c.b<<2);
							}
						}
				
			}

}

int video_output(void *notused)
{
	uint16_t vga_x,vga_y;
	pal_color_type c;
	static uint8_t init_flag;

	ts.tv_sec=0;
	ts.tv_nsec=10000000;
	 while(!video_stop)
	 	{
#ifndef NO_OGL			
			if((init_flag==0))
			{
				init_flag=1;
					init_opengl();
					glGenTextures(1,&main_texture);
					
			}
#endif
		if(resize)
		{
			resize=0;
			resizeWindow(resize_x,resize_y);
			
		}
		Slock(sdl_screen);
		for(vga_y=0;vga_y<200;vga_y++)
			for(vga_x=0;vga_x<320;vga_x++)
			{
				c=palette[v_buf[vga_x+320*vga_y]];
				DrawPixel(sdl_screen,X0+vga_x*XSCALE,Y0+vga_y*YSCALE,c.r<<2, c.g<<2, c.b<<2);
				DrawPixel(sdl_screen,X0+1+vga_x*XSCALE,Y0+vga_y*YSCALE,c.r<<2, c.g<<2, c.b<<2);
				DrawPixel(sdl_screen,X0+vga_x*XSCALE,Y0+1+vga_y*YSCALE,c.r<<2, c.g<<2, c.b<<2);
				DrawPixel(sdl_screen,X0+1+vga_x*XSCALE,Y0+1+vga_y*YSCALE,c.r<<2, c.g<<2, c.b<<2);
			}

			
		show_cursor();
		Sulock(sdl_screen);
		SDL_Flip(sdl_screen);
#ifndef NO_OGL
	glLoadIdentity();
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT); 	// clear buffers
    glEnable(GL_TEXTURE_2D);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

	glBindTexture(GL_TEXTURE_2D, main_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);   
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, WIDTH, HEIGHT, 0, GL_RGBA,GL_UNSIGNED_BYTE,sdl_screen->pixels );

    glBegin(GL_QUADS);
        glTexCoord2f(0.0,1.0);
        glVertex2f(0.0,0.0);
        glTexCoord2f(1.0,1.0);
        glVertex2f(1.0,0.0);
        glTexCoord2f(1.0,0.0);
        glVertex2f(1.0,1.0);
        glTexCoord2f(0.0,0.0);
        glVertex2f(0.0,1.0);
    glEnd();
    glFlush();
    SDL_GL_SwapBuffers();
#endif		
		nanosleep(ts);
		}
		 video_done=1;
		 nanosleep(ts);
		 SDL_Quit();
		 return 0;
}

int  handle_keys(void *useless)
{
	SDL_Event event;
	while(!video_stop)
	{
    while ( SDL_PollEvent(&event) )
    { 
     	if ( event.type == SDL_QUIT )
     	{
			stop_video_thread();
			 normal_exit=0;
      		 all_done();
      		 SDL_Quit();
      		 exit(4);
     	} 
     	if ( event.type == SDL_KEYDOWN )
     	{
			if(event.key.keysym.sym==SDLK_SCROLLOCK)
			{
				turbo_mode=1;
			} else
			{
				uint8_t key_found;
				key_found=0;
				printf ("SDL_KEYDOWN keysym.sym: %"PRIu16" keysym.mod:%"PRIu16"\t", event.key.keysym.sym, event.key.keysym.mod);
				if (event.key.keysym.sym <= 255)	/* regular ASCII key, process as normal */
				{
					key_found=1;
				}
				else			/* it is extended keycode, check if it is one on our list */
				{
					uint8_t key_index=0;
					while(spec_keys[key_index])
					{
						if(spec_keys[key_index]==event.key.keysym.sym) key_found=2;
						key_index++;
					}
				}
				if (key_found)  /* only return key pressed if it is either regular ASCII key, or extended key we know about */
				{
					keypressed_=1;
					key_=event.key.keysym.sym;
				}
				printf(" END key_found=%"PRIu8" keypressed_=%"PRIu8" key_=%"PRIu16"\r\n", key_found, keypressed_, key_);
			}
		}
		if( event.type == SDL_KEYUP )
		{
			if(event.key.keysym.sym==SDLK_SCROLLOCK)
			{
				turbo_mode=0;
			} 
		}
     	
     	if( event.type == SDL_MOUSEMOTION )
     	{
		  mouse_x = event.motion.x;
		  mouse_y = event.motion.y;
	  	}
		if( event.type == SDL_MOUSEBUTTONDOWN )
		{ //If the left mouse button was pressed
			if( event.button.button == SDL_BUTTON_LEFT )
			{
				mouse_buttons=0x01;
			}
		}
	  	if (event.type == SDL_VIDEORESIZE)
		{
 			resize=1;
 			resize_x=event.resize.w;
 			resize_y=event.resize.h;
		}

		
     }	
		SDL_Delay(20);
//		printf("Keys thread  %d \n",fence);
		
   	}
   	keys_done=1;
   	return 0;
}





void SDL_init_video(uint8_t *vga_buf)
{
	uint16_t x,y;
	
	SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO);
#ifdef NO_OGL	
	sdl_screen=SDL_SetVideoMode(WIDTH,HEIGHT,32,SDL_HWSURFACE|SDL_DOUBLEBUF);
#else
	if(SDL_BYTEORDER == SDL_LIL_ENDIAN){sdl_screen=SDL_CreateRGBSurface(SDL_SWSURFACE,WIDTH,HEIGHT,32,0x000000ff,0x0000ff00,0x00ff0000,0xff000000);}
	else sdl_screen=SDL_CreateRGBSurface(SDL_SWSURFACE,WIDTH,HEIGHT,32,0xff000000,0x00ff0000,0x0000ff00,0x000000ff);
		
	
#endif
	if ( sdl_screen == NULL )
	{
   		printf("Unable to set %dx%d video: %s\n",WIDTH,HEIGHT, SDL_GetError());
   		exit(50);
 	}
 	SDL_ShowCursor(SDL_DISABLE); 
 	Slock(sdl_screen);
	for(y=0;y<HEIGHT;y++)
		for(x=0;x<WIDTH;x++)
		{
			DrawPixel(sdl_screen,x,y,0,0,0);
		}
 	Sulock(sdl_screen);
 	SDL_Flip(sdl_screen);
//		---- copy - paste ----
 	Slock(sdl_screen);
	for(y=0;y<HEIGHT;y++)
		for(x=0;x<WIDTH;x++)
		{
			DrawPixel(sdl_screen,x,y,0,0,0);
		}
 	Sulock(sdl_screen);
 	SDL_Flip(sdl_screen);
//   ------------------------- 	
 	v_buf=vga_buf;
 	video_stop=0;
 	video_done=0;
	video=SDL_CreateThread(video_output,NULL);
	keyshandler=SDL_CreateThread(handle_keys,NULL);

}

void stop_video_thread(void)
{
	video_stop=1;
	while(!video_done) sleep(0);
}

void setrgb256(uint8_t palnum,uint8_t r, uint8_t g,uint8_t b) // set palette
{
	palette[palnum].r=r;
	palette[palnum].g=g;
	palette[palnum].b=b;
}

void getrgb256_(uint8_t palnum,uint8_t *r, uint8_t *g,uint8_t *b)// get palette
{
	*r=palette[palnum].r;
	*g=palette[palnum].g;
	*b=palette[palnum].b;
}

void set256Colors(pal_color_type *pal) // set all palette
{
//	uint16_t i;
//	for(i=0; i<256;i++)
//	{
//		palette[i].r=pal[i].r;
//		palette[i].g=pal[i].g;
//		palette[i].b=pal[i].b;
//	}
	memcpy(palette,pal,256*3);
}

void sdl_mixer_init(void)
{
	audio_rate = 44100;
	audio_format = AUDIO_S16;
	audio_channels = 2;
	audio_buffers = 4096;
	if(Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers))
	{
    	printf("Unable to open audio!\n");
    	exit(123);
  	}
	audio_open = 1;
}

void musicDone(void)
{
  Mix_HaltMusic();
  Mix_FreeMusic(music);
  music = NULL;
}

void play_mod(uint8_t loop,char *filename)
{
	int l;
	
	if(music!=NULL) musicDone();

	music = Mix_LoadMUS(filename);
	/* This begins playing the music - the first argument is a
	   pointer to Mix_Music structure, and the second is how many
	   times you want it to loop (use -1 for infinite, and 0 to
	   have it just play once) */
	if(music==NULL) printf("load music error %s\n",filename);
	if(loop) l=-1; else l=0;
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
	  Mix_HaltMusic();
}


uint64_t delta_usec(void)
{
	uint64_t cur_usec,tmp;
	static uint64_t old_usec;
	struct timeval tv;

	gettimeofday(&tv,NULL);
	cur_usec=tv.tv_sec*1000000L+tv.tv_usec;
	tmp=cur_usec-old_usec;
	old_usec=cur_usec;
	return tmp;
}

void delay(uint16_t ms)
{
	static uint64_t err;
	int64_t us=1;
	struct {
               time_t tv_sec;        /* seconds */
               long   tv_nsec;       /* nanoseconds */
           } ts2;
 	ts2.tv_sec=0;
	ts2.tv_nsec=5000;
	delta_usec();
	us=(ms*1000*TIMESCALE)-err;
	if(turbo_mode) us/=TURBO_FACTOR;
	while(us>0)
	{
		us-=delta_usec();
		nanosleep(ts2);
	}
	err=-us;
	if(video_done && !normal_exit) exit(4);
}

void upscroll(uint8_t *img)
{
	uint16_t y;
	for(y=1;y<100;y++)
	{
		memmove(v_buf+(320*(200-y)),img,320*(y));
		delay(5);
	}
}

void scale_img(uint16_t x0s, uint16_t y0s, uint16_t widths, uint16_t heights, uint16_t x0d, uint16_t y0d, uint16_t widthd, uint16_t heightd, uint8_t *s, uint8_t *d)
{
	uint16_t xd,yd;
	double kx,ky;
	kx=(double)widths/(double)widthd;
	ky=(double)heights/(double)heightd;
	for(yd=0;yd<heightd;yd++)
		for(xd=0;xd<widthd;xd++)
		{
			d[((x0d+xd)+320*(yd+y0d))]=s[(x0s+(uint16_t)(xd*kx)+320*(y0s+(uint16_t)(yd*ky)))];
		}
		
}

void setcolor(uint16_t color)
{
	cur_color=color;
}
void draw_pixel(uint16_t x, uint16_t y)
{
	if(cur_writemode) v_buf[x+320*y]=v_buf[x+320*y] ^ cur_color;
	else v_buf[x+320*y]=cur_color;
}

void circle(uint16_t x, uint16_t y, uint16_t r)
{
	int64_t xx,yy;
	const float E=0.9;
	xx=0;
	yy=r;
		draw_pixel(x+xx,(y+yy*E));
		draw_pixel(x-xx,(y+yy*E));
		draw_pixel(x+xx,(y-yy*E));
		draw_pixel(x-xx,(y-yy*E));
		while(yy>=1)
	{
		yy=yy-1;
		if((xx*xx)+(yy*yy)<(r*r)) 	xx=xx+1;
		if((xx*xx)+(yy*yy)<(r*r)) 	yy=yy+1;
		draw_pixel(x+xx,(y+yy*E));
		draw_pixel(x-xx,(y+yy*E));
		draw_pixel(x+xx,(y-yy*E));
		draw_pixel(x-xx,(y-yy*E));

	}

}

uint8_t key_pressed(void)
{
	uint8_t k;
	struct {
               time_t tv_sec;        /* seconds */
               long   tv_nsec;       /* nanoseconds */
           } ts2;
    ts2.tv_sec=0;
	ts2.tv_nsec=500000;
	k=keypressed_;
//	keypressed=0;
	nanosleep(ts2);
	return k;
	
	
}
uint8_t readkey(void)
{

	struct {
               time_t tv_sec;        /* seconds */
               long   tv_nsec;       /* nanoseconds */
           } ts2;
	static uint8_t null_key,key_index;
	uint8_t key;
	
    if(null_key)
    {
		key=spec_map[key_index];
		null_key=0;
	}
	else
	{
		key_index=0;
		while(spec_keys[key_index])
		{
			if(spec_keys[key_index]==key_)
			{
				null_key=spec_null[key_index];
				break;
			}
			key_index++;
		}
		if(spec_keys[key_index]==0)
		{
			assert (key_ < 256);
			key=(uint8_t)key_;
		}
		else
		{
			if(!null_key) key=spec_map[key_index];
			else key=0;
		}
	}
    ts2.tv_sec=0;
	ts2.tv_nsec=500000;
	keypressed_=0;
	nanosleep(ts2);
	return key;
}

uint8_t readkey_raw(void)
{
	struct {
               time_t tv_sec;        /* seconds */
               long   tv_nsec;       /* nanoseconds */
           } ts2;

    ts2.tv_sec=0;
	ts2.tv_nsec=500000;
	keypressed_=0;
	nanosleep(ts2);
	return key_;
	
}


uint8_t mouse_get_status(void)
{
	uint8_t t;
	t=mouse_buttons;
	mouse_buttons=0;
	return t;
}

int32_t mouse_get_x(void)
{
	int32_t x;
	double rx,rx0;
	if(resize_x==0) return 0;
	rx=(double)(mouse_x)/(double)(resize_x);
	rx0=(double)(wx0)/(double)(resize_x);
	x=WIDTH*((rx-rx0)/(1-2*rx0));
	x=(x-X0)/XSCALE;
	if(x<0) x=0;
	if(x>319) x=319;
	return x;
}

int32_t mouse_get_y(void)
{
	int32_t y;
	double ry,ry0;
	if(resize_y==0) return 0;
	ry=(double)(mouse_y)/(double)(resize_y);
	ry0=(double)(wy0)/(double)(resize_y);
	y=HEIGHT*((ry-ry0)/(1-2*ry0));
	y=(y-Y0)/YSCALE;
	if(y<0) y=0;
	if(y>199) y=199;
	return y;
}


void rectangle(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2 )
{
	uint16_t i;
//	printf("rect : %d %d %d %d  color %d\n",x1,y1,x2,y2,cur_color);
	if(x2>x1) 	for(i=x1;i<x2;i++) { draw_pixel(i,y1); draw_pixel(i,y2);  	}
	else	for(i=x2;i<x1;i++) { draw_pixel(i,y1); draw_pixel(i,y2);  	}
	if(y2>y1) 	for(i=y1;i<y2;i++) { draw_pixel(x1,i); draw_pixel(x2,i);  		}
	else	for(i=y2;i<y1;i++) { draw_pixel(x1,i); draw_pixel(x2,i);  		}
	
	
}

void mousehide(void)
{
	showmouse=0;
}
void mouseshow(void)
{
	showmouse=1;
}
void mousesetcursor(uint8_t *icon)
{
	memcpy(mouse_icon,icon,256);
}

void all_done(void)
{
	musicDone();
	video_stop=1;
	while(!video_done) sleep(0);
	while(!keys_done) sleep(0);
}

void setmodvolumeto(uint16_t vol)
{
	Mix_VolumeMusic(vol/2);
}
void move_mouse(uint16_t x, uint16_t y)
{
	SDL_WarpMouse(x,y);
}


void play_sound(char *filename, uint16_t rate)
{
	
	FILE *f;
	int32_t length,readed,r,i;
	int8_t *sound_raw,chan;
	float k;
	int16_t *sound,smp;
	char *fn,*s,*s1;

	fn=malloc(256);
	s1=strdup(filename);
	s=s1;
	while(*s)
		{
			*s=toupper(*s);
			s++;
		}
	strcpy(fn,SOUNDS_PATH);
	strcat(fn,s1);
	f=fopen(fn,"rb");
	if(f==NULL)
	{
		 printf("Can't open file %s\n",fn);
		 return;
	}
	fseek(f,0,SEEK_END);
	length=ftell(f);
	fseek(f,0,SEEK_SET);
	sound_raw=malloc(length);
	readed=0;
	while(readed<length)
	{
		r=fread(sound_raw+readed,1,length-readed,f);
		if(r>=0) readed+=r;
		else
		{
			printf("Can't read %s @%ld error= %d\n",fn,ftell(f),errno);
			return;
		}
	}
	fclose(f);
	free(fn); free(s1);
// resample and play	
	k=(float)rate/(float)audio_rate;
	sound=calloc(1+(length/k),4);
	for(i=0;i<(length/k);i++)
	{
		smp=(sound_raw[(uint32_t)(i*k)])*SOUNDS_VOLUME;
		sound[i*2]=smp;
		sound[1+i*2]=smp;
//		printf("%d / %d, %d / %d\n\r",i,(uint32_t)(length/k),(int32_t)(i*k),length);
	}
	free(sound_raw);
	chan=-1;
	for(i=0;i<SOUNDS_MAX_CHANNELS;i++)
	{
		if(!Mix_Playing(i))
		{
			if(raw_chunks[i]!=NULL)
			{
				Mix_FreeChunk(raw_chunks[i]);
				raw_chunks[i]=NULL;
			}
			chan=i;
			break;
		}
	}
	if(chan>=0)
	{
		if(!(raw_chunks[chan]=Mix_QuickLoad_RAW((void *)sound, (uint32_t)(length/k)*4)))
		{
	    	printf("Mix_QuickLoad_RAW: %s\n", Mix_GetError());
	    }
	    if(sound!=NULL) free(sound);
	    Mix_PlayChannel(chan,raw_chunks[chan],0);
	}
  	
	
}


void pausemod(void)
{
	Mix_PauseMusic();
}
void continuemod(void)
{
	Mix_ResumeMusic();
	
}


void setfillstyle(uint16_t style, uint16_t f_color)
{
	fill_color=f_color;
	if(style>1) printf("setfillstyle style=%d\n",style);
	
}

void bar(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2 )
{
	uint16_t i,j,x,xe,y,ye;
//	printf("rect : %d %d %d %d  color %d\n",x1,y1,x2,y2,cur_color);
	if(x2>x1) { x=x1; xe=x2;}
	else { x=x2; xe=x1;}
	if(y2>y1) { y=y1; ye=y2;}
	else { y=y2; ye=y1;}
	for(j=y;j<ye;j++)
		for(i=x;i<xe;i++)
			v_buf[i+320*j]=fill_color;
}





void line(int16_t x1,int16_t y1,int16_t x2,int16_t y2)
{
//	printf("%d,%d - %d,%d\n",x1,y1,x2,y2);
	int i,dx,dy,sdx,sdy,dxabs,dyabs,x,y,px,py;
	dx=x2-x1;      // the horizontal distance of the line
	dy=y2-y1;      // the vertical distance of the line
	dxabs=abs(dx);
	dyabs=abs(dy);
	if(dx>0) sdx=1; else sdx=-1;
	if(dy>0) sdy=1; else sdy=-1;
	x=dyabs>>1;
	y=dxabs>>1;
	px=x1;
	py=y1;
	draw_pixel(px, py);
	if (dxabs>=dyabs) { // the line is more horizontal than vertical
		for(i=0;i<dxabs;i++) {
			y+=dyabs;
			if (y>=dxabs) {
				y-=dxabs;
				py+=sdy;
			}
			px+=sdx;
			draw_pixel(px, py);
		}
	}
	else { // the line is more vertical than horizontal
		for(i=0;i<dyabs;i++) {
			x+=dxabs;
			if (x>=dyabs) {
				x-=dyabs;
				px+=sdx;
			}
			py+=sdy;
			draw_pixel( px, py);
		}
	}

    cur_x=x2;
    cur_y=y2;

 }





void moveto(uint16_t x, uint16_t y)
{
	cur_x=x;
	cur_y=y;
}
void lineto(uint16_t x, uint16_t y)
{
	line(cur_x,cur_y,x,y);
}

void pieslice(uint16_t x, uint16_t y, uint16_t phi0, uint16_t phi1, uint16_t r)
{
	int16_t i,j;
	double f,f0,f1;
	const float E=0.9;
	f0=phi0*M_PI/180.0;
	f1=phi1*M_PI/180.0;
	for(j=-r;j<r;j++)
		for(i=-r;i<r;i++)
		{
			f=atan2(j,i);
			if(f<0) f+=2*M_PI;
			if((f>=f0) && (f<f1))
			{
				if((i*i+j*j)<=r*r) v_buf[i+x+320*(y-(int)(j*E))]=fill_color;
			}
		}
}

void setwritemode(uint16_t mode)
{
	cur_writemode=mode;
}

uint8_t playing(void)
{
	return Mix_PlayingMusic();
}
