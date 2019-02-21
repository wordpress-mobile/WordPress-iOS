import Foundation

extension Blog {
    enum AnalyticsType: String {
        case dotcom
        case jetpack
        case core
    }

    var analyticsType: AnalyticsType {
        if let dotComID = dotComID, dotComID.intValue > 0 {
            if isHostedAtWPcom {
                return .dotcom
            } else {
                return .jetpack
            }
        } else {
            return .core
        }
    }
}
