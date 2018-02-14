import UIKit

@objc protocol NoResultsViewControllerDelegate {
    @objc optional func actionButtonPressed()
    @objc optional func dismissButtonPressed()
}

/// A view to show when there are no results for a given situation.
/// Ex: My Sites > account has no sites; My Sites > all sites are hidden.
/// The image and title will always show.
/// The action button is shown by default, but will be hidden if button title is not provided.
/// The subtitle is optional and will only show if provided.
///
@objc class NoResultsViewController: NUXViewController {

    // MARK: - Properties

    @objc weak var delegate: NoResultsViewControllerDelegate?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var actionButton: LoginButton!

    // To allow storing values until view is loaded.
    private var titleText: String?
    private var subtitleText: String?
    private var buttonText: String?
    private var imageName: String?

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
    ///   - buttonTitle: Title of action button. Optional.
    ///   - subtitle:    Secondary descriptive text. Optional.
    ///   - image:       Name of image file to use. Optional.
    @objc func configure(title: String, buttonTitle: String? = nil, subtitle: String? = nil, image: String? = nil) {
        titleText = title
        subtitleText = subtitle
        buttonText = buttonTitle
        imageName = image
    }

    /// Public method to show a 'Dismiss' button in the navigation bar in place of the 'Back' button.
    func showDismissButton() {
        navigationItem.hidesBackButton = true

        let dismissButton = UIBarButtonItem(title: NSLocalizedString("Dismiss", comment: "Dismiss button title."),
                                            style: .done,
                                            target: self,
                                            action: #selector(self.dismissButtonPressed))
        dismissButton.accessibilityLabel = NSLocalizedString("Dismiss", comment: "Dismiss button title.")
        navigationItem.leftBarButtonItem = dismissButton
    }

    /// Use the values provided in the actual elements.
    private func configureView() {

        guard let titleText = titleText else {
                return
        }

        titleLabel.text = titleText
        subtitleLabel.text = subtitleText

        if let buttonText = buttonText {
            actionButton?.setTitle(buttonText, for: UIControlState())
            actionButton?.setTitle(buttonText, for: .highlighted)
            actionButton?.titleLabel?.adjustsFontForContentSizeCategory = true
            actionButton?.accessibilityIdentifier = accessibilityIdentifier(for: buttonText)
        } else {
            actionButton.isHidden = true
        }

        if let imageName = imageName {
            imageView.image = UIImage(named: imageName)
        }

        view.layoutIfNeeded()
    }

    // MARK: - Helpers

    private func accessibilityIdentifier(for string: String) -> String {
        let buttonIdFormat = NSLocalizedString("%@ Button", comment: "Accessibility identifier for buttons.")
        return String(format: buttonIdFormat, string)
    }

    // MARK: - Button Handling

    @IBAction func actionButtonPressed(_ sender: Any) {
        delegate?.actionButtonPressed?()
    }

    @objc func dismissButtonPressed() {
        delegate?.dismissButtonPressed?()
    }

}
