import Foundation

extension Bundle {
    /// Returns the `Bundle` for the host `.app`.
    ///
    /// - If this is called from code already located in the main app's bundle or from a Pod/Framework,
    ///   this will return the same as `Bundle.main`, aka the bundle of the app itself.
    /// - If this is called from an App Extension (Widget, ShareExtension, etc), this will return the bundle of the
    ///   main app hosting said App Extension (while `Bundle.main` would return the App Extension itself)
    ///
    /// This is particularly useful to reference a resource or string bundled inside the app from an App Extension / Widget.
    ///
    /// - Note:
    ///   In the context of Unit Tests this will return the Test Harness (aka Test Host) app, since that is the app running said tests.
    ///
    static let app: Bundle = {
        var url = Bundle.main.bundleURL
        while url.pathExtension != "app" && url.lastPathComponent != "/" {
            url.deleteLastPathComponent()
        }
        guard let appBundle = Bundle(url: url) else { fatalError("Unable to find the parent app bundle") }
        return appBundle
    }()
}
