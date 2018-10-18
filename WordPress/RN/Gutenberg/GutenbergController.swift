
import UIKit
import React

@objc (GBPostManager)
public class GBPostManager: NSObject, RCTBridgeModule {
    public static func moduleName() -> String! {
        return "GBPostManager"
    }

    var post: Post?
    @objc(savePost:)
    func savePost(with content: String) {
        print("NewContent: ")
        print(content)
        print(post)
    }

    public static func requiresMainQueueSetup() -> Bool {
        return false
    }
}

class GutenbergController: UIViewController {

    private let post: Post

    init(post: Post) {

        self.post = post
        GutenbergBridge.shared.postManager.post = post

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        let props: [AnyHashable: Any] = [
            "initialData": post.content ?? ""]
        let bridge = GutenbergBridge.shared
        view = RCTRootView(bridge: bridge.rnBridge, moduleName: "gutenberg", initialProperties: props)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addSaveButton()
        addCancelButton()
        title = post.titleForDisplay()
    }

    private func addSaveButton() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(save))
        navigationItem.leftBarButtonItem = doneButton
    }

    private func addCancelButton() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = cancelButton
    }

    @objc private func save(sender: UIBarButtonItem) {
        close(sender: sender)
    }

    @objc private func close(sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
