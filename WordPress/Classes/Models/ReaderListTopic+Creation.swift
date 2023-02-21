import Foundation

extension ReaderListTopic {

    /// Returns an existing topic for the specified list, or creates one if one
    /// doesn't already exist.
    ///
    static func named(_ listName: String, forUser user: String, in context: NSManagedObjectContext) -> ReaderListTopic? {
        let remote = ReaderTopicServiceRemote(wordPressComRestApi: WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress()))
        let sanitizedListName = remote.slug(forTopicName: listName) ?? listName.lowercased()
        let sanitizedUser = user.lowercased()
        let path = remote.path(forEndpoint: "read/list/\(sanitizedUser)/\(sanitizedListName)/posts", withVersion: ._1_2)

        if let existingTopic = try? ReaderAbstractTopic.lookup(pathContaining: path, in: context) as? ReaderListTopic {
            return existingTopic
        }

        let topic = ReaderListTopic(context: context)
        topic.title = listName
        topic.slug = sanitizedListName
        topic.owner = user
        topic.path = path

        return topic
    }

}
