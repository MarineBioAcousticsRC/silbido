#include <utSharedLib.h>

static void	*Slots[MAXSHAREDSEGMENTS];


void * get(int n) {
  return (n >= 0 && n < MAXSHAREDSEGMENTS) ? Slots[n] : 0;
}

void set(int n, void *Value) {
  if (n >= 0 && n < MAXSHAREDSEGMENTS)
    Slots[n] = Value;
}
