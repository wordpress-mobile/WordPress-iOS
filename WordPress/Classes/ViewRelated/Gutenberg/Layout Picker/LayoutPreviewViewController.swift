import UIKit
import Aztec
import Gutenberg

class LayoutPreviewViewController: UIViewController {

    @IBOutlet weak var createPageBtn: UIButton!
    @IBOutlet weak var previewContainer: UIView!

    let completion: PageCoordinator.TemplateSelectionCompletion
    let layout: PageTemplateLayout
    private var accentColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.muriel(color: .accent, .shade40)
                } else {
                    return UIColor.muriel(color: .accent, .shade50)
                }
            }
        } else {
            return UIColor.muriel(color: .accent, .shade50)
        }
    }

    private lazy var gutenberg: Gutenberg = {
        return Gutenberg(dataSource: self, extraModules: [])
    }()

    let ghostView: GutenGhostView = {
        let ghost = GutenGhostView()
        ghost.hidesToolbar = true
        return ghost
    }()

    private var defaultBrackgroundColor: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        }
        return .white
    }

    init(layout: PageTemplateLayout, completion: @escaping PageCoordinator.TemplateSelectionCompletion) {
        self.layout = layout
        self.completion = completion
        super.init(nibName: "\(LayoutPreviewViewController.self)", bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Preview", comment: "Title for screen to preview a static content.")
        WPFontManager.loadNotoFontFamily()
        styleButtons()
        setupGutenbergView()
        view.backgroundColor = defaultBrackgroundColor

        configureCloseButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ghostView.startAnimation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ghostView.frame = previewContainer.frame
    }

    override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()
        ghostView.frame = previewContainer.frame
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        ghostView.frame = previewContainer.frame
    }

    private func setupGutenbergView() {
        view.backgroundColor = .white
        gutenberg.rootView.translatesAutoresizingMaskIntoConstraints = false
        gutenberg.rootView.backgroundColor = .basicBackground
        previewContainer.addSubview(gutenberg.rootView)

        previewContainer.leftAnchor.constraint(equalTo: gutenberg.rootView.leftAnchor).isActive = true
        previewContainer.rightAnchor.constraint(equalTo: gutenberg.rootView.rightAnchor).isActive = true
        previewContainer.topAnchor.constraint(equalTo: gutenberg.rootView.topAnchor).isActive = true
        previewContainer.bottomAnchor.constraint(equalTo: gutenberg.rootView.bottomAnchor).isActive = true
    }

    private func styleButtons() {
        createPageBtn.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
        createPageBtn.backgroundColor = accentColor
        createPageBtn.layer.cornerRadius = 8
    }

    private func configureCloseButton() {
        navigationItem.rightBarButtonItem = CollapsableHeaderViewController.closeButton(target: self, action: #selector(closeButtonTapped))
    }

    @IBAction func createPageTapped(_ sender: Any) {
        LayoutPickerAnalyticsEvent.templateApplied(slug: layout.slug)

        dismiss(animated: true) {
            self.completion(self.layout)
        }
    }

    @objc func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension LayoutPreviewViewController: GutenbergBridgeDataSource {
    func gutenbergInitialContent() -> String? {
        return layout.content
    }

    var loadingView: UIView? {
        return ghostView
    }

    func gutenbergInitialTitle() -> String? {
        return nil
    }

    func aztecAttachmentDelegate() -> TextViewAttachmentDelegate {
        return self
    }

    func gutenbergLocale() -> String? {
        return nil
    }

    func gutenbergTranslations() -> [String: [String]]? {
        return nil
    }

    func gutenbergEditorTheme() -> GutenbergEditorTheme? {
        return nil
    }

    var isPreview: Bool {
        return true
    }
}

extension LayoutPreviewViewController: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return nil
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return UIImage()
    }

    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) { }
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) { }
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) { }
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) { }
}
