import Foundation
import Gridicons
import WordPressShared.WPStyleGuide

@objc public class ReaderFollowedSitesStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var disclosureIcon: UIImageView!
    @IBOutlet private weak var contentButton: UIButton!
    @IBOutlet private weak var contentIPadTopConstraint: NSLayoutConstraint?
    @IBOutlet private weak var contentBottomConstraint: NSLayoutConstraint!

    public var delegate: ReaderStreamHeaderDelegate?


    // MARK: - Lifecycle Methods


    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }


    func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()

        titleLabel.font = WPStyleGuide.tableviewTextFont()
        titleLabel.textColor = WPStyleGuide.darkGrey()
        titleLabel.text = NSLocalizedString("Manage Sites", comment: "Button title. Tapping lets the user manage the sites they follow.")

        disclosureIcon.image = Gridicon.iconOfType(.ChevronRight, withSize: disclosureIcon.frame.size)
        disclosureIcon.tintColor = UIColor(fromRGBAColorWithRed: 199.0, green: 199.0, blue: 204.0, alpha: 1.0)

        imageView.image = Gridicon.iconOfType(.Cog, withSize: imageView.frame.size)
        imageView.tintColor = UIColor.whiteColor()
    }


    public override func sizeThatFits(size: CGSize) -> CGSize {
        var height = innerContentView.frame.size.height
        if UIDevice.isPad() && contentIPadTopConstraint != nil {
            height += contentIPadTopConstraint!.constant
        }
        height += contentBottomConstraint.constant
        return CGSize(width: size.width, height: height)
    }


    // MARK: - Configuration


    public func configureHeader(topic: ReaderAbstractTopic) {
        // no op
    }


    public func enableLoggedInFeatures(enable: Bool) {
        // no op
    }


    // MARK: - Actions


    @IBAction func didTouchDown(sender: UIButton) {
        innerContentView.backgroundColor = UIColor(fromRGBAColorWithRed: 217.0, green: 217.0, blue: 217.0, alpha: 1.0)
    }


    @IBAction func didTouchUpInside(sender: UIButton) {
        innerContentView.backgroundColor = UIColor.whiteColor()

        delegate?.handleFollowActionForHeader(self)
    }


    @IBAction func didTouchUpOutside(sender: UIButton) {
        innerContentView.backgroundColor = UIColor.whiteColor()
    }
}
