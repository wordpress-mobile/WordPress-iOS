
import Foundation
import React

class GutenbergBridge {
    let rnBridge: RCTBridge
    let postManager: GBPostManager
    let mediaProvider: MediaProvider

    static var shared: GutenbergBridge {
        guard let bridge = _shared else {
            fatalError("RN Bridge not initialized")
        }
        return bridge
    }

    private static var _shared: GutenbergBridge?

    static func start(with launchOptions: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            _shared = GutenbergBridge(options: launchOptions)
        }
    }

    private init(options launchOptions: [AnyHashable: Any]?) {
        let bDelegate = bridgeDelegate
        postManager = bDelegate.postManager
        mediaProvider = bDelegate.mediaProvider

        rnBridge = RCTBridge(delegate: bDelegate, launchOptions: launchOptions)
    }

    private var bridgeDelegate: BridgeDelegate = {
        let mediaProvider = MediaProvider()

        let sourceURL = RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index", fallbackResource: nil)!
        return BridgeDelegate(sourceURL: sourceURL, mediaProvider: mediaProvider)
    }()
}
