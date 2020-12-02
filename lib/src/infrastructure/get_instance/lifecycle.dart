import 'package:meta/meta.dart';

/// The [GetLifeCycle]
///
/// ```dart
/// class SomeController with GetLifeCycle {
///   SomeController() {
///     configureLifeCycle();
///   }
/// }
/// ```
mixin GetLifeCycle {
  // /// The `configureLifeCycle` works as a constructor for the [GetLifeCycle]
  // ///
  // /// This method must be invoked in the constructor of the implementation
  // void configureLifeCycle() {
  //   if (_initialized) return;
  // }

  /// Called immediately after the widget is allocated in memory.
  /// You might use this to initialize something for the controller.
  void onInit() {}

  /// Called 1 frame after onInit(). It is the perfect place to enter
  /// navigation events, like snackbar, dialogs, or a new route, or
  /// async request.
  void onReady() {}

  /// Called before [onDelete] method. [onClose] might be used to
  /// dispose resources used by the controller. Like closing events,
  /// or streams before the controller is destroyed.
  /// Or dispose objects that can potentially create some memory leaks,
  /// like TextEditingControllers, AnimationControllers.
  /// Might be useful as well to persist some data on disk.
  void onClose() {}

  bool _initialized = false;

  /// Checks whether the controller has already been initialized.
  bool get initialized => _initialized;

  /// Called at the exact moment the widget is allocated in memory.
  /// It uses an internal "callable" type, to avoid any @overrides in subclases.
  /// This method should be internal and is required to define the
  /// lifetime cycle of the subclass.
  @internal
  void onStart() {
    if (_initialized) return;
    onInit();
    _initialized = true;
    Future.delayed(Duration.zero, onReady);
  }

  bool _isClosed = false;

  /// Checks whether the controller has already been closed.
  bool get isClosed => _isClosed;

  // Internal callback that starts the cycle of this controller.
  @internal
  void onDelete() {
    if (_isClosed) return;
    _isClosed = true;
    onClose();
  }
}

/// Allow track difference between GetxServices and GetxControllers
mixin GetxServiceMixin {}
