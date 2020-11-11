import Gutenberg

class GutenbergWebNavigationController: UINavigationController {
    private let gutenbergWebController: GutenbergWebViewController
    private let blockName: String

    var onSave: ((Block) -> Void)?

    init(with post: AbstractPost, block: Block) throws {
        gutenbergWebController = try GutenbergWebViewController(with: post, block: block)
        blockName = block.name
        super.init(nibName: nil, bundle: nil)
        viewControllers = [gutenbergWebController]
        gutenbergWebController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPAnalytics.track(.gutenbergUnsupportedBlockWebViewShown, properties: ["block": blockName])
    }

    /// Due to a bug on iOS 13, presenting a DocumentController on a modally presented controller will result on a crash.
    /// This is a workaround to prevent this crash.
    /// More info: https://stackoverflow.com/questions/58164583/wkwebview-with-the-new-ios13-modal-crash-when-a-file-picker-is-invoked
    ///
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        defer {
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }

        guard
            #available(iOS 13, *),
            let menuViewControllerClass = NSClassFromString("UIDocumentMenuViewController"), // Silence deprecation warning.
            viewControllerToPresent.isKind(of: menuViewControllerClass),
            UIDevice.current.userInterfaceIdiom == .phone
        else {
            return
        }

        viewControllerToPresent.popoverPresentationController?.sourceView = gutenbergWebController.view
        viewControllerToPresent.popoverPresentationController?.sourceRect = gutenbergWebController.view.frame
    }

    private func trackWebViewClosed(action: String) {
        WPAnalytics.track(.gutenbergUnsupportedBlockWebViewClosed, properties: ["action": action])
    }
}

extension GutenbergWebNavigationController: GutenbergWebDelegate {
    func webController(controller: GutenbergWebSingleBlockViewController, didPressSave block: Block) {
        onSave?(block)
        trackWebViewClosed(action: "save")
        dismiss(webController: controller)
    }

    func webControllerDidPressClose(controller: GutenbergWebSingleBlockViewController) {
        trackWebViewClosed(action: "dismiss")
        dismiss(webController: controller)
    }

    func webController(controller: GutenbergWebSingleBlockViewController, didLog log: String) {
        DDLogVerbose(log)
    }

    private func dismiss(webController: GutenbergWebSingleBlockViewController) {
        webController.cleanUp()
        presentingViewController?.dismiss(animated: true)
    }
}
