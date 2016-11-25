import Foundation
import XCTest
import CoreData
@testable import WordPress

extension ReaderPost: ManagedObject {
    @nonobjc static let entityName = "ReaderPost"
}

extension SourcePostAttribution: ManagedObject {
    @nonobjc static let entityName = "SourcePostAttribution"
}

class ReaderPostCacheProviderTests: XCTestCase {

    var context: NSManagedObjectContext!
    var postHelper: CoreDataHelper<ReaderPost>!
    var cacheProvider: ReaderPostCacheProvider!

    override func setUp() {

        super.setUp()
        context = TestContextManager.sharedInstance().mainContext
        postHelper = CoreDataHelper<ReaderPost>(context: context)
        cacheProvider = ReaderPostCacheProvider(context: context)
    }

    func testCouldntFindNormalPost() {

        let cachedPost = cacheProvider.getPostByID(9999, siteID: 10000)
        XCTAssertNil(cachedPost)
    }

    func testGetNormalPost() {

        let insertedPost = insertNormalPostWithID(1, siteID: 2)
        let cachedPost = cacheProvider.getPostByID(1, siteID: 2)
        XCTAssertEqual(insertedPost, cachedPost)
    }

    func testGetCrossPost() {

        let insertedPost = insertCrossPostWithID(10, siteID: 20)
        let cachedPost = cacheProvider.getPostByID(10, siteID: 20)
        XCTAssertEqual(insertedPost, cachedPost)
    }

    func testGetAttributionPost() {

        let insertedPost = insertAttributionPostWithID(20, siteID: 30)
        let cachedPost = cacheProvider.getPostByID(20, siteID: 30)
        XCTAssertEqual(insertedPost, cachedPost)
    }

    func insertNormalPostWithID(postID: Int, siteID: Int) -> ReaderPost {

        let post = postHelper.insertNewObject()
        post.postID = postID
        post.siteID = siteID
        _ = try? context.save()
        return post
    }

    func insertAttributionPostWithID(postID: Int, siteID: Int) -> ReaderPost {

        let attributionHelper = CoreDataHelper<SourcePostAttribution>(context: context)
        let attribution = attributionHelper.insertNewObject()
        attribution.postID = postID
        attribution.blogID = siteID

        let post = postHelper.insertNewObject()
        post.sourceAttribution = attribution

        _ = try? context.save()
        return post
    }

    func insertCrossPostWithID(postID: Int, siteID: Int) -> ReaderPost {

        let crossHelper = CoreDataHelper<ReaderCrossPostMeta>(context: context)
        let cross = crossHelper.insertNewObject()
        cross.postID = postID
        cross.siteID = siteID

        let post = postHelper.insertNewObject()
        post.crossPostMeta = cross

        _ = try? context.save()
        return post
    }
}
