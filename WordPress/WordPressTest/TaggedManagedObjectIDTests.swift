import Foundation
import XCTest

@testable import WordPress

class TaggedManagedObjectIDTests: CoreDataTestCase {

    func testQuerySaved() throws {
        let post = PostBuilder(contextManager.mainContext).with(title: "Test post").build()
        try contextManager.mainContext.save()

        let id = TaggedManagedObjectID(saved: post)
        let result = try contextManager.mainContext.existingObject(with: id)
        XCTAssertEqual(result.postTitle, "Test post")
    }

    func testQueryUnsaved() throws {
        let post = PostBuilder(contextManager.mainContext).with(title: "Test post").build()
        let id = try TaggedManagedObjectID(unsaved: post)

        try contextManager.mainContext.save()

        let newContext = contextManager.newDerivedContext()
        let result = try newContext.existingObject(with: id)
        XCTAssertEqual(result.postTitle, "Test post")
    }

    func testQueryUnsavedUsingTheSameContext() throws {
        let context = contextManager.mainContext
        let post = PostBuilder(context).with(title: "Test post").build()
        let id = try TaggedManagedObjectID(unsaved: post)

        let result = try context.existingObject(with: id)
        XCTAssertEqual(result.postTitle, "Test post")
    }

    func testQueryUnsavedUsingDifferentContext() throws {
        let post = PostBuilder(contextManager.mainContext).build()
        let id = try TaggedManagedObjectID(unsaved: post)

        let newContext = contextManager.newDerivedContext()

        let expectation = expectation(description: "The query should fail because the model is not saved")
        do {
            _ = try newContext.existingObject(with: id)
        } catch {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
    }

    func testEqutable() throws {
        let post = PostBuilder(contextManager.mainContext).with(title: "Test post").build()
        let unsaveID = try TaggedManagedObjectID(unsaved: post)
        try contextManager.mainContext.save()
        let savedID = TaggedManagedObjectID(saved: post)

        XCTAssertEqual(unsaveID, savedID)
        XCTAssertEqual(TaggedManagedObjectID(saved: post), savedID)
    }

    // This is not really a test. More like a demostration of how to workaround Swift compiler's covariance support.
    func testCovariance() throws {
        let post = PostBuilder(contextManager.mainContext).with(author: "WordPress.com").build()
        try contextManager.mainContext.save()

        let postID: TaggedManagedObjectID<Post> = .init(saved: post)
        let abstractPostID: TaggedManagedObjectID<AbstractPost> = .init(saved: post)

        // This line does not compile without the second `author(of:in:)` overload.
        try XCTAssertEqual(author(of: postID, in: contextManager.mainContext), "WordPress.com")
        try XCTAssertEqual(author(of: abstractPostID, in: contextManager.mainContext), "WordPress.com")
    }

    // This function does not accept `TaggedManagedObjectID<Post>` argument, because `TaggedManagedObjectID<Post>` is
    // not a subtype of `TaggedManagedObjectID<AbstractPost>` even though `Post` is a subtype of `AbstractPost`.
    //
    // But sometimes, we do want to declare a function that accepts object id of all `AbstractPost` types. In those cases,
    // we can declare them in another way: see the function below.
    private func author(of id: TaggedManagedObjectID<AbstractPost>, in context: NSManagedObjectContext) throws -> String? {
        try context.existingObject(with: id).author
    }

    // This function accepts all `TaggedManagedObjectID` instances that are created from all `AbstractPost` types.
    private func author<T: AbstractPost>(of id: TaggedManagedObjectID<T>, in context: NSManagedObjectContext) throws -> String? {
        try context.existingObject(with: id).author
    }

}
