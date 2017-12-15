import UIKit

@objc protocol NoSitesViewDelegate {
    func addSiteButtonPressed()
}

@objc class NoSitesView: UIView {

    // MARK: - Properties

    @objc weak var delegate: NoSitesViewDelegate?

    @IBOutlet weak var noSitesTitle: UILabel!
    @IBOutlet weak var addSiteButton: LoginButton!
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTrailingConstraint: NSLayoutConstraint!

    // MARK: - Init

    @objc class func instanceFromNib() -> NoSitesView {
        let view = UINib(nibName: "NoSitesView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! NoSitesView
        view.configureElements()
        return view
    }

    // MARK: - Configuration

    private func configureElements() {
        noSitesTitle.text = NSLocalizedString("Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.", comment: "Text shown when the account has no sites.")
        let buttonTitle = NSLocalizedString("Add new site", comment: "Title of button to add a new site.")
        addSiteButton?.setTitle(buttonTitle, for: UIControlState())
        addSiteButton?.setTitle(buttonTitle, for: .highlighted)
        addSiteButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        addSiteButton?.accessibilityIdentifier = "Add New Site Button"
    }

    // MARK: - Orientation Handling

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {

        super.traitCollectionDidChange(previousTraitCollection)

        guard let superview = superview else {
            return
        }

        translatesAutoresizingMaskIntoConstraints = false

        // Set the width on the label so it wraps properly.
        noSitesTitle.preferredMaxLayoutWidth = superview.frame.size.width -
            titleLeadingConstraint.constant -
            titleTrailingConstraint.constant

        frame = superview.frame
    }

    // MARK: - Button Handling

    @IBAction func addSiteButtonPressed(_ sender: Any) {
        delegate?.addSiteButtonPressed()
    }

}
