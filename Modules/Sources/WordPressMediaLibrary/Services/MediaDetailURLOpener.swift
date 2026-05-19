import Foundation

/// App-injected opener for the URL row on the V2 detail screen. App-target
/// implementation wraps `WebViewControllerFactory.controller(url:blog:source:)`
/// and pushes onto the resolved nav controller.
@MainActor
public protocol MediaDetailURLOpener: AnyObject {
    func open(_ url: URL, mediaTitle: String?)
}
