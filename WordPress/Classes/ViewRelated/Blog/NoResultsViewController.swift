import UIKit

@objc protocol NoResultsViewControllerDelegate {
    func actionButtonPressed()
}

/// A view to show when there are no results for a given situation.
/// Ex: My Sites > account has no sites; My Sites > all sites are hidden.
/// The image, title, and action button will always show.
/// The subtitle is optional and will only show if provided.
///
@objc class NoResultsViewController: UIViewController {

    // MARK: - Properties

    @objc weak var delegate: NoResultsViewControllerDelegate?
    @IBOutlet weak var noResultsImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var actionButton: LoginButton!

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: view, andTableView: nil)
    }

    /// Configures the view with the given information.
    ///
    /// - Parameters:
    ///   - title:       Main descriptive text. Required.
    ///   - buttonTitle: Title of action button. Required.
    ///   - subTitle:    Secondary descriptive text. Optional.
    @objc func configure(title: String, buttonTitle: String, subTitle: String? = nil) {
        titleLabel.text = title
        subTitleLabel.text = subTitle
        actionButton?.setTitle(buttonTitle, for: UIControlState())
        actionButton?.setTitle(buttonTitle, for: .highlighted)
        actionButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton?.accessibilityIdentifier = buttonTitle + " Button"
    }

    // MARK: - Button Handling

    @IBAction func actionButtonPressed(_ sender: Any) {
        delegate?.actionButtonPressed()
    }

}
