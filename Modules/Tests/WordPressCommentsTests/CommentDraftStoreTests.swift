import Foundation
import Testing
@testable import WordPressComments

@MainActor
struct CommentDraftStoreTests {
    private func makeStore(namespace: String = "site|user") -> UserDefaultsCommentDraftStore {
        let defaults = UserDefaults(suiteName: "CommentDraftStoreTests-\(UUID().uuidString)")!
        return UserDefaultsCommentDraftStore(namespace: namespace, defaults: defaults)
    }

    @Test func saveAndLoadRoundTrip() {
        let store = makeStore()
        store.saveDraft("hello", commentID: 7)
        let loaded = store.loadDraft(commentID: 7)
        #expect(loaded == "hello")
    }

    @Test func loadMissingReturnsNil() {
        let store = makeStore()
        let loaded = store.loadDraft(commentID: 1)
        #expect(loaded == nil)
    }

    @Test func deleteRemovesDraft() {
        let store = makeStore()
        store.saveDraft("hello", commentID: 3)
        store.deleteDraft(commentID: 3)
        let loaded = store.loadDraft(commentID: 3)
        #expect(loaded == nil)
    }

    @Test func draftsAreScopedByCommentID() {
        let store = makeStore()
        store.saveDraft("hello", commentID: 1)
        let loaded = store.loadDraft(commentID: 2)
        #expect(loaded == nil)
    }

    @Test func namespaceLowercasesSchemeAndHostButNotPath() {
        let namespace = UserDefaultsCommentDraftStore.namespace(
            siteURL: URL(string: "HTTPS://Example.COM/Blog")!,
            username: "Admin"
        )
        #expect(namespace == "https://example.com/Blog|Admin")
    }

    @Test func draftsAreScopedByNamespace() {
        let defaults = UserDefaults(suiteName: "CommentDraftStoreTests-\(UUID().uuidString)")!
        let store1 = UserDefaultsCommentDraftStore(namespace: "site1|user1", defaults: defaults)
        let store2 = UserDefaultsCommentDraftStore(namespace: "site2|user2", defaults: defaults)

        store1.saveDraft("draft1", commentID: 1)
        store2.saveDraft("draft2", commentID: 1)

        #expect(store1.loadDraft(commentID: 1) == "draft1")
        #expect(store2.loadDraft(commentID: 1) == "draft2")
    }
}
