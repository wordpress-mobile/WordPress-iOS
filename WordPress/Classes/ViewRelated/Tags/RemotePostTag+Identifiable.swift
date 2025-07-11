import Foundation
import WordPressKit

extension RemotePostTag: @retroactive Identifiable {
    public var id: Int {
        return tagID?.intValue ?? 0
    }
}
