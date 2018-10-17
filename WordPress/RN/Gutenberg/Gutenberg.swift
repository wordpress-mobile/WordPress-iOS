
import UIKit
import React

class GutenbergController: UIViewController {

    private let initialHTML: String
    private let mediaProvider = MediaProvider()
    private lazy var bridge: RCTBridge = {
        return RCTBridge(delegate: bridgeDelegate, launchOptions: nil)
    }()

    private lazy var bridgeDelegate: BridgeDelegate = {
        let sourceURL = RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index", fallbackResource: nil)!
        return BridgeDelegate(sourceURL: sourceURL, mediaProvider: mediaProvider)
    }()

    init(html: String) {
        initialHTML = html
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        initialHTML = ""
        super.init(coder: aDecoder)
    }

    override func loadView() {
        let props = ["html": initialHTML]
        view = RCTRootView(bridge: bridge, moduleName: "gutenberg", initialProperties: props)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addDismissButton()
    }

    private func addDismissButton() {
        let dismissButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(dismiss))
        navigationItem.leftBarButtonItem = dismissButton
    }

    @objc private func dismiss(sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
