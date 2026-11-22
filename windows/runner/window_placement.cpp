#include "window_placement.h"

namespace {

constexpr wchar_t kRegistryKey[] = L"Software\\Barnabas\\Absorb";
constexpr wchar_t kRegistryValue[] = L"WindowPlacement";

}  // namespace

bool LoadWindowPlacement(WINDOWPLACEMENT* placement) {
  WINDOWPLACEMENT saved = {};
  DWORD size = sizeof(saved);
  DWORD type = 0;
  const LSTATUS status =
      RegGetValueW(HKEY_CURRENT_USER, kRegistryKey, kRegistryValue,
                   RRF_RT_REG_BINARY, &type, &saved, &size);
  if (status != ERROR_SUCCESS || size != sizeof(saved) ||
      saved.length != sizeof(saved)) {
    return false;
  }
  // A monitor that has since been unplugged would leave the window out of
  // reach, so the default spot is used instead.
  if (MonitorFromRect(&saved.rcNormalPosition, MONITOR_DEFAULTTONULL) ==
      nullptr) {
    return false;
  }
  *placement = saved;
  return true;
}

void SaveWindowPlacement(HWND window) {
  WINDOWPLACEMENT placement = {};
  placement.length = sizeof(placement);
  if (!GetWindowPlacement(window, &placement)) {
    return;
  }
  HKEY key = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kRegistryKey, 0, nullptr, 0,
                      KEY_SET_VALUE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
    return;
  }
  RegSetValueExW(key, kRegistryValue, 0, REG_BINARY,
                 reinterpret_cast<const BYTE*>(&placement), sizeof(placement));
  RegCloseKey(key);
}
