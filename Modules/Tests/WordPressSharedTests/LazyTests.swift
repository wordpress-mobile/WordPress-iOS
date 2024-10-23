import XCTest
@testable import WordPressShared

class LazyTests: XCTestCase {
    @Lazy
    var container = Container()

    final class Container {
        static var initCallCount = 0

        var name = "hello"

        init() {
            Container.initCallCount += 1
        }
    }

    override func tearDown() {
        super.tearDown()

        Container.initCallCount = 0
    }

    func testLazyProperty() {
        XCTAssertEqual(Container.initCallCount, 0, "Has to be created lazily")

        // Accessing value without triggering init
        XCTAssertNil($container.value)
        XCTAssertEqual(Container.initCallCount, 0, "Accessing the projected value should not trigger init")

        // Accessing value while initializing it lazily
        XCTAssertEqual(container.name, "hello")
        XCTAssertNotNil($container.value)
        XCTAssertEqual(Container.initCallCount, 1)

        // Using the cached value
        container.name = "here goes nothing"
        XCTAssertEqual(Container.initCallCount, 1, "Lazily created value is retained")

        // Resetting the value
        $container.reset()
        XCTAssertNil($container.value)
    }
}
