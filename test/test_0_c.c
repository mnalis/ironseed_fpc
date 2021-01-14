#include "../c_utils.c"

static fpc_screentype_t pas_screen;
int main (int argc, char *argv[])
{
	int x1, x2, y1, y2;
	int count = 0;

	printf ("main start\n");
	pas_screen = calloc(320,200); assert (pas_screen);
	setrgb256(31,60,10,20);
	srand(123);

	printf ("allocated\n");
	SDL_init_video(pas_screen, 0);
	printf ("main after SDL_init_video\n");

	while ((!is_video_finished) && (count++<10)) {
		SDL_Delay(1000);
		x1 = rand() % 320; x2 = rand() % 320; y1 = rand() % 200; y2 = rand() % 200;
		printf ("line%d from %d,%d to %d,%d...\n", count, x1, y1, x2, y2);
		line ((fpc_word_t) x1, (fpc_word_t) y1, (fpc_word_t) x2, (fpc_word_t) y2);
	}
	printf ("main end\n");
	return 0;
}
