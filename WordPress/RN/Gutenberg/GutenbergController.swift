
import UIKit
import React

class GutenbergController: UIViewController, PostEditor {
    var onClose: ((Bool, Bool) -> Void)?

    var isOpenedDirectlyForPhotoPost: Bool = false

    let post: AbstractPost

    required init(post: AbstractPost) {
        guard let post = post as? Post else {
            fatalError()
        }
        self.post = post
        super.init(nibName: nil, bundle: nil)

        GutenbergBridge.shared.mediaProvider.post = post
        GutenbergBridge.shared.postManager.delegate = self
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
        addCancelButton()
        title = post.titleForDisplay()
    }

    private func addCancelButton() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(close(sender:)))
        navigationItem.rightBarButtonItem = cancelButton
    }

    @objc private func close(sender: UIBarButtonItem) {
        close(didSave: false)
    }

    private func close(didSave: Bool) {
        GutenbergBridge.shared.mediaProvider.post = nil
        GutenbergBridge.shared.postManager.delegate = nil
        onClose?(didSave, false)
    }
}

extension GutenbergController: GBPostManagerDelegate {
    func closeButtonPressed() {
        close(didSave: false)
    }

    func saveButtonPressed(with content: String) {
        guard let post = post as? Post else {
            return
        }
        post.content = content
        PostCoordinator.shared.save(post: post)
        DispatchQueue.main.async { [weak self] in
            self?.close(didSave: true)
        }
    }
}
