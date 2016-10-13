import Foundation
import Gridicons
import WordPressShared.WPStyleGuide

@objc public class ReaderFollowedSitesStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var borderedView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var disclosureIcon: UIImageView!
    @IBOutlet private weak var contentButton: UIButton!

    public weak var delegate: ReaderStreamHeaderDelegate?


    // MARK: - Lifecycle Methods


    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }


    func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().CGColor
        borderedView.layer.borderWidth = 1.0

        titleLabel.font = WPStyleGuide.tableviewTextFont()
        titleLabel.textColor = WPStyleGuide.darkGrey()
        titleLabel.text = NSLocalizedString("Manage", comment: "Button title. Tapping lets the user manage the sites they follow.")

        disclosureIcon.image = Gridicon.iconOfType(.ChevronRight, withSize: disclosureIcon.frame.size)
        disclosureIcon.tintColor = WPStyleGuide.accessoryDefaultTintColor()

        imageView.image = Gridicon.iconOfType(.Cog)
        imageView.tintColor = UIColor.whiteColor()
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
        borderedView.backgroundColor = WPStyleGuide.cellDefaultHighlightColor()
    }


    @IBAction func didTouchUpInside(sender: UIButton) {
        borderedView.backgroundColor = UIColor.whiteColor()

        delegate?.handleFollowActionForHeader(self)
    }


    @IBAction func didTouchUpOutside(sender: UIButton) {
        borderedView.backgroundColor = UIColor.whiteColor()
    }
}
