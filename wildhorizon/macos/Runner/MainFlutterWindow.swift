import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Force the app and window to the front on launch. macOS often refuses
    // to foreground the window after `flutter run`; without this the user
    // sees the build finish but no visible window.
    DispatchQueue.main.async {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
      self.makeKeyAndOrderFront(nil)
      self.orderFrontRegardless()
    }
  }
}
