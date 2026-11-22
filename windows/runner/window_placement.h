#ifndef RUNNER_WINDOW_PLACEMENT_H_
#define RUNNER_WINDOW_PLACEMENT_H_

#include <windows.h>

// Where the window was when it was last closed, kept per user in the
// registry: its size, its position, which also says which monitor, and
// whether it was maximized.

// Fills |placement| with the saved one. False when there is none, or when
// the monitor it was on is no longer there.
bool LoadWindowPlacement(WINDOWPLACEMENT* placement);

void SaveWindowPlacement(HWND window);

#endif  // RUNNER_WINDOW_PLACEMENT_H_
