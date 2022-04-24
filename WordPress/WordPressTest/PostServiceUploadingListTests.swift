import UIKit
import XCTest
import Nimble

@testable import WordPress

/// Test cases for PostService.markAsFailedAndDraftIfNeeded()
class PostServiceUploadingListTests: XCTestCase {

    private var contextManager: ContextManagerMock!
    private var context: NSManagedObjectContext! {
        contextManager.mainContext
    }

    override func setUp() {
        super.setUp()
        contextManager = ContextManagerMock()
    }

    override func tearDown() {
        super.tearDown()
        contextManager.tearDown()
    }

    /// Returns true if a single post is added to the list
    ///
    func testReturnTrueForSingleUpload() {
        let post = PostBuilder(context).build()
        let uploadingList = PostServiceUploadingList.shared

        uploadingList.uploading(post.objectID)

        expect(uploadingList.isSingleUpload(post.objectID)).to(beTrue())
    }

    /// Returns false if the same post is added twice to the list
    ///
    func testReturnFalseForMultipleUpload() {
        let post = PostBuilder(context).build()
        let uploadingList = PostServiceUploadingList.shared

        uploadingList.uploading(post.objectID)
        uploadingList.uploading(post.objectID)

        expect(uploadingList.isSingleUpload(post.objectID)).to(beFalse())
    }

    /// If a post is added twice and then the upload of one finishes, return true
    ///
    func testReturnTrueForMultipleUploadIfOneOfThemIsRemoved() {
        let post = PostBuilder(context).build()
        let uploadingList = PostServiceUploadingList.shared

        uploadingList.uploading(post.objectID)
        uploadingList.uploading(post.objectID)
        uploadingList.finishedUploading(post.objectID)

        expect(uploadingList.isSingleUpload(post.objectID)).to(beTrue())
    }
}
