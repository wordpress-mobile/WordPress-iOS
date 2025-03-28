import UIKit
import DGCharts

class SubscribersChartMarker: StatsChartMarker {
    let date: Date

    init(dotColor: UIColor, name: String, date: Date) {
        self.date = date
        super.init(dotColor: dotColor, name: name)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func text(for entry: ChartDataEntry) -> NSMutableAttributedString? {
        let tightParagraphStyle = NSMutableParagraphStyle()
        tightParagraphStyle.lineSpacing = 0
        tightParagraphStyle.lineHeightMultiple = 0.8
        tightParagraphStyle.alignment = .center

        let subscriberCountRowAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                                           .paragraphStyle: tightParagraphStyle,
                                                                           .foregroundColor: UIColor.white]

        let subscriberLabelRowAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote),
                                                                           .paragraphStyle: tightParagraphStyle,
                                                                           .foregroundColor: UIColor.white]

        let subscriberDateRowAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote),
                                                                          .paragraphStyle: paragraphStyle,
                                                                          .foregroundColor: UIColor.white.withAlphaComponent(0.8)]

        let attrString = NSMutableAttributedString()
        attrString.append(NSAttributedString(string: entry.y.abbreviatedString() + "\n", attributes: subscriberCountRowAttributes))
        attrString.append(NSAttributedString(string: "\(name)\n", attributes: subscriberLabelRowAttributes))
        attrString.append(NSAttributedString(string: DateValueFormatter().dateFormatter.string(from: date), attributes: subscriberDateRowAttributes))
        return attrString
    }
}
