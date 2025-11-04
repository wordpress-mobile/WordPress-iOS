import Foundation
import WordPressKitObjC

extension RemotePost {
    public static func compare(otherTerms lhs: [String: [String]], withAnother rhs: [String: [String]]) -> Bool {
        guard lhs.count == rhs.count else { return false }

        return lhs.mapValues { Set($0) } == rhs.mapValues { Set($0) }
    }
}
