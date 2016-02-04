import UIKit
import WordPressShared

class PlanListViewController: UITableViewController {
    let cellIdentifier = "PlanListItem"
    let availablePlans = [
        Plan.Free,
        Plan.Premium,
        Plan.Business
    ]
    let activePlan: Plan?

    convenience init(blog: Blog) {
        self.init(activePlan: blog.plan)
    }

    init(activePlan: Plan?) {
        self.activePlan = activePlan
        super.init(style: .Grouped)
        title = NSLocalizedString("Plans", comment: "Title for the plan selector")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(WPTableViewCellSubtitle.self, forCellReuseIdentifier: cellIdentifier)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availablePlans.count
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return WPTableViewSectionHeaderFooterView.heightForHeader(title, width: tableView.frame.width)
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = NSLocalizedString("WordPress.com Plans", comment: "Title for the Plans list header")
        let view = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        view.title = title
        return view
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        let plan = availablePlans[indexPath.row]
        let active = plan == activePlan

        if active {
            cell.imageView?.image = plan.activeImage
        } else {
            cell.imageView?.image = plan.image
        }
        cell.textLabel?.attributedText = attributedTitleForPlan(plan, active: active)
        cell.textLabel?.adjustsFontSizeToFitWidth = true

        cell.detailTextLabel?.text = plan.description
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()

        cell.selectionStyle = .None

        return cell
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 92
    }

    // TODO: Prices should always come from StoreKit
    // @koke 2016-02-02
    private func priceForPlan(plan: Plan) -> String? {
        switch plan {
        case .Free:
            return nil
        case .Premium:
            return "$99.99"
        case .Business:
            return "$299.99"
        }
    }

    private func attributedTitleForPlan(plan: Plan, active: Bool) -> NSAttributedString {
        let titleAttributes = [
            NSFontAttributeName: WPStyleGuide.tableviewTextFont(),
            NSForegroundColorAttributeName: WPStyleGuide.tableViewActionColor()
        ]
        let priceAttributes = [
            NSFontAttributeName: WPFontManager.openSansRegularFontOfSize(14.0),
            NSForegroundColorAttributeName: WPStyleGuide.darkGrey()
        ]
        let pricePeriodAttributes = [
            NSFontAttributeName: WPFontManager.openSansItalicFontOfSize(13.0),
            NSForegroundColorAttributeName: WPStyleGuide.greyLighten20()
        ]
        let planTitle = NSAttributedString(string: plan.title, attributes: titleAttributes)

        let attributedTitle = NSMutableAttributedString(attributedString: planTitle)

        if active {
            let currentPlanAttributes = [
                NSFontAttributeName: WPFontManager.openSansSemiBoldFontOfSize(11.0),
                NSForegroundColorAttributeName: WPStyleGuide.validGreen()
            ]
            let currentPlan = NSLocalizedString("Current Plan", comment: "").uppercaseStringWithLocale(NSLocale.currentLocale())
            let attributedCurrentPlan = NSAttributedString(string: currentPlan, attributes: currentPlanAttributes)
            attributedTitle.appendString(" ")
            attributedTitle.appendAttributedString(attributedCurrentPlan)
        } else if let price = priceForPlan(plan) {
            attributedTitle.appendString(" ")
            let attributedPrice = NSAttributedString(string: price, attributes: priceAttributes)
            attributedTitle.appendAttributedString(attributedPrice)

            attributedTitle.appendString(" ")
            let pricePeriod = NSAttributedString(string: NSLocalizedString("per year", comment: ""), attributes: pricePeriodAttributes)
            attributedTitle.appendAttributedString(pricePeriod)
        }
        return attributedTitle

    }
}
