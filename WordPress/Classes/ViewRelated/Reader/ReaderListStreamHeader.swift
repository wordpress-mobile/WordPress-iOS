import Foundation
import WordPressShared.WPStyleGuide

@objc open class ReaderListStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet fileprivate weak var borderedView: UIView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var detailLabel: UILabel!

    // Required by ReaderStreamHeader protocol.
    open var delegate: ReaderStreamHeaderDelegate?


    // MARK: - Lifecycle Methods

    open override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = 1.0
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(detailLabel)
    }


    // MARK: - Configuration

    open func configureHeader(_ topic: ReaderAbstractTopic) {
        assert(topic.isKind(of: ReaderListTopic.self))

        let listTopic = topic as! ReaderListTopic

        titleLabel.text = topic.title
        detailLabel.text = listTopic.owner
    }

    open func enableLoggedInFeatures(_ enable: Bool) {
        // noop
    }

}
