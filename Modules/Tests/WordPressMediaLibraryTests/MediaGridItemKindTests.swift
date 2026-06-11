import Testing
import WordPressAPI
import WordPressAPIInternal

@testable import WordPressMediaLibrary

struct MediaGridItemKindTests {
    @Test func failedWithoutDataHasUnknownKind() {
        let item = MediaGridItem(item: MediaItemBuilder.failedNoData(id: 1))
        #expect(item.kind == nil)
    }

    @Test func missingHasUnknownKind() {
        let item = MediaGridItem(item: MediaItemBuilder.missing(id: 2))
        #expect(item.kind == nil)
    }
}
