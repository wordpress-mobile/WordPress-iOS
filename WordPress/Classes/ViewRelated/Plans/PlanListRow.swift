import UIKit
import WordPressShared

struct PlanListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    static let customHeight: Float? = 92
    fileprivate let iconSize = CGSize(width: 60, height: 60)

    let title: String
    let active: Bool
    let price: String
    let description: String
    let iconUrl: URL

    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.imageView?.downloadResizedImage(iconUrl, placeholderImage: UIImage(named: "plan-placeholder")!, pointSize: iconSize)
        cell.textLabel?.attributedText = attributedTitle
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = description
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()
        cell.detailTextLabel?.font = WPFontManager.systemRegularFont(ofSize: 14.0)
        cell.separatorInset = UIEdgeInsets.zero
    }

    fileprivate var attributedTitle: NSAttributedString {
        return Formatter.attributedTitle(title, price: price, active: active)
    }

    struct Formatter {
        static let titleAttributes: [String: Any] = [
            NSFontAttributeName: WPStyleGuide.tableviewTextFont(),
            NSForegroundColorAttributeName: WPStyleGuide.tableViewActionColor()
        ]
        static let priceAttributes: [String: Any] = [
            NSFontAttributeName: WPFontManager.systemRegularFont(ofSize: 14.0),
            NSForegroundColorAttributeName: WPStyleGuide.darkGrey()
        ]
        static let pricePeriodAttributes: [String: Any] = [
            NSFontAttributeName: WPFontManager.systemItalicFont(ofSize: 14.0),
            NSForegroundColorAttributeName: WPStyleGuide.grey()
        ]

        static func attributedTitle(_ title: String, price: String, active: Bool) -> NSAttributedString {
            let planTitle = NSAttributedString(string: title, attributes: titleAttributes)

            let attributedTitle = NSMutableAttributedString(attributedString: planTitle)

            if active {
                let currentPlanAttributes: [String: Any] = [
                    NSFontAttributeName: WPFontManager.systemSemiBoldFont(ofSize: 11.0),
                    NSForegroundColorAttributeName: WPStyleGuide.validGreen()
                ]
                let currentPlan = NSLocalizedString("Current Plan", comment: "").uppercased(with: Locale.current)
                let attributedCurrentPlan = NSAttributedString(string: currentPlan, attributes: currentPlanAttributes)
                attributedTitle.appendString(" ")
                attributedTitle.append(attributedCurrentPlan)
            } else if !price.isEmpty {
                attributedTitle.appendString(" ")

                let pricePeriod = String(format: NSLocalizedString("%@ <em>per year</em>", comment: "Plan yearly price"), price)

                let attributes: StyledHTMLAttributes = [ .BodyAttribute: priceAttributes as Dictionary<String, AnyObject>,
                                                         .EmTagAttribute: pricePeriodAttributes as Dictionary<String, AnyObject> ]

                let attributedPricePeriod = NSAttributedString.attributedStringWithHTML(pricePeriod, attributes: attributes)
                attributedTitle.append(attributedPricePeriod)
            }

            return attributedTitle
        }
    }
}
