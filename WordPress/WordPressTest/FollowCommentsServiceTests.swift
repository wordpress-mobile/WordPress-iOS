import XCTest
import WordPressKit

@testable import WordPress

class FollowCommentsServiceTests: XCTestCase {

    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!
    private let siteID = NSNumber(value: 1)
    private let postID = NSNumber(value: 1)

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = contextManager.mainContext
    }

    override func tearDown() {
        context = nil
        ContextManager.overrideSharedInstance(nil)
        contextManager = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testCanFollowConversationIfReaderTeamTopic() {
        // Arrange
        let remoteMock = ReaderPostServiceRemoteMock()
        seedBlog(isWPForTeams: false)
        let testTopic = seedReaderTeamTopic()
        let testPost = seedReaderPostForTopic(testTopic)
        let followCommentsService = FollowCommentsService(post: testPost, remote: remoteMock)!

        // Act
        let canFollowConversation = followCommentsService.canFollowConversation

        // Assert
        XCTAssertTrue(canFollowConversation, "Can follow comments on post if the topic is ReaderTeamTopic")
    }

    func testCanFollowConversationIfWPForTeams() {
        // Arrange
        let remoteMock = ReaderPostServiceRemoteMock()
        seedBlog(isWPForTeams: true)
        let testTopic = seedReaderListTopic()
        let testPost = seedReaderPostForTopic(testTopic)
        let followCommentsService = FollowCommentsService(post: testPost, remote: remoteMock)!

        // Act
        let canFollowConversation = followCommentsService.canFollowConversation

        // Assert
        XCTAssertTrue(canFollowConversation, "Can follow comments on post if blog is marked as a  P2 blog")
    }

    func testCannotFollowConversation() {
        // Arrange
        let remoteMock = ReaderPostServiceRemoteMock()
        seedBlog(isWPForTeams: false)
        let testTopic = seedReaderListTopic()
        let testPost = seedReaderPostForTopic(testTopic)
        let followCommentsService = FollowCommentsService(post: testPost, remote: remoteMock)!

        // Act
        let canFollowConversation = followCommentsService.canFollowConversation

        // Assert
        XCTAssertFalse(canFollowConversation, "Can't follow comments on post if the topic isn't a ReaderTeamTopic and the blog isn't marked as a P2 blog")
    }

    func testToggleSubscriptionToUnsubscribed() {
        // Arrange
        let remoteMock = ReaderPostServiceRemoteMock()
        let testTopic = seedReaderTeamTopic()
        let testPost = seedReaderPostForTopic(testTopic)
        let followCommentsService = FollowCommentsService(post: testPost, remote: remoteMock)!
        let isSubscribed = true

        // Act
        followCommentsService.toggleSubscribed(isSubscribed, success: {}, failure: { _ in })

        // Assert
        XCTAssertFalse(remoteMock.subscribeToPostCalled, "subscribeToPost should not be called")
        XCTAssertTrue(remoteMock.unsubscribeFromPostCalled, "unsubscribeFromPost should be called")
    }

    func testToggleSubscriptionToSubscribed() {
        // Arrange
        let remoteMock = ReaderPostServiceRemoteMock()
        let testTopic = seedReaderTeamTopic()
        let testPost = seedReaderPostForTopic(testTopic)
        let followCommentsService = FollowCommentsService(post: testPost, remote: remoteMock)!
        let isSubscribed = false

        // Act
        followCommentsService.toggleSubscribed(isSubscribed, success: {}, failure: { _ in })

        // Assert
        XCTAssertTrue(remoteMock.subscribeToPostCalled, "subscribeToPost should be called")
        XCTAssertFalse(remoteMock.unsubscribeFromPostCalled, "unsubscribeFromPost should not be called")
    }

    // MARK: - Mocks / Tester

    class ReaderPostServiceRemoteMock: ReaderPostServiceRemote {

        var subscribeToPostCalled = false
        var unsubscribeFromPostCalled = false

        override func subscribeToPost(with postID: Int,
                                      for siteID: Int,
                                      success: @escaping () -> Void,
                                      failure: @escaping (Error?) -> Void) {
            subscribeToPostCalled = true
        }

        override func unsubscribeFromPost(with postID: Int,
                                          for siteID: Int,
                                          success: @escaping () -> Void,
                                          failure: @escaping (Error) -> Void) {
            unsubscribeFromPostCalled = true
        }
    }

    // MARK: - Helpers

       func seedReaderListTopic() -> ReaderListTopic {
           let topic = NSEntityDescription.insertNewObject(forEntityName: ReaderListTopic.classNameWithoutNamespaces(), into: context) as! ReaderListTopic
           topic.path = "/list/topic1"
           topic.title = "topic1"
           topic.type = ReaderListTopic.TopicType

           do {
               try context.save()
           } catch let error as NSError {
               XCTAssertNil(error, "Error seeding list topic")
           }

           return topic
       }


       func seedReaderTeamTopic() -> ReaderTeamTopic {
           let topic = NSEntityDescription.insertNewObject(forEntityName: ReaderTeamTopic.classNameWithoutNamespaces(), into: context) as! ReaderTeamTopic
            topic.path = "/a8c/topic2"
            topic.title = "topic2"
            topic.type = ReaderTeamTopic.TopicType

           do {
               try context.save()
           } catch let error as NSError {
               XCTAssertNil(error, "Error seeding team topic")
           }

           return topic
       }

       func seedReaderPostForTopic(_ topic: ReaderAbstractTopic) -> ReaderPost {
           let post = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.classNameWithoutNamespaces(), into: context) as! ReaderPost
           post.siteID = siteID
           post.postID = postID
           post.topic = topic

           do {
               try context.save()
           } catch let error as NSError {
               XCTAssertNil(error, "Error seeding post")
           }

           return post
       }

       func seedBlog(isWPForTeams: Bool) {
           let blog = NSEntityDescription.insertNewObject(forEntityName: Blog.classNameWithoutNamespaces(), into: context) as! Blog
           blog.dotComID = siteID
           blog.xmlrpc = "http://test.blog/xmlrpc.php"
           blog.url = "http://test.blog/"
           blog.options = [
               "is_wpforteams_site": [
                   "value": NSNumber(value: isWPForTeams)
               ]
           ]

           do {
               try context.save()
           } catch let error as NSError {
               XCTAssertNil(error, "Error seeding blog")
           }
       }
}
