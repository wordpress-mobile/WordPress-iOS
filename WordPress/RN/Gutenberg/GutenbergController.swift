import CoreServices
import UIKit
import React
import WPMediaPicker

class GutenbergController: UIViewController, PostEditor {

    var onClose: ((Bool, Bool) -> Void)?

    var isOpenedDirectlyForPhotoPost: Bool = false

    let post: AbstractPost
    let gutenberg: Gutenberg

    let navBarManager = PostEditorNavigationBarManager()

    var mediaPickerHelper: GutenbergMediaPickerHelper!

    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var currentBlogCount: Int {
        let service = BlogService(managedObjectContext: mainContext)
        return service.blogCountForAllAccounts()
    }

    var isSingleSiteMode: Bool {
        return currentBlogCount <= 1 || post.hasRemote()
    }

    required init(post: AbstractPost) {
        guard let post = post as? Post else {
            fatalError()
        }
        self.post = post
        self.gutenberg = Gutenberg(props: ["initialData": post.content ?? ""])
        super.init(nibName: nil, bundle: nil)

        mediaPickerHelper = GutenbergMediaPickerHelper(context: self, post: post)
        navBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        gutenberg.invalidate()
    }

    override func loadView() {
        view = gutenberg.rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        reloadBlogPickerButton()
        gutenberg.delegate = self
    }

    func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.accessibilityIdentifier = "Gutenberg Editor Navigation Bar"
        navigationItem.leftBarButtonItems = navBarManager.leftBarButtonItems
        navigationItem.rightBarButtonItems = navBarManager.rightBarButtonItems
    }

    func reloadBlogPickerButton() {
        var pickerTitle = post.blog.url ?? String()
        if let blogName = post.blog.settings?.name, blogName.isEmpty == false {
            pickerTitle = blogName
        }

        navBarManager.reloadBlogPickerButton(with: pickerTitle, enabled: !isSingleSiteMode)
    }

    @objc private func close(sender: UIBarButtonItem) {
        close(didSave: false)
    }

    private func close(didSave: Bool) {
        onClose?(didSave, false)
    }
}

extension GutenbergController {
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

extension GutenbergController: GutenbergBridgeDelegate {

    func gutenbergDidRequestMediaPicker(callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       dataSourceType: .mediaLibrary,
                                                       callback: callback)
    }

    func gutenbergDidProvideHTML(_ html: String) {

    }
}

extension GutenbergController: PostEditorNavigationBarManagerDelegate {
    var publishButtonText: String {
        return "Publish"
    }

    var isPublishButtonEnabled: Bool {
        return true
    }

    var uploadingButtonSize: CGSize {
        return AztecPostViewController.Constants.uploadingButtonSize
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton) {
        close(didSave: false)
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {

    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, blogPickerWasPressed sender: UIButton) {

    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        gutenberg.requestHTML()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {

    }
}
