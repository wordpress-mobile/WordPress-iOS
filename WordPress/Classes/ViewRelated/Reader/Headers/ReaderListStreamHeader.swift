import Foundation
import WordPressShared.WPStyleGuide

@objc open class ReaderListStreamHeader: UIView, ReaderStreamHeader {
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

    @objc func applyStyles() {
        backgroundColor = .listBackground
        borderedView.backgroundColor = .listForeground
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = .hairlineBorderWidth
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(detailLabel)
    }


    // MARK: - Configuration

    @objc open func configureHeader(_ topic: ReaderAbstractTopic) {
        assert(topic.isKind(of: ReaderListTopic.self))

        let listTopic = topic as! ReaderListTopic

        titleLabel.text = topic.title
        detailLabel.text = listTopic.owner
    }

    @objc open func enableLoggedInFeatures(_ enable: Bool) {
        // noop
    }

}
