// Waits until the mouse crosses a horizontal band, then prints where it
// went and exits. sketchybar only reports mouse.entered/exited for a
// whole item window (the full popup height), so this tells a band
// inside that window apart, such as a slider's strip.
//
// While the left button is held after a press inside the band, it also
// mirrors the drag onto a slider item, `sketchybar --set <item>
// slider.percentage=<n>`, so a slider drawn elsewhere follows live.
//
// usage: mouse_band <bx> <by> <bw> <bh> <cx> <cy> <cw> <ch> <inside> <item>
//   b*: the band, c*: the window around it, both in screen points
//   (top-left origin); inside: 1 when the mouse is in the band now;
//   item: the slider to mirror a drag onto.
// prints: "in" or "out" when the mouse crosses the band's edge, "gone"
// when it leaves the window, "timeout" after 60 s without either.
#include <ApplicationServices/ApplicationServices.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char** argv) {
  if (argc != 11) return 1;
  CGRect band = CGRectMake(atof(argv[1]), atof(argv[2]), atof(argv[3]), atof(argv[4]));
  CGRect window = CGRectMake(atof(argv[5]), atof(argv[6]), atof(argv[7]), atof(argv[8]));
  bool inside = atoi(argv[9]);
  const char* item = argv[10];

  bool was_down = CGEventSourceButtonState(kCGEventSourceStateCombinedSessionState, kCGMouseButtonLeft);
  bool dragging = false;
  int last_percent = -1;

  for (int tick = 0; tick < 60 * 100; tick++) {
    CGEventRef event = CGEventCreate(NULL);
    CGPoint point = CGEventGetLocation(event);
    CFRelease(event);
    bool down = CGEventSourceButtonState(kCGEventSourceStateCombinedSessionState, kCGMouseButtonLeft);

    if (down && !was_down && CGRectContainsPoint(band, point)) dragging = true;
    if (!down) dragging = false;
    was_down = down;

    if (dragging) {
      // Same rounding as sketchybar's slider.
      float delta = point.x - band.origin.x;
      if (delta < 0) delta = 0;
      int percent = (int)(delta / band.size.width * 100.f + 0.5f);
      if (percent > 100) percent = 100;
      if (percent != last_percent) {
        char command[256];
        snprintf(command, sizeof(command), "sketchybar --set '%s' slider.percentage=%d", item, percent);
        system(command);
        last_percent = percent;
      }
      usleep(10000);
      continue;
    }

    if (!CGRectContainsPoint(window, point)) {
      puts("gone");
      return 0;
    }
    if (CGRectContainsPoint(band, point) != inside) {
      puts(inside ? "out" : "in");
      return 0;
    }
    usleep(10000);
  }
  puts("timeout");
  return 0;
}
