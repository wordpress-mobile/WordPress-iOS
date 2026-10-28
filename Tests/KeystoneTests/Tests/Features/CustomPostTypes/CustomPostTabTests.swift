import Testing
import WordPressAPI
@testable import WordPress

struct CustomPostTabTests {
    @Test func allTabSortsByPostDate() {
        #expect(CustomPostTab.all.orderby == .date)
        #expect(CustomPostListFilter(tab: .all).orderby == .date)
    }
}
