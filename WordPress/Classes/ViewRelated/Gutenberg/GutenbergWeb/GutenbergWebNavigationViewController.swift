import Gutenberg

class GutenbergWebNavigationController: UINavigationController {
    private let gutenbergWebController: GutenbergWebViewController

    var onSave: ((Block) -> Void)?

    init(with post: AbstractPost, block: Block) throws {
        gutenbergWebController = try GutenbergWebViewController(with: post, block: block)
        super.init(rootViewController: gutenbergWebController)
        gutenbergWebController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Due to a bug on iOS 13, presenting a DocumentController on a modally presented controller will result on a crash.
    /// This is a workaround to prevent this crash.
    /// More info: https://stackoverflow.com/questions/58164583/wkwebview-with-the-new-ios13-modal-crash-when-a-file-picker-is-invoked
    ///
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if #available(iOS 13, *),
            let menuViewControllerClass = NSClassFromString("UIDocumentMenuViewController"), // Silence deprecation warning.
            viewControllerToPresent.isKind(of: menuViewControllerClass),
            UIDevice.current.userInterfaceIdiom == .phone
        {
            viewControllerToPresent.popoverPresentationController?.sourceView = gutenbergWebController.view
            viewControllerToPresent.popoverPresentationController?.sourceRect = gutenbergWebController.view.frame
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

extension GutenbergWebNavigationController: GutenbergWebDelegate {
    func webController(controller: GutenbergWebSingleBlockViewController, didPressSave block: Block) {
        onSave?(block)
        dismiss(webController: controller)
    }

    func webControllerDidPressClose(controller: GutenbergWebSingleBlockViewController) {
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
