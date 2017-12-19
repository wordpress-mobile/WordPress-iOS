import Foundation
import Gridicons
import WordPressShared.WPStyleGuide

@objc open class ReaderFollowedSitesStreamHeader: UIView, ReaderStreamHeader {
    @IBOutlet fileprivate weak var borderedView: UIView!
    @IBOutlet fileprivate weak var imageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var disclosureIcon: UIImageView!
    @IBOutlet fileprivate weak var contentButton: UIButton!

    open weak var delegate: ReaderStreamHeaderDelegate?


    // MARK: - Lifecycle Methods


    open override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }


    @objc func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = 1.0

        titleLabel.font = WPStyleGuide.tableviewTextFont()
        titleLabel.textColor = WPStyleGuide.darkGrey()
        titleLabel.text = NSLocalizedString("Manage", comment: "Button title. Tapping lets the user manage the sites they follow.")

        disclosureIcon.image = Gridicon.iconOfType(.chevronRight, withSize: disclosureIcon.frame.size).imageFlippedForRightToLeftLayoutDirection()
        disclosureIcon.tintColor = WPStyleGuide.accessoryDefaultTintColor()

        imageView.image = Gridicon.iconOfType(.cog)
        imageView.tintColor = UIColor.white
    }


    // MARK: - Configuration


    @objc open func configureHeader(_ topic: ReaderAbstractTopic) {
        // no op
    }


    @objc open func enableLoggedInFeatures(_ enable: Bool) {
        // no op
    }


    // MARK: - Actions


    @IBAction func didTouchDown(_ sender: UIButton) {
        borderedView.backgroundColor = WPStyleGuide.cellDefaultHighlightColor()
    }


    @IBAction func didTouchUpInside(_ sender: UIButton) {
        borderedView.backgroundColor = UIColor.white

        delegate?.handleFollowActionForHeader(self)
    }


    @IBAction func didTouchUpOutside(_ sender: UIButton) {
        borderedView.backgroundColor = UIColor.white
    }
}
