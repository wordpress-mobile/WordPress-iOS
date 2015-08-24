import Foundation

@objc public class ReaderListStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    public var delegate: ReaderStreamHeaderDelegate?


    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(detailLabel)
    }
    

    // MARK: - Configuration

    public func configureHeader(topic: ReaderTopic) {
        titleLabel.text = topic.title
// TODO: Wire up when supported by the topic
//        detailLabel.text = "sites . followers"
    }

}
