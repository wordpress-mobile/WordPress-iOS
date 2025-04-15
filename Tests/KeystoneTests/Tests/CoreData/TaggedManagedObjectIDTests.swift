import Foundation
import XCTest

@testable import WordPress

class TaggedManagedObjectIDTests: CoreDataTestCase {

    func testQuerySaved() throws {
        let post = PostBuilder(contextManager.mainContext).with(title: "Test post").build()
        try contextManager.mainContext.save()

        let id = TaggedManagedObjectID(post)
        let result = try contextManager.mainContext.existingObject(with: id)
        XCTAssertEqual(result.postTitle, "Test post")
    }

    func testQueryUnsaved() throws {
        let post = PostBuilder(contextManager.mainContext).with(title: "Test post").build()
        let id = TaggedManagedObjectID(post)

        try contextManager.mainContext.save()

        let newContext = contextManager.newDerivedContext()
        let result = try newContext.existingObject(with: id)
        XCTAssertEqual(result.postTitle, "Test post")
    }

    func testQueryUnsavedUsingTheSameContext() throws {
        let context = contextManager.mainContext
        let post = PostBuilder(context).with(title: "Test post").build()
        let id = TaggedManagedObjectID(post)

        let result = try context.existingObject(with: id)
        XCTAssertEqual(result.postTitle, "Test post")
    }

    func testQueryUnsavedUsingDifferentContext() throws {
        let post = PostBuilder(contextManager.mainContext).build()
        let id = TaggedManagedObjectID(post)

        let newContext = contextManager.newDerivedContext()

        XCTAssertThrowsError(try newContext.existingObject(with: id), "The query should fail because the model is not saved")
    }

    func testEqutable() throws {
        let post = PostBuilder(contextManager.mainContext).with(title: "Test post").build()
        let unsaveID = TaggedManagedObjectID(post)
        try contextManager.mainContext.save()
        let savedID = TaggedManagedObjectID(post)

        XCTAssertEqual(unsaveID, savedID)
        XCTAssertEqual(TaggedManagedObjectID(post), savedID)
    }

}

// MARK: – Covariance workaround demo

extension TaggedManagedObjectIDTests {

    // Covariance is the ability to use a more derived type (a subclass) in place of a less derived type (a superclass).
    //
    // When we declare a generic type like `TaggedManagedObjectID<Model>`, we lose type-hierarchy information of the
    // generic parameter `Model`. That means the compiler will not accept a `TaggedManagedObjectID<Post>` instance for
    // a parameter defined as `TaggedManagedObjectID<AbstractPost>` even though `Post` is a subtype of `AbstractPost`.
    //
    // However, Swift compiler has special treatment for its standard library types like `Array` and `Set`: You can pass
    // an `Array<Post>` instance for a parameter defined as `Array<AbstractPost>`.
    //
    // Here is a `swift repl` output to demostrate this Swift feature:
    //
    // ```
    // $ swift repl
    // Welcome to Apple Swift version 5.8.1 (swiftlang-5.8.0.124.5 clang-1403.0.22.11.100).
    // Type :help for assistance.
    //   1> class Parent {}
    //   2> class Child: Parent {}
    //   3> print(Child() is Parent)
    // true
    //   4> struct Foo<T> {}
    //   5> print(Foo<Child>() is Foo<Parent>)
    // false
    //   6> print(Array<Child>() is Array<Parent>)
    // true
    // ```
    //
    // We don't get any special treatment from Swift compiler, so we'll have to make our own workaround, since it's
    // not uncommon to declare a function which accepts `NSManagedObjectID` instances of a certain type and its subtypes.
    //
    // Below is a demonstration of how to work around this limitation by using a generic function.

    // If this test compiles, then the overload definition (see below) works.

    // This is not really a test. More like a demostration of how to workaround Swift compiler's covariance support.
    func testCovariance() throws {
        let post = PostBuilder(contextManager.mainContext).with(author: "WordPress.com").build()
        try contextManager.mainContext.save()

        let postID: TaggedManagedObjectID<Post> = .init(post)
        let abstractPostID: TaggedManagedObjectID<AbstractPost> = .init(post)

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
