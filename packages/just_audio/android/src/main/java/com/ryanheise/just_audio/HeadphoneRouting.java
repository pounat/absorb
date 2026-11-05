package com.ryanheise.just_audio;

import android.content.Context;
import android.content.SharedPreferences;
import android.media.AudioDeviceCallback;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.media.AudioPlaybackConfiguration;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/** App-local routing. The selected device must be present before playback starts. */
final class HeadphoneRouting implements MethodChannel.MethodCallHandler {
    private static HeadphoneRouting instance;
    private final AudioManager audioManager;
    private final SharedPreferences preferences;
    private final Set<AudioPlayer> players = new HashSet<>();

    static synchronized HeadphoneRouting get(Context context) {
        if (instance == null) instance = new HeadphoneRouting(context.getApplicationContext());
        return instance;
    }

    private HeadphoneRouting(Context context) {
        audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        preferences = context.getSharedPreferences("absorb_headphones", Context.MODE_PRIVATE);
        if (Build.VERSION.SDK_INT >= 23) {
            audioManager.registerAudioDeviceCallback(new AudioDeviceCallback() {
                @Override
                public void onAudioDevicesAdded(AudioDeviceInfo[] devices) { refreshPlayers(); }

                @Override
                public void onAudioDevicesRemoved(AudioDeviceInfo[] devices) { refreshPlayers(); }
            }, new Handler(Looper.getMainLooper()));
        }
    }

    void register(AudioPlayer player) {
        players.add(player);
        player.applyHeadphoneRouting();
    }

    void unregister(AudioPlayer player) { players.remove(player); }

    boolean isEnabled() { return !selectedKey().isEmpty(); }

    private String selectedKey() { return preferences.getString("device", ""); }

    private static boolean isHeadphoneOutput(AudioDeviceInfo device) {
        switch (device.getType()) {
            case AudioDeviceInfo.TYPE_BLUETOOTH_A2DP:
            case AudioDeviceInfo.TYPE_WIRED_HEADSET:
            case AudioDeviceInfo.TYPE_WIRED_HEADPHONES:
            case AudioDeviceInfo.TYPE_USB_HEADSET:
            case AudioDeviceInfo.TYPE_HEARING_AID:
            case AudioDeviceInfo.TYPE_BLE_HEADSET:
                return true;
            default:
                return false;
        }
    }

    private AudioDeviceInfo[] outputs() {
        return Build.VERSION.SDK_INT >= 23
            ? audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            : new AudioDeviceInfo[0];
    }

    private static String name(AudioDeviceInfo device) {
        CharSequence product = device.getProductName();
        return product == null || product.length() == 0 ? "Headphones" : product.toString();
    }

    private static String key(AudioDeviceInfo device) {
        String address = "";
        if (Build.VERSION.SDK_INT >= 28) {
            try { address = device.getAddress(); } catch (SecurityException ignored) { }
        }
        // Device IDs change after a reconnect. Persist the address or product name instead.
        return device.getType() + ":" + (address.isEmpty() ? name(device) : address);
    }

    AudioDeviceInfo selectedDevice() {
        String wanted = selectedKey();
        if (wanted.isEmpty()) return null;
        for (AudioDeviceInfo device : outputs()) {
            if (isHeadphoneOutput(device) && wanted.equals(key(device))) return device;
        }
        return null;
    }

    private void refreshPlayers() {
        for (AudioPlayer player : new ArrayList<>(players)) player.applyHeadphoneRouting();
    }

    private Map<String, Object> state() {
        Map<String, Object> state = new HashMap<>();
        List<Map<String, Object>> devices = new ArrayList<>();
        for (AudioDeviceInfo device : outputs()) {
            if (!isHeadphoneOutput(device)) continue;
            Map<String, Object> item = new HashMap<>();
            item.put("key", key(device));
            item.put("name", name(device));
            item.put("bluetooth", device.getType() == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP
                || device.getType() == AudioDeviceInfo.TYPE_BLE_HEADSET
                || device.getType() == AudioDeviceInfo.TYPE_HEARING_AID);
            devices.add(item);
        }
        state.put("devices", devices);
        state.put("selectedKey", selectedKey());
        state.put("selectedName", preferences.getString("name", "Headphones"));
        state.put("connected", selectedDevice() != null);
        List<String> reported = new ArrayList<>();
        if (isEnabled() && Build.VERSION.SDK_INT >= 31) {
            try {
                for (AudioPlaybackConfiguration playback : audioManager.getActivePlaybackConfigurations()) {
                    if (playback.getAudioAttributes() == null
                            || playback.getAudioAttributes().getUsage() != android.media.AudioAttributes.USAGE_GAME) continue;
                    AudioDeviceInfo device = playback.getAudioDeviceInfo();
                    if (device == null) continue;
                    String label = device.getType() == AudioDeviceInfo.TYPE_REMOTE_SUBMIX
                        ? "Audio capture" : name(device);
                    if (!reported.contains(label)) reported.add(label);
                }
            } catch (RuntimeException ignored) { /* Routing still works without diagnostics. */ }
        }
        state.put("reportedOutputs", reported);
        return state;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "state":
                    result.success(state());
                    break;
                case "select":
                    String wanted = call.argument("key");
                    if (wanted == null) wanted = "";
                    String label = "";
                    if (!wanted.isEmpty()) {
                        AudioDeviceInfo found = null;
                        for (AudioDeviceInfo device : outputs()) {
                            if (isHeadphoneOutput(device) && wanted.equals(key(device))) {
                                found = device;
                                break;
                            }
                        }
                        if (found == null) {
                            result.error("disconnected", "Connect your headphones and refresh the list.", null);
                            return;
                        }
                        label = name(found);
                    }
                    preferences.edit().putString("device", wanted).putString("name", label).apply();
                    refreshPlayers();
                    result.success(state());
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception error) {
            result.error("routing_error", "Could not change the audio output.", null);
            android.util.Log.e("AbsorbHeadphones", "Audio routing failed", error);
        }
    }
}
