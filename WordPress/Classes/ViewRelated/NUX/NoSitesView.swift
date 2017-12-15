import UIKit

@objc protocol NoSitesViewDelegate {
    func addSiteButtonPressed()
}

@objc class NoSitesView: UIView {

    // MARK: - Properties

    @objc weak var delegate: NoSitesViewDelegate?

    @IBOutlet weak var noSitesImage: UIImageView!
    @IBOutlet weak var noSitesTitle: UILabel!
    @IBOutlet weak var addSiteButton: LoginButton!
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTrailingConstraint: NSLayoutConstraint!

    // MARK: - Init

    @objc class func instanceFromNib() -> NoSitesView {
        return UINib(nibName: "NoSitesView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! NoSitesView
    }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(NoSitesView.orientationChanged),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange,
                                               object: nil)
    }

    // MARK: - De-init

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Configuration

    func configureViewForFrame(_ viewFrame: CGRect) {

        configureElements()

        translatesAutoresizingMaskIntoConstraints = false

        let frameWidth = viewFrame.size.width
        let frameHeight = viewFrame.size.height
        noSitesTitle.preferredMaxLayoutWidth = frameWidth -
                                               titleLeadingConstraint.constant -
                                               titleTrailingConstraint.constant

        var newFrame = viewFrame

        if frameHeight > frameWidth {
            newFrame.size.height = frameWidth
        }
        else {
            newFrame.size.height = frameHeight/2
        }

        frame = newFrame
    }

    func configureElements() {
        noSitesTitle.text = NSLocalizedString("Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.", comment: "Text shown when the account has no sites.")
        let buttonTitle = NSLocalizedString("Add new site", comment: "Title of button to add a new site.")
        addSiteButton?.setTitle(buttonTitle, for: UIControlState())
        addSiteButton?.setTitle(buttonTitle, for: .highlighted)
        addSiteButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        addSiteButton?.accessibilityIdentifier = "Add New Site Button"
    }

    // MARK: - Orientation Handling

    @objc func orientationChanged() {
        if let superview = superview {
            configureViewForFrame(superview.frame)
        }
    }

    // MARK: - Button Handling

    @IBAction func addSiteButtonPressed(_ sender: Any) {
        delegate?.addSiteButtonPressed()
    }

}
