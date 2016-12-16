import Foundation
import CoreData

@objc (Page)
class Page: AbstractPost {

    /// Number of seconds in twenty-four hours.
    ///
    fileprivate static let twentyFourHours = TimeInterval(86400)

    /// The time interval formatter that all pages will use for their section identifiers.
    ///
    fileprivate static let timeIntervalFormatter : TTTTimeIntervalFormatter = {
        let timeIntervalFormatter = TTTTimeIntervalFormatter()

        timeIntervalFormatter.leastSignificantUnit = .day
        timeIntervalFormatter.usesIdiomaticDeicticExpressions = true
        timeIntervalFormatter.presentDeicticExpression = NSLocalizedString("today", comment: "Today")

        return timeIntervalFormatter
    }()

    /// Section identifier for the page.
    ///
    func sectionIdentifier() -> String {

        let interval = date_created_gmt?.timeIntervalSinceNow ?? TimeInterval(0)

        if interval > 0 && interval < type(of: self).twentyFourHours {
            return NSLocalizedString("later today", comment: "Later today")
        } else {
            return type(of: self).timeIntervalFormatter.string(forTimeInterval: interval)
        }
    }
}
