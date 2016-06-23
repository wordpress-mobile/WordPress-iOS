import UIKit
import WordPressShared

struct PlanListRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellSubtitle)
    static let customHeight: Float? = 92
    private let iconSize = CGSize(width: 60, height: 60)

    let title: String
    let active: Bool
    let price: String
    let description: String
    let iconUrl: NSURL

    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.imageView?.downloadResizedImage(iconUrl, placeholderImage: UIImage(named: "plan-placeholder")!, pointSize: iconSize)
        cell.textLabel?.attributedText = attributedTitle
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = description
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()
        cell.detailTextLabel?.font = WPFontManager.systemRegularFontOfSize(14.0)
        cell.separatorInset = UIEdgeInsetsZero
    }

    private var attributedTitle: NSAttributedString {
        return Formatter.attributedTitle(title, price: price, active: active)
    }

    struct Formatter {
        static let titleAttributes = [
            NSFontAttributeName: WPStyleGuide.tableviewTextFont(),
            NSForegroundColorAttributeName: WPStyleGuide.tableViewActionColor()
        ]
        static let priceAttributes = [
            NSFontAttributeName: WPFontManager.systemRegularFontOfSize(14.0),
            NSForegroundColorAttributeName: WPStyleGuide.darkGrey()
        ]
        static let pricePeriodAttributes = [
            NSFontAttributeName: WPFontManager.systemItalicFontOfSize(14.0),
            NSForegroundColorAttributeName: WPStyleGuide.grey()
        ]

        static func attributedTitle(title: String, price: String, active: Bool) -> NSAttributedString {
            let planTitle = NSAttributedString(string: title, attributes: titleAttributes)

            let attributedTitle = NSMutableAttributedString(attributedString: planTitle)

            if active {
                let currentPlanAttributes = [
                    NSFontAttributeName: WPFontManager.systemSemiBoldFontOfSize(11.0),
                    NSForegroundColorAttributeName: WPStyleGuide.validGreen()
                ]
                let currentPlan = NSLocalizedString("Current Plan", comment: "").uppercaseStringWithLocale(NSLocale.currentLocale())
                let attributedCurrentPlan = NSAttributedString(string: currentPlan, attributes: currentPlanAttributes)
                attributedTitle.appendString(" ")
                attributedTitle.appendAttributedString(attributedCurrentPlan)
            } else if !price.isEmpty {
                attributedTitle.appendString(" ")

                let pricePeriod = String(format: NSLocalizedString("%@ <em>per year</em>", comment: "Plan yearly price"), price)

                let attributes: StyledHTMLAttributes = [ .BodyAttribute: priceAttributes,
                                                         .EmTagAttribute: pricePeriodAttributes ]

                let attributedPricePeriod = NSAttributedString.attributedStringWithHTML(pricePeriod, attributes: attributes)
                attributedTitle.appendAttributedString(attributedPricePeriod)
            }

            return attributedTitle
        }
    }
}
