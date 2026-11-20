import CoreData
import Testing
import WordPressData

@testable import WordPress

@MainActor
struct ReadOnlyNotificationCommentTests {
    private let contextManager = ContextManager.forTesting()

    @Test func buildsTheCommentFromTheNotification() throws {
        let note = try loadReply()

        let copy = try #require(makeCopy(of: note))
        let comment = copy.comment

        #expect(comment.commentID == 1912)
        #expect(comment.postID == 6987)
        #expect(comment.parentID == 1910)
        #expect(comment.authorID == 2002)
        #expect(comment.author == "Sam Sample")
        #expect(comment.authorAvatarURL == "https://gravatar.example.com/avatar/sam")
        #expect(comment.author_url == "http://samsample.example.com")
        #expect(comment.postTitle == "Remote flags rollout")
        #expect(comment.link == "https://private-site.example.com/2026/11/18/remote-flags-rollout/#comment-1912")
        #expect(comment.dateCreated == note.timestampAsDate)
        #expect(comment.isApproved())
        #expect(!comment.canModerate)
        #expect(
            comment.content
                == "<p>Caching happens on each calling site, so the API isn’t hit on every request. 😅 </p>\n\n"
                + "<p>The apps only ask when they <a href=\"https://example.com/launch\">launch</a>. 🙂</p>"
        )
    }

    @Test func buildsTheParentCommentFromTheHeader() throws {
        let copy = try #require(makeCopy(of: loadReply()))
        let parent = try #require(copy.parentComment)

        #expect(parent.commentID == 1910)
        #expect(parent.authorForDisplay() == "Pat Example")
        #expect(parent.contentPreviewForDisplay() == "The library lives apart from the endpoint, so reuse is easy ...")
    }

    @Test func topLevelCommentHasNoParentAndTakesThePostTitleFromTheSubject() throws {
        let note = try loadReply { json in
            var meta = json["meta"] as! [String: Any]
            var ids = meta["ids"] as! [String: Any]
            ids["parent_comment"] = nil
            meta["ids"] = ids
            json["meta"] = meta as AnyObject
            json["header"] = [["text": "Pat Example"], ["text": "Remote flags rollout"]] as AnyObject
            json["subject"] =
                [
                    [
                        "text": "Sam Sample commented on Remote flags rollout",
                        "ranges": [["type": "post", "indices": [24, 44], "id": 6987]]
                    ]
                ] as AnyObject
        }

        let copy = try #require(makeCopy(of: note))

        #expect(copy.parentComment == nil)
        #expect(copy.comment.parentID == 0)
        #expect(copy.comment.postTitle == "Remote flags rollout")
    }

    @Test func returnsNilWhenTheNotificationHasNoComment() throws {
        let note = try NotificationUtility(coreDataStack: contextManager).loadLikeNotification()

        #expect(makeCopy(of: note) == nil)
    }

    @Test func neverSavesTheCopy() throws {
        let copy = try #require(makeCopy(of: loadReply()))

        contextManager.saveContextAndWait(contextManager.mainContext)

        let savedComments = try contextManager.mainContext.count(
            for: NSFetchRequest<WordPressData.Comment>(entityName: "Comment")
        )
        #expect(savedComments == 0)
        withExtendedLifetime(copy) {}
    }

    @Test func commentDetailsHideModerationForTheCopy() throws {
        let note = try loadReply()
        let copy = try #require(makeCopy(of: note))

        let readOnly = CommentDetailViewController(
            readOnlyComment: copy,
            notification: note,
            notificationDelegate: nil,
            managedObjectContext: contextManager.mainContext
        )
        // The same comment shown normally: with no site, the app treats it as self-hosted and allows moderation.
        let regular = CommentDetailViewController(
            comment: copy.comment,
            notification: note,
            notificationDelegate: nil,
            managedObjectContext: contextManager.mainContext
        )
        readOnly.loadViewIfNeeded()
        regular.loadViewIfNeeded()

        #expect(!readOnly.allowsModeration)
        #expect(regular.allowsModeration)
        // The moderation section is the second one.
        #expect(readOnly.numberOfSections(in: readOnly.tableView) == 1)
        #expect(regular.numberOfSections(in: regular.tableView) == 2)
    }

    // MARK: - Helpers

    private func makeCopy(of note: WordPressData.Notification) -> ReadOnlyNotificationComment? {
        ReadOnlyNotificationComment(notification: note, mainContext: contextManager.mainContext)
    }

    /// Loads the private-site reply fixture, after applying `change` to its JSON.
    private func loadReply(_ change: (inout JSONObject) -> Void = { _ in }) throws -> WordPressData.Notification {
        var json = try JSONObject(fromFileNamed: "notifications-private-site-reply.json")
        change(&json)
        let note = WordPressData.Notification(context: contextManager.mainContext)
        for (key, value) in json {
            note.setValue(value, forKey: key)
        }
        return note
    }
}
