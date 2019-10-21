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
        prepareForVoiceOver()
    }


    @objc func applyStyles() {
        backgroundColor = .clear
        borderedView.backgroundColor = .listForeground
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = .hairlineBorderWidth

        titleLabel.font = WPStyleGuide.tableviewTextFont()
        titleLabel.textColor = .neutral(.shade70)
        titleLabel.text = NSLocalizedString("Manage", comment: "Button title. Tapping lets the user manage the sites they follow.")

        disclosureIcon.image = Gridicon.iconOfType(.chevronRight, withSize: disclosureIcon.frame.size).imageFlippedForRightToLeftLayoutDirection()
        disclosureIcon.tintColor = .neutral(.shade30)

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
        borderedView.backgroundColor = .textInverted
    }


    @IBAction func didTouchUpInside(_ sender: UIButton) {
        borderedView.backgroundColor = .listForeground

        delegate?.handleFollowActionForHeader(self)
    }


    @IBAction func didTouchUpOutside(_ sender: UIButton) {
        borderedView.backgroundColor = .listForeground
    }
}


// MARK: - Accessibility
extension ReaderFollowedSitesStreamHeader: Accessible {
    func prepareForVoiceOver() {
        isAccessibilityElement = true
        accessibilityLabel = NSLocalizedString("Manage", comment: "Button title. Tapping lets the user manage the sites they follow.")
        accessibilityHint = NSLocalizedString("Tapping lets you manage the sites you follow.", comment: "Accessibility hint")
        accessibilityTraits = UIAccessibilityTraits.button
    }
}
