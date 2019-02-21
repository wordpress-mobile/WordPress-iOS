import Foundation

extension Blog {
    enum AnalyticsType: String {
        case wpcom
        case jetpack
        case core
    }

    var analyticsType: AnalyticsType {
        if let dotComID = dotComID, dotComID.intValue > 0 {
            if isHostedAtWPcom {
                return .wpcom
            } else {
                return .jetpack
            }
        } else {
            return .core
        }
    }
}
