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
        cell.imageView?.downloadResizedImage(from: iconUrl, placeholderImage: UIImage(named: "plan-placeholder")!, pointSize: iconSize)
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
        static let titleAttributes: [NSAttributedStringKey: Any] = [
            .font: WPStyleGuide.tableviewTextFont(),
            .foregroundColor: WPStyleGuide.tableViewActionColor()
        ]
        static let priceAttributes: [NSAttributedStringKey: Any] = [
            .font: WPFontManager.systemRegularFont(ofSize: 14.0),
            .foregroundColor: WPStyleGuide.darkGrey()
        ]
        static let pricePeriodAttributes: [NSAttributedStringKey: Any] = [
            .font: WPFontManager.systemItalicFont(ofSize: 14.0),
            .foregroundColor: WPStyleGuide.grey()
        ]

        static func attributedTitle(_ title: String, price: String, active: Bool) -> NSAttributedString {
            let paddedTitle = title + " "
            let planTitle = NSAttributedString(string: paddedTitle, attributes: titleAttributes)

            let attributedTitle = NSMutableAttributedString(attributedString: planTitle)

            if active {
                let currentPlanAttributes: [NSAttributedStringKey: Any] = [
                    .font: WPFontManager.systemSemiBoldFont(ofSize: 11.0),
                    .foregroundColor: WPStyleGuide.validGreen()
                ]
                let currentPlan = NSLocalizedString("Current Plan", comment: "Label title. Refers to the current WordPress.com plan for a user's site.").localizedUppercase
                let attributedCurrentPlan = NSAttributedString(string: currentPlan, attributes: currentPlanAttributes)
                attributedTitle.append(attributedCurrentPlan)
            } else if !price.isEmpty {

                let pricePeriod = String(format: NSLocalizedString("%@ <em>per year</em>", comment: "Plan yearly price"), price)

                let attributes: StyledHTMLAttributes = [ .BodyAttribute: priceAttributes,
                                                         .EmTagAttribute: pricePeriodAttributes ]

                let attributedPricePeriod = NSAttributedString.attributedStringWithHTML(pricePeriod, attributes: attributes)
                attributedTitle.append(attributedPricePeriod)
            }

            return attributedTitle
        }
    }
}
