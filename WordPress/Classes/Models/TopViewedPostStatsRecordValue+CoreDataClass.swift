import Foundation
import CoreData

public enum TopViewsPostType: Int16 {
    case unknown
    case post
    case page
    case homepage

    init(kind: StatsTopPost.Kind) {
        switch kind {
        case .unknown:
            self = .unknown
        case .post:
            self = .post
        case .page:
            self = .page
        case .homepage:
            self = .homepage
        }
    }

    var statsTopPostKind: StatsTopPost.Kind {
        switch self {
        case .unknown:
            return .unknown
        case .post:
            return .post
        case .page:
            return .page
        case .homepage:
            return .homepage
        }
    }
}

public class TopViewedPostStatsRecordValue: StatsRecordValue {
    public var postURL: URL? {
        guard let url = postURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

    public override func validateForInsert() throws {
        try super.validateForInsert()

        guard TopViewsPostType(rawValue: type) != nil else {
            throw StatsCoreDataValidationError.invalidEnumValue
        }
    }
}
}
