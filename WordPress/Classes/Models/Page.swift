import Foundation
import CoreData

@objc (Page)
class Page: AbstractPost {

    /// Number of seconds in twenty-four hours.
    ///
    private static let twentyFourHours = NSTimeInterval(86400)

    /// The time interval formatter that all pages will use for their section identifiers.
    ///
    private static let timeIntervalFormatter : TTTTimeIntervalFormatter = {
        let timeIntervalFormatter = TTTTimeIntervalFormatter()

        timeIntervalFormatter.leastSignificantUnit = .Day
        timeIntervalFormatter.usesIdiomaticDeicticExpressions = true
        timeIntervalFormatter.presentDeicticExpression = NSLocalizedString("today", comment: "Today")

        return timeIntervalFormatter
    }()

    /// Section identifier for the page.
    ///
    func sectionIdentifier() -> String {

        let interval = date_created_gmt?.timeIntervalSinceNow ?? NSTimeInterval(0)

        if interval > 0 && interval < self.dynamicType.twentyFourHours {
            return NSLocalizedString("later today", comment: "Later today")
        } else {
            return self.dynamicType.timeIntervalFormatter.stringForTimeInterval(interval)
        }
    }
}
