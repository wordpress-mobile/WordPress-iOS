import UIKit

@objc class NoSitesView: UIView {

    // MARK: - Properties

    @IBOutlet weak var noSitesImage: UIImageView!
    @IBOutlet weak var noSitesTitle: UILabel!
    @IBOutlet weak var addSiteButton: LoginButton!

    // MARK: - Init

     @objc class func instanceFromNib() -> NoSitesView {
        return UINib(nibName: "NoSitesView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! NoSitesView
    }

    // MARK: - Configuration

    @objc func configureViewForFrame(_ viewFrame: CGRect) {

        configureElements()

        let frameWidth = viewFrame.size.width
        let frameHeight = viewFrame.size.height

        var newFrame = viewFrame

        if frameHeight > frameWidth {
            newFrame.size.width = frameWidth
            newFrame.size.height = frameWidth
        }
        else {
            newFrame.size.width = frameHeight
            newFrame.size.height = frameHeight
        }

        frame = newFrame
        noSitesTitle.preferredMaxLayoutWidth = frame.size.width - 40
    }

    func configureElements() {
        noSitesTitle.text = NSLocalizedString("Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.", comment: "Text shown when the account has no sites.")
        let buttonTitle = NSLocalizedString("Add new site", comment: "Title of button to add a new site.")
        addSiteButton?.setTitle(buttonTitle, for: UIControlState())
        addSiteButton?.setTitle(buttonTitle, for: .highlighted)
        addSiteButton?.accessibilityIdentifier = "Add New Site Button"
    }

}
