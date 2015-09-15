import Foundation

@objc public class ReaderListStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    // Required by ReaderStreamHeader protocol.
    public var delegate: ReaderStreamHeaderDelegate?


    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(detailLabel)
    }

    public override func sizeThatFits(size: CGSize) -> CGSize {
        return systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
    }


    // MARK: - Configuration

    public func configureHeader(topic: ReaderAbstractTopic) {
        assert(topic.isKindOfClass(ReaderListTopic))

        let listTopic = topic as! ReaderListTopic

        titleLabel.text = topic.title
        detailLabel.text = listTopic.owner
    }

    public func enableLoggedInFeatures(enable: Bool) {
        // noop
    }

}
