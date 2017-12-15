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

        var newFrame = superview.frame

        // If horizontal compact, limit the height so the view isn't stretched out.
        if traitCollection.horizontalSizeClass == .compact {
            newFrame.size.height = superview.frame.size.width
        }
        // If vertical compact, reduce the height.
        else if traitCollection.verticalSizeClass == .compact {
            newFrame.size.height = superview.frame.size.height/2
        }

        // Set the width on the label so it wraps properly.
        noSitesTitle.preferredMaxLayoutWidth = newFrame.size.width -
            titleLeadingConstraint.constant -
            titleTrailingConstraint.constant

        frame = newFrame
    }

    // MARK: - Button Handling

    @IBAction func addSiteButtonPressed(_ sender: Any) {
        delegate?.addSiteButtonPressed()
    }

}
