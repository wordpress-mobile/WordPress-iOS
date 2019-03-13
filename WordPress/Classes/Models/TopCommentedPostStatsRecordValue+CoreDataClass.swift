import Foundation
import CoreData


public class TopCommentedPostStatsRecordValue: StatsRecordValue {

    public var postURL: URL? {
        guard let url = postURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

}

// This could arguably live both here and in `TopCommentsAuthor` — I've arbitraily chosen this location.
extension StatsCommentsInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        let posts: [StatsRecordValue] = topPosts.map {
            let value = TopCommentedPostStatsRecordValue(context: context)

            value.title = $0.name
            value.commentCount = Int64($0.commentCount)
            value.postURLString = $0.postURL?.absoluteString
            value.postID = $0.postID

            return value
        }
        let authors: [StatsRecordValue] = topAuthors.compactMap {
            let value = TopCommentsAuthorStatsRecordValue(context: context)

            value.name = $0.name
            value.commentCount = Int64($0.commentCount)
            value.avatarURLString = $0.iconURL?.absoluteString

            return value
        }

        return [posts, authors].flatMap { $0 }
    }

    init(statsRecordValue: StatsRecordValue) {
        // We won't be needing those until later. I added them to protocol to show the intended design
        // but it doesn't make sense to implement it yet.
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
    }

    static var recordType: StatsRecordType {
        return .commentInsight
    }

}
