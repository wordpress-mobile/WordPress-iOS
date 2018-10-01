import Foundation
import UIKit
import Aztec


// MARK: - UnknownEditorViewController
//
class UnknownEditorViewController: UIViewController {

    /// Save Bar Button
    ///
    fileprivate(set) var saveButton: UIBarButtonItem = {
        let saveTitle = NSLocalizedString("Save", comment: "Save Action")
        return UIBarButtonItem(title: saveTitle, style: .plain, target: self, action: #selector(saveWasPressed))
    }()

    /// Cancel Bar Button
    ///
    fileprivate(set) var cancelButton: UIBarButtonItem = {
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel Action")
        return UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelWasPressed))
    }()

    /// HTML Editor
    ///
    fileprivate(set) var editorView: UITextView!

    /// Raw HTML To Be Edited
    ///
    fileprivate let attachment: HTMLAttachment

    /// Unmodified HTML Text
    ///
    fileprivate let pristinePrettyHTML: String

    /// Closure to be executed whenever the user saves changes performed on the document
    ///
    var onDidSave: ((String) -> Void)?

    /// Closure to be executed whenever the user cancels edition
    ///
    var onDidCancel: (() -> Void)?



    /// Default Initializer
    ///
    /// - Parameter rawHTML: HTML To Be Edited
    ///
    init(attachment: HTMLAttachment) {
        self.attachment = attachment
        self.pristinePrettyHTML = attachment.prettyHTML()
        super.init(nibName: nil, bundle: nil)
    }


    /// Overriden Initializers
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError("You should use the `init(rawHTML:)` initializer!")
    }


    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupEditorView()
        setupMainView()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        editorView.becomeFirstResponder()
    }
}


// MARK: - Private Helpers
//
private extension UnknownEditorViewController {

    func setupNavigationBar() {
        title = NSLocalizedString("Unknown HTML", comment: "Title for Unknown HTML Editor")
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton

        saveButton.isEnabled = false
    }

    func setupEditorView() {
        let storage = HTMLStorage(defaultFont: Constants.defaultContentFont)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)

        editorView = UITextView(frame: .zero, textContainer: container)
        editorView.accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        editorView.accessibilityIdentifier = "HTMLContentView"
        editorView.autocorrectionType = .no
        editorView.delegate = self
        editorView.translatesAutoresizingMaskIntoConstraints = false
        editorView.text = pristinePrettyHTML
        editorView.contentInset = Constants.defaultContentInsets
    }

    func setupMainView() {
        view.addSubview(editorView)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            editorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            editorView.topAnchor.constraint(equalTo: view.topAnchor),
            editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: - UITextViewDelegate
extension UnknownEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        saveButton.isEnabled = textView.text != pristinePrettyHTML
    }
}

// MARK: - Actions
//
extension UnknownEditorViewController {

    @IBAction func cancelWasPressed() {
        onDidCancel?()
    }

    @IBAction func saveWasPressed() {
        onDidSave?(editorView.text)
    }
}


// MARK: - Constants
//
extension UnknownEditorViewController {

    struct Constants {
        static let defaultContentFont = UIFont.systemFont(ofSize: 14)
        static let defaultContentInsets = UIEdgeInsets.init(top: 0, left: 5, bottom: 0, right: -5)
    }
}
