import 'package:flutter_chrome_cast/entities/cast_session.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/enums/connection_state.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// <p>A class that manages sessions. </p>
/// <p>The method <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_session_manager#a211d476c2e9b265ed7510d12f4b29c02">startSessionWithDevice: (GCKSessionManager)</a> is used to create a new session with a given <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_device" data-title="An object representing a receiver device. ">GCKDevice</a>. The session manager uses the <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_device_provider" data-title="An abstract base class for performing device discovery and session construction. ">GCKDeviceProvider</a> for that device type to construct a new <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_session" data-title="An abstract base class representing a session with a receiver device. ">GCKSession</a> object, to which it then delegates all session requests.</p>
/// <p><a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_session_manager" data-title="A class that manages sessions. ">GCKSessionManager</a> handles the automatic resumption of suspended sessions (that is, resuming sessions that were ended when the application went to the background, or in the event that the application crashed or was forcibly terminated by the user). When the application resumes or restarts, the session manager will wait for a short time for the device provider of the suspended session's device to discover that device again, and if it does, it will attempt to reconnect to that device and re-establish the session automatically.</p>
/// <p>If the application has created a <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_u_i_cast_button" data-title="A subclass of UIButton that implements a &quot;Cast&quot; button. ">GCKUICastButton</a> without providing a target and selector, then a user tap on the button will display the default Cast dialog and it will automatically start and stop sessions based on user selection or disconnection of a device. If however the application is providing its own device selection/control dialog UI, then it should use the <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_session_manager" data-title="A class that manages sessions. ">GCKSessionManager</a> directly to create and control sessions.</p>
/// <p>Whether or not the application uses the <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_session_manager" data-title="A class that manages sessions. ">GCKSessionManager</a> to control sessions, it can attach a <a class="el notranslate" href="/cast/docs/reference/ios/protocol_g_c_k_session_manager_listener-p" data-title="The GCKSessionManager listener protocol. ">GCKSessionManagerListener</a> to be notified of session events, and can also use KVO to monitor the <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_session_manager#a8b48906a8910f328343e2260e6bef6a0" data-title="The current session connection state. ">connectionState</a> property to track the current session lifecycle state.</p>
/// <dl class="section since"><dt>Since</dt><dd>3.0 </dd></dl>

abstract class GoogleCastSessionManagerPlatformInterface
    extends PlatformInterface {
  /// Creates a new [GoogleCastSessionManagerPlatformInterface].
  GoogleCastSessionManagerPlatformInterface({required super.token});

  /// Tests if a session is currently being managed by this session manager, and it is currently connected.

  /// This will be YES if the session state is ConnectionStateConnected.
  bool get hasConnectedSession;

  /// The current session, if any.
  GoogleCastSession? get currentSession;

  /// Stream of current session changes.
  Stream<GoogleCastSession?> get currentSessionStream;

  /// 	readnonatomicassign

  /// The current session connection state.

  GoogleCastConnectState get connectionState;

  /// Starts a new session with the given device, using the default session options that were registered for the device category, if any.

  /// This is an asynchronous operation.

  /// Parameters
  ///     device	The device to use for this session.

  /// Returns
  ///     YES if the operation has been started successfully, NO if there is a session currently established or if the operation could not be started.
  Future<bool> startSessionWithDevice(GoogleCastDevice device);

  /// Attempts to join or start a session with options that were supplied to the UIApplicationDelegate::application:openURL:options: method.

  /// Typically this is a request to join an existing Cast session on a particular device that was initiated by another app.

  /// Parameters
  ///     openURLOptions	The options that were extracted from the URL.
// /    sessionOptions	The options for this session, if any. May be nil.

// Returns
//     YES if the operation has been started successfully, NO if there is a session currently established, or the openURL options do not contain the required Cast options.

// Since
//     4.0

  Future<bool> startSessionWithOpenURLOptions();

  /// Suspends the current session.

  /// This is an asynchronous operation.

  /// Parameters
  ///
  ///     reason	The reason for the suspension.

  /// Returns
  ///     YES if the operation has been started successfully, NO if there is no session currently established or if the operation could not be started.

  Future<bool> suspendSessionWithReason();

  ///Ends the current session.

  /// This is an asynchronous operation.

  /// Returns
  ///     YES if the operation has been started successfully, NO if there is no session currently established or if the operation could not be started.

  Future<bool> endSession();

  /// Ends the current session and stops casting if one sender device is connected; otherwise, optionally stops casting if multiple sender devices are connected.

  /// Use the stopCasting parameter to indicate whether casting on the receiver should stop when the session ends. This parameter only applies when multiple sender devices are connected. For example, the same app is open on multiple sender devices and each sender device has an active Cast session with the same receiver device.

  ///     If you set stopCasting to YES, the receiver app stops casting when multiple devices are connected.
  ///     If stopCasting is NO and other devices have an active session, the receiver keeps playing.
  ///     If only one sender device is connected, the receiver app stops casting the media and ignores the stopCasting value, even if it's set to NO.

  /// Parameters
  ///     stopCasting	Whether casting on the receiver should stop when the session ends. Only used when multiple sender devices are connected.

  /// Returns
  ///     YES if the operation to end the session started successfully, NO if there is no session currently established or if the operation could not be started.

  Future<bool> endSessionAndStopCasting();

  /// Sets the default session options for devices in a specific category (iOS only).
  ///
  /// This method is only available on iOS platforms and works with GCKSessionOptions.
  /// Use this to configure default session behavior for specific device categories.
  ///
  /// Implementation note:
  /// For native iOS, this maps to:
  /// - sessionOptions: nullable GCKSessionOptions
  /// - forDeviceCategory: (NSString *) category
  Future<void> setDefaultSessionOptions(
      // nullable GCKSessionOptions *\tsessionOptions
      // forDeviceCategory: \t\t(NSString *)  \tcategory
      );

  /// Sets the device volume.
  void setDeviceVolume(double value);
}
