import XCTest
import Foundation
import CoreData
import WordPress

final class ReaderTopicSwiftTest: XCTestCase {

    private var testContextManager: TestContextManager?
    private var context: NSManagedObjectContext?
    let expectationTimeout = 5.0

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        testContextManager = TestContextManager.sharedInstance()
        context = testContextManager?.mainContext
    }

    override func tearDown() {
        context = nil
        TestContextManager.overrideSharedInstance(nil)
        testContextManager = nil
        super.tearDown()
    }

    // MARK: - Config / Helpers

    func seedTopics() {
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }

        let topic1 = NSEntityDescription.insertNewObject(forEntityName: ReaderListTopic.classNameWithoutNamespaces(), into: context) as! ReaderListTopic
        topic1.path = "/list/topic1"
        topic1.title = "topic1"
        topic1.type = ReaderListTopic.TopicType

        let topic2 = NSEntityDescription.insertNewObject(forEntityName: ReaderTagTopic.classNameWithoutNamespaces(), into: context) as! ReaderTagTopic
        topic2.path = "/tags/topic2"
        topic2.title = "topic2"
        topic2.type = ReaderTagTopic.TopicType

        let topic3 = NSEntityDescription.insertNewObject(forEntityName: ReaderTagTopic.classNameWithoutNamespaces(), into: context) as! ReaderTagTopic
        topic3.path = "/list/topic3"
        topic3.title = "topic3"
        topic3.type = ReaderTagTopic.TopicType

        do {
            try context.save()
        } catch let error as NSError {
            XCTAssertNil(error, "Error seeding topics")
        }
    }

    func countTopics() -> Int {
        guard let context = context else {
            XCTFail("Context is nil")
            return 0
        }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderAbstractTopic.classNameWithoutNamespaces())
        return try! context.count(for: request)
    }

    func seedPostsForTopic(_ topic: ReaderAbstractTopic) {
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }

        let post1 = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.classNameWithoutNamespaces(), into: context) as! ReaderPost
        post1.postID = NSNumber(value: 1)
        post1.postTitle = "post1"
        post1.content = "post1"
        post1.topic = topic

        let post2 = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.classNameWithoutNamespaces(), into: context) as! ReaderPost
        post2.postID = NSNumber(value: 2)
        post2.postTitle = "post2"
        post2.content = "post2"
        post2.topic = topic

        let post3 = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.classNameWithoutNamespaces(), into: context) as! ReaderPost
        post3.postID = NSNumber(value: 3)
        post3.postTitle = "post3"
        post3.content = "post3"
        post3.topic = topic

        do {
            try context.save()
        } catch let error as NSError {
            XCTAssertNil(error, "Error seeding posts")
        }
    }

    func remoteTopicsForTests() -> [RemoteReaderTopic] {
        let foo = RemoteReaderTopic()
        foo.topicID = 1
        foo.title = "foo"
        foo.path = "/tags/foo"
        foo.isSubscribed = true
        foo.isMenuItem = true

        let bar = RemoteReaderTopic()
        bar.topicID = 2
        bar.title = "bar"
        bar.path = "/tags/bar"
        bar.isSubscribed = true
        bar.isMenuItem = true

        let baz = RemoteReaderTopic()
        baz.topicID = 3
        baz.title = "baz"
        baz.path = "/tags/baz"
        baz.isSubscribed = true
        baz.isMenuItem = true

        return [foo, bar, baz]
    }

    func remoteAndDefaultTopicForTests() -> [RemoteReaderTopic] {
        var remoteTopics = remoteTopicsForTests()

        let def = RemoteReaderTopic()
        def.topicID = 4
        def.title = "def"
        def.path = "/def"
        def.isSubscribed = true
        def.isMenuItem = true

        remoteTopics.append(def)

        return remoteTopics
    }


    // MARK: Tests

    /**
    Ensure that topics a user unsubscribes from are removed from core data when merging
    results from the REST API.
    */
    func testUnsubscribedTopicIsRemovedDuringSync() {
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }
        let remoteTopics = remoteTopicsForTests()

        // Setup
        var expect = expectation(description: "topics saved expectation")
        let service = ReaderTopicService(managedObjectContext: context)
        service.mergeMenuTopics(remoteTopics, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Topics exist in the context
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderTagTopic.classNameWithoutNamespaces())
        var count = try! context.count(for: request)
        XCTAssertEqual(count, remoteTopics.count, "Number of topics in context did not match expectations")

        // Merge new set of topics
        expect = expectation(description: "topics saved expectation")
        let foo = remoteTopics.first as RemoteReaderTopic?
        service.mergeMenuTopics([foo!], withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Make sure the missing topics were removed when merged
        count = try! context.count(for: request)
        XCTAssertEqual(count, 1, "Number of topics in context did not match expectations")
        do {
            let results = try context.fetch(request)
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
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }
        let remoteTopics = remoteTopicsForTests()
        let foo = remoteTopics.first

        let startingTopics: [RemoteReaderTopic] = [remoteTopics[1], remoteTopics[2]]

        // Setup
        var expect = expectation(description: "topics saved expectation")
        let service = ReaderTopicService(managedObjectContext: context)
        service.mergeMenuTopics(startingTopics, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Topics exist in context
        let sortDescriptor = NSSortDescriptor(key: "tagID", ascending: true)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderTagTopic.classNameWithoutNamespaces())
        request.sortDescriptors = [sortDescriptor]
        var count = try! context.count(for: request)
        XCTAssertEqual(count, startingTopics.count, "Number of topics in context did not match expectations")

        // Merge new set of topics
        expect = expectation(description: "topics saved expectation")
        service.mergeMenuTopics(remoteTopics, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // make sure the missing topics were added
        count = try! context.count(for: request)
        XCTAssertEqual(count, remoteTopics.count, "Number of topics in context did not match expectations")

        do {
            let results = try context.fetch(request)
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
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }
        let remoteTopics = remoteAndDefaultTopicForTests()

        // Setup
        let expect = expectation(description: "topics saved expectation")
        let service = ReaderTopicService(managedObjectContext: context)
        service.currentTopic = nil

        // Current topic is not nil after a sync
        service.mergeMenuTopics(remoteTopics, withSuccess: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        XCTAssertNotNil(service.currentTopic, "The current topic was nil.")

        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderAbstractTopic.classNameWithoutNamespaces())
        request.sortDescriptors = [sortDescriptor]

        let results = try! context.fetch(request)

        var topic = results.last as! ReaderAbstractTopic
        XCTAssertEqual(service.currentTopic.type, ReaderDefaultTopic.TopicType, "The curent topic should have been a default topic")

        topic = results.first as! ReaderAbstractTopic
        service.currentTopic = topic

        XCTAssertEqual(service.currentTopic.path, topic.path, "The current topic did not match the topic we assiged to it")
    }

    /**
    Ensure all topics are deleted when an account is changed.
    */
    func testDeleteAllTopics() {
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }
        seedTopics()
        XCTAssertFalse(countTopics() == 0, "The number of seeded topics should not be zero")
        let service = ReaderTopicService(managedObjectContext: context)
        service.deleteAllTopics()
        XCTAssertTrue(countTopics() == 0, "The number of seeded topics should be zero")
    }

    /**
    Ensure all the posts belonging to a topic are deleted when the topic is deleted.
    */
    func testPostsDeletedWhenTopicDeleted() {
        // setup
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }
        let topic = NSEntityDescription.insertNewObject(forEntityName: ReaderListTopic.classNameWithoutNamespaces(), into: context) as! ReaderListTopic
        topic.path = "/list/topic"
        topic.title = "topic"
        topic.type = ReaderListTopic.TopicType
        seedPostsForTopic(topic)

        XCTAssertTrue(topic.posts.count == 3, "Topic should have posts relationship with three posts.")

        // Save the new topic + posts in the contet
        var expect = expectation(description: "topics saved expectation")
        testContextManager?.save(context, withCompletionBlock: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        // Delete the topic and posts from the context
        context.delete(topic)

        expect = expectation(description: "topics saved expectation")
        testContextManager?.save(context, withCompletionBlock: { () -> Void in
            expect.fulfill()
        })
        waitForExpectations(timeout: expectationTimeout, handler: nil)

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderListTopic.classNameWithoutNamespaces())
        let count = try! context.count(for: request)
        XCTAssertTrue(count == 0, "Topic was not deleted successfully")

        let postRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderPost.classNameWithoutNamespaces())
        let postRequestCount = try! context.count(for: postRequest)
        print("pistRequestCount ", postRequestCount)
        XCTAssertTrue(count == 0, "Topic posts were not deleted successfully")
    }

    func testTopicTitleFormatting() {
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }
        let service = ReaderTopicService(managedObjectContext: context)

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
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }
        let service = ReaderTopicService(managedObjectContext: context)

        let phrase = "coffee talk"
        let topic = service.searchTopic(forSearchPhrase: phrase)

        XCTAssert(topic?.type == "search")
    }
}
