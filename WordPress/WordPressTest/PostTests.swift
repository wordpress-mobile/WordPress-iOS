import Foundation
import XCTest

@testable import WordPress

class PostTests: XCTestCase {

    private let context: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.parentContext = TestContextManager.sharedInstance().mainContext

        return context
    }()

    private func newTestBlog() -> Blog {
        return NSEntityDescription.insertNewObjectForEntityForName(BlogEntityName, inManagedObjectContext: context) as! Blog
    }

    private func newTestPost() -> Post {
        return NSEntityDescription.insertNewObjectForEntityForName(PostEntityName, inManagedObjectContext: context) as! Post
    }

    private func newTestPostCategory() -> PostCategory {
        return NSEntityDescription.insertNewObjectForEntityForName(PostCategoryEntityName, inManagedObjectContext: context) as! PostCategory
    }

    private func newTestPostCategory(name: String) -> PostCategory {
        let category = newTestPostCategory()
        category.categoryName = name

        return category
    }

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        context.rollback()
        super.tearDown()
    }

    func testThatNoCategoriesReturnEmptyStringWhenCallingCategoriesText() {
        let post = newTestPost()
        let categoriesText = post.categoriesText()

        XCTAssert(categoriesText == "")
    }

    func testThatSomeCategoriesReturnAListWhenCallingCategoriesText() {

        let post = newTestPost()

        post.categories = [newTestPostCategory("1"), newTestPostCategory("2"), newTestPostCategory("3")]

        let categoriesText = post.categoriesText()

        XCTAssert(categoriesText == "1, 2, 3")
    }

    func testSetCategoriesFromNamesWithTwoCategories() {
        let blog = newTestBlog()
        let post = newTestPost()

        let category1 = newTestPostCategory("One")
        let category2 = newTestPostCategory("Two")
        let category3 = newTestPostCategory("Three")

        blog.categories = [category1, category2, category3]

        post.blog = blog
        post.setCategoriesFromNames(["One", "Three"])

        let postCategories = post.categories as! Set<PostCategory>
        XCTAssert(postCategories.count == 2)
        XCTAssert(postCategories.contains(category1))
        XCTAssert(!postCategories.contains(category2))
        XCTAssert(postCategories.contains(category3))
    }

    func testThatSettingNilLikeCountReturnsZeroNumberOfLikes() {
        let post = newTestPost()

        post.likeCount = nil

        XCTAssert(post.numberOfLikes() == 0)
    }

    func testThatSettingLikeCountAffectsNumberOfLikes() {
        let post = newTestPost()

        post.likeCount = 2

        XCTAssert(post.numberOfLikes() == 2)
    }

    func testThatSettingNilCommentCountReturnsZeroNumberOfComments() {
        let post = newTestPost()

        post.commentCount = nil

        XCTAssert(post.numberOfComments() == 0)
    }

    func testThatSettingCommentCountAffectsNumberOfComments() {
        let post = newTestPost()

        post.commentCount = 2

        XCTAssert(post.numberOfComments() == 2)
    }

    func testThatAddCategoriesWorks() {
        let post = newTestPost()
        let testCategories = Set([newTestPostCategory("1"), newTestPostCategory("2"), newTestPostCategory("3")])

        post.addCategories(testCategories)

        guard let postCategories = post.categories else {
            XCTFail("post.categories should not be nil here.")
            return
        }

        XCTAssert(postCategories.count == testCategories.count)

        for testCategory in testCategories {
            XCTAssert(postCategories.contains(testCategory))
        }
    }

    func testThatAddCategoriesObjectWorks() {
        let post = newTestPost()
        let testCategory = newTestPostCategory("1")

        post.addCategoriesObject(testCategory)

        guard let postCategories = post.categories else {
            XCTFail("post.categories should not be nil here.")
            return
        }

        XCTAssert(postCategories.count == 1)
        XCTAssert(postCategories.contains(testCategory))
    }

    func testThatRemoveCategoriesWorks() {
        let post = newTestPost()
        let testCategories = Set<PostCategory>(arrayLiteral: newTestPostCategory("1"), newTestPostCategory("2"), newTestPostCategory("3"))

        post.categories = testCategories
        XCTAssert(post.categories?.count != 0 && post.categories?.count == testCategories.count)

        post.removeCategories(testCategories)
        XCTAssert(post.categories?.count == 0)
    }

    func testThatRemoveCategoriesObjectWorks() {
        let post = newTestPost()
        let testCategory = newTestPostCategory("1")

        post.categories = Set<PostCategory>(arrayLiteral: testCategory)
        XCTAssert(post.categories?.count == 1)

        post.removeCategoriesObject(testCategory)
        XCTAssert(post.categories?.count == 0)
    }

}
