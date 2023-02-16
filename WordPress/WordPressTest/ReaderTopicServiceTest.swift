import XCTest
import Foundation
import CoreData
import Nimble

@testable import WordPress

final class ReaderTopicSwiftTest: CoreDataTestCase {

    let expectationTimeout = 5.0

    // MARK: - Config / Helpers

    func seedTopics() {
        let topic1 = NSEntityDescription.insertNewObject(forEntityName: ReaderListTopic.classNameWithoutNamespaces(), into: mainContext) as! ReaderListTopic
        topic1.path = "/list/topic1"
        topic1.title = "topic1"
        topic1.type = ReaderListTopic.TopicType

        let topic2 = NSEntityDescription.insertNewObject(forEntityName: ReaderTagTopic.classNameWithoutNamespaces(), into: mainContext) as! ReaderTagTopic
        topic2.path = "/tags/topic2"
        topic2.title = "topic2"
        topic2.type = ReaderTagTopic.TopicType

        let topic3 = NSEntityDescription.insertNewObject(forEntityName: ReaderTagTopic.classNameWithoutNamespaces(), into: mainContext) as! ReaderTagTopic
        topic3.path = "/list/topic3"
        topic3.title = "topic3"
        topic3.type = ReaderTagTopic.TopicType

        do {
            try mainContext.save()
        } catch let error as NSError {
            XCTAssertNil(error, "Error seeding topics")
        }
    }

