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

// This could arguably live both here and in `TopCommentsAuthor` — I've arbitrarily chosen this location.
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

    init?(statsRecordValues: [StatsRecordValue]) {
        let authors: [StatsTopCommentsAuthor] = statsRecordValues
            .compactMap { $0 as? TopCommentsAuthorStatsRecordValue }
            .compactMap {
                guard let name = $0.name else {
                    return nil
                }
                return StatsTopCommentsAuthor(name: name, commentCount: Int($0.commentCount), iconURL: $0.avatarURL)
        }

        let posts: [StatsTopCommentsPost] = statsRecordValues
            .compactMap { $0 as? TopCommentedPostStatsRecordValue }
            .compactMap {
                guard
                    let name = $0.title,
                    let postID = $0.postID
                    else {
                        return nil
                }
                return StatsTopCommentsPost(name: name, postID: postID, commentCount: Int($0.commentCount), postURL: $0.postURL)
        }

        self = StatsCommentsInsight(topPosts: posts, topAuthors: authors)
    }

    static var recordType: StatsRecordType {
        return .commentInsight
    }

}
