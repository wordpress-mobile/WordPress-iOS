import XCTest
@testable import WordPress

class BlogTitleTests: CoreDataTestCase {

    private var blog: Blog!

    override func setUp() {
        blog = BlogBuilder(mainContext).with(url: Constants.blogURL).build()
    }

    func testBlogTitleIsName() throws {
        // Given a blog
        // When blogName is a string
        let blogName = "my blog name"
        blog.settings = newSettings()
        blog.settings?.name = blogName

        // Then blogTitle is blogName
        XCTAssertEqual(blog.title, blogName)
    }

    func testBlogSettingsNameIsNil() throws {
        // Given a blog
        // When blogName is nil
        blog.settings = newSettings()
        blog.settings?.name = nil

        // Then blogTitle is blogDisplayURL
        XCTAssertEqual(blog.title, Constants.blogDisplayURL)
    }

    func testBlogTitleIsDisplayURLWhenTitleNil() throws {
        // Given a blog
        // When a blog has no blogSettings
        // Then blogTitle is blogDisplayURL
        XCTAssertEqual(blog.title, Constants.blogDisplayURL)
    }

    // MARK: - Private Helpers
    fileprivate func newSettings() -> BlogSettings {
        let name = BlogSettings.classNameWithoutNamespaces()
        let entity = NSEntityDescription.insertNewObject(forEntityName: name, into: mainContext)

        return entity as! BlogSettings
    }
}

private extension BlogTitleTests {
    enum Constants {
        static let blogDisplayURL: String = "wordpress.com"
        static let blogURL: String = "http://wordpress.com"
    }
}
