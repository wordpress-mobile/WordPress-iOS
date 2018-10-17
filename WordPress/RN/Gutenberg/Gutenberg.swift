
import UIKit
import React

class GutenbergController: UIViewController {

    private let mediaProvider = MediaProvider()

    private lazy var bridgeDelegate: BridgeDelegate = {
        let sourceURL = RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index", fallbackResource: nil)!

        return BridgeDelegate(sourceURL: sourceURL, mediaProvider: MediaProvider())
    }()

    init(html: String) {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func loadView() {
        let bridge = RCTBridge(delegate: bridgeDelegate, launchOptions: nil)
        view = RCTRootView(bridge: bridge, moduleName: "gutenberg", initialProperties: nil)
    }
}
