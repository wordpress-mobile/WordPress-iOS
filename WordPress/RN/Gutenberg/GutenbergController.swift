
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

        GutenbergBridge.shared.postManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        let props: [AnyHashable: Any] = [
            "initialData": post.content ?? ""]
        view = GutenbergBridge.rootView(with: props)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = post.titleForDisplay()
    }

    @objc private func close(sender: UIBarButtonItem) {
        close(didSave: false)
    }

    private func close(didSave: Bool) {
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
