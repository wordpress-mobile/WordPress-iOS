import UIKit

@objc protocol NoResultsViewControllerDelegate {
    func actionButtonPressed()
}

/// A view to show when there are no results for a given situation.
/// Ex: My Sites > account has no sites; My Sites > all sites are hidden.
/// The image, title, and action button will always show.
/// The subtitle is optional and will only show if provided.
///
@objc class NoResultsViewController: NUXViewController {

    // MARK: - Properties

    @objc weak var delegate: NoResultsViewControllerDelegate?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var actionButton: LoginButton!

    override var sourceTag: SupportSourceTag {
        get {
            if let parent = parent,
                parent.isKind(of: SiteCreationNavigationController.self) {
                return .wpComCreateSiteError
            }
            return super.sourceTag
        }
    }

    // To allow storing values until view is loaded.
    private var titleText: String?
    private var subTitleText: String?
    private var buttonText: String?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }

    /// Public method to provide values for text elements.
    ///
    /// - Parameters:
    ///   - title:       Main descriptive text. Required.
    ///   - buttonTitle: Title of action button. Required.
    ///   - subTitle:    Secondary descriptive text. Optional.
    @objc func configure(title: String, buttonTitle: String, subTitle: String? = nil) {
        titleText = title
        subTitleText = subTitle
        buttonText = buttonTitle
    }

    func hideBackButton() {
        navigationItem.hidesBackButton = true
    }

    /// Use the values provided in the actual elements.
    private func configureView() {

        guard let titleText = titleText,
            let buttonText = buttonText else {
                return
        }

        titleLabel.text = titleText
        subTitleLabel.text = subTitleText
        actionButton?.setTitle(buttonText, for: UIControlState())
        actionButton?.setTitle(buttonText, for: .highlighted)
        actionButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton?.accessibilityIdentifier = accessibilityIdentifier(for: buttonText)
        view.layoutIfNeeded()
    }

    // MARK: - Helpers

    private func accessibilityIdentifier(for string: String) -> String {
        let buttonId = NSLocalizedString("Button", comment: "Appended accessibility identifier for buttons.")
        return "\(string) \(buttonId)"
    }

    // MARK: - Button Handling

    @IBAction func actionButtonPressed(_ sender: Any) {
        delegate?.actionButtonPressed()
    }

}