    func countTopics() -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderAbstractTopic.classNameWithoutNamespaces())
        return try! mainContext.count(for: request)
    }

    func seedPostsForTopic(_ topic: ReaderAbstractTopic) {
        let post1 = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.classNameWithoutNamespaces(), into: mainContext) as! ReaderPost
        post1.postID = NSNumber(value: 1)
        post1.postTitle = "post1"
        post1.content = "post1"
        post1.topic = topic

        let post2 = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.classNameWithoutNamespaces(), into: mainContext) as! ReaderPost
        post2.postID = NSNumber(value: 2)
        post2.postTitle = "post2"
        post2.content = "post2"
        post2.topic = topic

        let post3 = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.classNameWithoutNamespaces(), into: mainContext) as! ReaderPost
        post3.postID = NSNumber(value: 3)
        post3.postTitle = "post3"
        post3.content = "post3"
        post3.topic = topic

        do {
            try mainContext.save()
        } catch let error as NSError {
            XCTAssertNil(error, "Error seeding posts")
        }
    }

    func remoteSiteInfoForTests() -> [RemoteReaderSiteInfo] {
        let foo = RemoteReaderSiteInfo()
        foo.feedID = 1
        foo.isFollowing = true
        foo.postsEndpoint = "/sites/foo"

        let bar = RemoteReaderSiteInfo()
        bar.feedID = 2
        bar.isFollowing = true
        bar.postsEndpoint = "/sites/bar"

        let baz = RemoteReaderSiteInfo()
        baz.feedID = 3
        baz.isFollowing = true
        baz.postsEndpoint = "/sites/baz"

        return [foo, bar, baz]
    }

    func remoteTopicsForTests() -> [RemoteReaderTopic] {
        let foo = RemoteReaderTopic(
            dictionary: [
                "ID": 1,
                "title": "foo",
                "URL": "/tags/foo",
            ],
            subscribed: true,
            recommended: false
        )
        foo.isMenuItem = true

        let bar = RemoteReaderTopic(
            dictionary: [
                "ID": 2,
                "title": "bar",
                "URL": "/tags/bar",
            ],
            subscribed: true,
            recommended: false
        )
        bar.isMenuItem = true

        let baz = RemoteReaderTopic(
            dictionary: [
                "ID": 3,
                "title": "baz",
                "URL": "/tags/baz",
            ],
            subscribed: true,
            recommended: false
        )
        baz.isMenuItem = true

        return [foo, bar, baz]
    }

    func remoteAndDefaultTopicForTests() -> [RemoteReaderTopic] {
        var remoteTopics = remoteTopicsForTests()

        let def = RemoteReaderTopic(
            dictionary: [
                "ID": 4,
                "title": "def",
                "URL": "/def",
            ],
            subscribed: true,
            recommended: false
        )
        def.isMenuItem = true

        remoteTopics.append(def)

        return remoteTopics
    }


    // MARK: Tests

    /**
    Ensure that followed sites a user unfollows from are set to unfollowed in core data when merging
    results from the REST API.
    */
    func testUnfollowedSiteIsUnfollowedDuringSync() {
        // Arrange: Setup
        let remoteSites = remoteSiteInfoForTests()
        let service = ReaderTopicService(coreDataStack: contextManager)
        let foo = remoteSites.first as RemoteReaderSiteInfo?

        // Act: Save sites
        var expect = expectation(description: "sites saved expectation")
        service.mergeFollowedSites(remoteSites, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Assert: Sites exist in the context
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderSiteTopic.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "following = YES")
        var count = try! mainContext.count(for: request)
        XCTAssertEqual(count, remoteSites.count, "Number of sites in context did not match expectations")

        // Act: Merge new set of sites
        expect = expectation(description: "sites saved expectation")
        service.mergeFollowedSites([foo!], withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Assert: Unfollowed sites were unfollowed when merged
        count = try! mainContext.count(for: request)
        XCTAssertEqual(count, 1, "Number of sites in context did not match expectations")
        do {
            let results = try mainContext.fetch(request)
            let site = results.first as! ReaderSiteTopic
            XCTAssertEqual(site.feedID, foo?.feedID, "The site returned was not the one expected.")
        } catch let error as NSError {
            XCTAssertNil(error, "Error executing fetch request.")
        }
    }

    /**
    Ensure that topics a user unsubscribes from are removed from core data when merging
    results from the REST API.
    */
    func testUnsubscribedTopicIsRemovedDuringSync() {
        let remoteTopics = remoteTopicsForTests()

        // Setup
        var expect = expectation(description: "topics saved expectation")
        let service = ReaderTopicService(coreDataStack: contextManager)
        service.mergeMenuTopics(remoteTopics, isLoggedIn: true, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Topics exist in the context
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderTagTopic.classNameWithoutNamespaces())
        var count = try! mainContext.count(for: request)
        XCTAssertEqual(count, remoteTopics.count, "Number of topics in context did not match expectations")

        // Merge new set of topics
        expect = expectation(description: "topics saved expectation")
        let foo = remoteTopics.first as RemoteReaderTopic?
        service.mergeMenuTopics([foo!], isLoggedIn: true, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Make sure the missing topics were removed when merged
        count = try! mainContext.count(for: request)
        XCTAssertEqual(count, 1, "Number of topics in context did not match expectations")
        do {
            let results = try mainContext.fetch(request)
            let topic = results.first as! ReaderTagTopic
            XCTAssertEqual(topic.tagID, foo?.topicID, "The topic returned was not the one expected.")
        } catch let error as NSError {
            XCTAssertNil(error, "Error executing fetch request.")
        }
    }

    /**
    Ensure that topics a user subscribes to are added to core data when merging
    results from the REST API.
    */
    func testNewlySubscribedTopicIsAddedDuringSync() {
        let remoteTopics = remoteTopicsForTests()
        let foo = remoteTopics.first

        let startingTopics: [RemoteReaderTopic] = [remoteTopics[1], remoteTopics[2]]

        // Setup
        var expect = expectation(description: "topics saved expectation")
        let service = ReaderTopicService(coreDataStack: contextManager)
        service.mergeMenuTopics(startingTopics, isLoggedIn: true, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Topics exist in context
        let sortDescriptor = NSSortDescriptor(key: "tagID", ascending: true)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderTagTopic.classNameWithoutNamespaces())
        request.sortDescriptors = [sortDescriptor]
        var count = try! mainContext.count(for: request)
        XCTAssertEqual(count, startingTopics.count, "Number of topics in context did not match expectations")

        // Merge new set of topics
        expect = expectation(description: "topics saved expectation")
        service.mergeMenuTopics(remoteTopics, isLoggedIn: true, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // make sure the missing topics were added
        count = try! mainContext.count(for: request)
        XCTAssertEqual(count, remoteTopics.count, "Number of topics in context did not match expectations")

        do {
            let results = try mainContext.fetch(request)
            let topic = results.first as! ReaderTagTopic
            XCTAssertEqual(topic.tagID, foo!.topicID, "The topic returned was not the one expected.")
        } catch let error as NSError {
            XCTAssertNil(error, "Error executing fetch request.")
        }
    }

    /**
    Ensure that a default topic can be set and retrieved.
    */
    func testGettingSettingCurrentTopic() {
        let remoteTopics = remoteAndDefaultTopicForTests()

        // Setup
        let expect = expectation(description: "topics saved expectation")
        let service = ReaderTopicService(coreDataStack: contextManager)
        service.setCurrentTopic(nil)

        // Current topic is not nil after a sync
        service.mergeMenuTopics(remoteTopics, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        XCTAssertNotNil(service.currentTopic, "The current topic was nil.")

        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderAbstractTopic.classNameWithoutNamespaces())
        request.sortDescriptors = [sortDescriptor]

        let results = try! mainContext.fetch(request)

        var topic = results.last as! ReaderAbstractTopic
        XCTAssertEqual(service.currentTopic(in: mainContext).type, ReaderDefaultTopic.TopicType, "The curent topic should have been a default topic")

        topic = results.first as! ReaderAbstractTopic
        service.setCurrentTopic(topic)

        XCTAssertEqual(service.currentTopic(in: mainContext).path, topic.path, "The current topic did not match the topic we assiged to it")
    }

    /**
    Ensure all topics are deleted when an account is changed.
    */
    func testDeleteAllTopics() {
        seedTopics()
        XCTAssertFalse(countTopics() == 0, "The number of seeded topics should not be zero")
        let service = ReaderTopicService(coreDataStack: contextManager)
        service.deleteAllTopics()
        XCTAssertTrue(countTopics() == 0, "The number of seeded topics should be zero")
    }

    /**
    Ensure all the posts belonging to a topic are deleted when the topic is deleted.
    */
    func testPostsDeletedWhenTopicDeleted() {
        // setup
        let topic = NSEntityDescription.insertNewObject(forEntityName: ReaderListTopic.classNameWithoutNamespaces(), into: mainContext) as! ReaderListTopic
        topic.path = "/list/topic"
        topic.title = "topic"
        topic.type = ReaderListTopic.TopicType
        seedPostsForTopic(topic)

        XCTAssertTrue(topic.posts.count == 3, "Topic should have posts relationship with three posts.")

        // Save the new topic + posts in the contet
        var expect = expectation(description: "topics saved expectation")
        contextManager.save(mainContext, completion: {
            expect.fulfill()
        }, on: .global())
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Delete the topic and posts from the context
        mainContext.delete(topic)

        expect = expectation(description: "topics saved expectation")
        contextManager.save(mainContext, completion: {
            expect.fulfill()
        }, on: .global())
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderListTopic.classNameWithoutNamespaces())
        let count = try! mainContext.count(for: request)
        XCTAssertTrue(count == 0, "Topic was not deleted successfully")

        let postRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderPost.classNameWithoutNamespaces())
        let postRequestCount = try! mainContext.count(for: postRequest)
        print("pistRequestCount ", postRequestCount)
        XCTAssertTrue(count == 0, "Topic posts were not deleted successfully")
    }

    func testTopicTitleFormatting() {
        let service = ReaderTopicService(coreDataStack: contextManager)

        var unformatted = "WordPress"
        var formatted = service.formatTitle(unformatted)
        XCTAssertTrue(formatted == unformatted, "WordPress should have maintained its case")

        // Lowercase should be capitalized
        unformatted = "art & entertainment"
        formatted = service.formatTitle(unformatted)
        XCTAssertTrue(formatted == "Art & Entertainment", "Lower cased words should be capitalized")

        // Special consideration for the casing of "techy" words like iPhone and ePaper.
        unformatted = "iPhone"
        formatted = service.formatTitle(unformatted)
        XCTAssertTrue(formatted == unformatted, "iPhone should have maintained its case")

        unformatted = "ePaper"
        formatted = service.formatTitle(unformatted)
        XCTAssertTrue(formatted == unformatted, "ePaper should have maintained its case")

        // All caps stays all caps.
        unformatted = "VINE"
        formatted = service.formatTitle(unformatted)
        XCTAssertTrue(formatted == unformatted, "VINE should have remained all caps")
    }

    func testReaderSearchTopicCreated() {
        let service = ReaderTopicService(coreDataStack: contextManager)

        let phrase = "coffee talk"
        waitUntil { done in
            service.createSearchTopic(forSearchPhrase: phrase) { objectID in
                guard let objectID else {
                    XCTFail("A nil object id is returned")
                    return
                }

                let topic = try? self.mainContext.existingObject(with: objectID) as? ReaderSearchTopic
                XCTAssertEqual(topic?.type, "search")

                done()
            }
        }
    }
}
