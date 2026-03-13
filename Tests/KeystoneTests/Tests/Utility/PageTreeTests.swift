import Testing

@testable import WordPress

struct PageTreeTests {

    private struct MockPost: HierarchicalPost {
        var id: Int64 { postId }
        var postId: Int64
        var parentPostId: Int64 = 0
        var order: Int64 = 0
    }

    @Test func flatList() {
        let posts = [
            MockPost(postId: 1),
            MockPost(postId: 2),
            MockPost(postId: 3),
        ]
        let result = PageTree.buildHierarchy(from: posts)
        #expect(result.count == 3)
        #expect(result.map(\.id) == [1, 2, 3])
        #expect(result.allSatisfy { $0.indentationLevel == 0 })
        #expect(result.allSatisfy { !$0.hasVisibleParent })
    }

    @Test func parentWithChildren() {
        let posts = [
            MockPost(postId: 1),
            MockPost(postId: 2, parentPostId: 1),
            MockPost(postId: 3, parentPostId: 1),
            MockPost(postId: 4),
        ]
        let result = PageTree.buildHierarchy(from: posts)
        #expect(result.map(\.id) == [1, 2, 3, 4])
        #expect(result.map(\.indentationLevel) == [0, 1, 1, 0])
        #expect(!result[0].hasVisibleParent)
        #expect(result[1].hasVisibleParent)
        #expect(result[2].hasVisibleParent)
        #expect(!result[3].hasVisibleParent)
    }

    @Test func nestedHierarchy() {
        let posts = [
            MockPost(postId: 1),
            MockPost(postId: 2, parentPostId: 1),
            MockPost(postId: 3, parentPostId: 2),
        ]
        let result = PageTree.buildHierarchy(from: posts)
        #expect(result.map(\.id) == [1, 2, 3])
        #expect(result.map(\.indentationLevel) == [0, 1, 2])
    }

    @Test func orphanedPostsBecomeTopLevel() {
        let posts = [
            MockPost(postId: 1),
            MockPost(postId: 2, parentPostId: 999),
        ]
        let result = PageTree.buildHierarchy(from: posts)
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.indentationLevel == 0 })
    }

    @Test func childBeforeParent() {
        let posts = [
            MockPost(postId: 2, parentPostId: 1),
            MockPost(postId: 1),
        ]
        let result = PageTree.buildHierarchy(from: posts)
        #expect(result.map(\.id) == [1, 2])
        #expect(result.map(\.indentationLevel) == [0, 1])
    }

    @Test func childrenSortedByOrder() {
        let posts = [
            MockPost(postId: 1),
            MockPost(postId: 2, parentPostId: 1, order: 3),
            MockPost(postId: 3, parentPostId: 1, order: 1),
            MockPost(postId: 4, parentPostId: 1, order: 2),
        ]
        let result = PageTree.buildHierarchy(from: posts)
        #expect(result.map(\.id) == [1, 3, 4, 2])
    }

    @Test func emptyInput() {
        let result = PageTree.buildHierarchy(from: [MockPost]())
        #expect(result.isEmpty)
    }
}
