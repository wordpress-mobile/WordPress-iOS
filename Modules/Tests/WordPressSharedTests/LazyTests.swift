import Testing
@testable import WordPressShared

final class LazyTests {
    @Lazy
    var container = Container()

    final class Container {
        static var initCallCount = 0

        var name = "hello"

        init() {
            Container.initCallCount += 1
        }
    }

    deinit {
        Container.initCallCount = 0
    }

    @Test func testLazyProperty() {
        #expect(Container.initCallCount == 0, "Has to be created lazily")

        // Accessing value without triggering init
        #expect($container.value == nil)
        #expect(Container.initCallCount == 0, "Accessing the projected value should not trigger init")

        // Accessing value while initializing it lazily
        #expect(container.name == "hello")
        #expect($container.value != nil)
        #expect(Container.initCallCount == 1)

        // Using the cached value
        container.name = "here goes nothing"
        #expect(Container.initCallCount == 1, "Lazily created value is retained")

        // Resetting the value
        $container.reset()
        #expect($container.value == nil)
    }
}
