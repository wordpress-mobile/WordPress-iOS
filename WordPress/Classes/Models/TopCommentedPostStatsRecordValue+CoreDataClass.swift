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

        let posts: [StatsRecordValue] = topPosts.map  { (obj: StatsTopCommentsPost) -> TopCommentedPostStatsRecordValue in
            let value = TopCommentedPostStatsRecordValue(context: context)

            value.title = obj.name
            value.commentCount = Int64(obj.commentCount)
            value.postURLString = obj.postURL?.absoluteString
            value.postID = obj.postID

            return value
        }
        let authors: [StatsRecordValue] = topAuthors.compactMap { (obj: StatsTopCommentsAuthor) -> StatsRecordValue in
            let value = TopCommentsAuthorStatsRecordValue(context: context)

            value.name = obj.name
            value.commentCount = Int64(obj.commentCount)
            value.avatarURLString = obj.iconURL?.absoluteString

            return value
        }

        return [posts, authors].flatMap { $0 }
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        let authors = statsRecordValues
            .compactMap { $0 as? TopCommentsAuthorStatsRecordValue }
            .compactMap { StatsTopCommentsAuthor(recordValue: $0) }

        let posts = statsRecordValues
            .compactMap { $0 as? TopCommentedPostStatsRecordValue }
            .compactMap { StatsTopCommentsPost(recordValue: $0) }

        self = StatsCommentsInsight(topPosts: posts, topAuthors: authors)
    }

    static var recordType: StatsRecordType {
        return .commentInsight
    }

}

fileprivate extension StatsTopCommentsPost {
    init?(recordValue: TopCommentedPostStatsRecordValue) {
        guard
            let name = recordValue.title,
            let postID = recordValue.postID
            else {
                return nil
        }

        self = StatsTopCommentsPost(name: name,
                                    postID: postID,
                                    commentCount: Int(recordValue.commentCount),
                                    postURL: recordValue.postURL)
    }
}

fileprivate extension StatsTopCommentsAuthor {
    init?(recordValue: TopCommentsAuthorStatsRecordValue) {
        guard let name = recordValue.name else {
            return nil
        }
        self = StatsTopCommentsAuthor(name: name,
                                      commentCount: Int(recordValue.commentCount),
                                      iconURL: recordValue.avatarURL)
    }
}
