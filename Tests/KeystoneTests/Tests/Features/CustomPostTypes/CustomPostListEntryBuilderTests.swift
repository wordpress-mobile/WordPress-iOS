import Foundation
import Testing

@testable import WordPress

@Suite("CustomPostListEntryBuilder")
struct CustomPostListEntryBuilderTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private var grouper: CustomPostDateGrouper {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return CustomPostDateGrouper(now: now, calendar: calendar, locale: Locale(identifier: "en_US"))
    }

    private func item(id: Int64, daysAgo: Double, modifiedDaysAgo: Double? = nil) -> CustomPostCollectionItem {
        let post = CustomPostCollectionDisplayPost(
            date: now.addingTimeInterval(-daysAgo * 86_400),
            modifiedDate: modifiedDaysAgo.map { now.addingTimeInterval(-$0 * 86_400) },
            title: "Post \(id)",
            content: nil
        )
        return CustomPostCollectionItem(id: id, post: post, state: .loading)
    }

    private func entries(
        _ items: [CustomPostCollectionItem],
        showsDateGroups: Bool = true
    ) -> [CustomPostListEntry] {
        CustomPostListEntryBuilder.entries(
            from: items,
            showsDateGroups: showsDateGroups,
            grouper: grouper
        )
    }

    @Test("a header opens each new group")
    func headersOnGroupChange() {
        let result = entries([item(id: 1, daysAgo: 1), item(id: 2, daysAgo: 2), item(id: 3, daysAgo: 400)])

        #expect(result.count == 5)
        #expect(result[0] == .header(.thisWeek, ordinal: 0))
        #expect(result[1].id == "post-1")
        #expect(result[2].id == "post-2")
        if case .header(let group, _) = result[3] {
            #expect(group != .thisWeek)
        } else {
            Issue.record("expected a header before the older post")
        }
    }

    @Test("no headers when date groups are off")
    func noHeaders() {
        let result = entries([item(id: 1, daysAgo: 1), item(id: 2, daysAgo: 400)], showsDateGroups: false)
        #expect(result.map(\.id) == ["post-1", "post-2"])
    }

    @Test("rows without a post neither emit nor reset the group")
    func loadingRows() {
        let loading = CustomPostCollectionItem(id: 9, post: nil, state: .loading)
        let result = entries([item(id: 1, daysAgo: 1), loading, item(id: 2, daysAgo: 2)])
        #expect(result.map(\.id) == ["header-0", "post-1", "post-9", "post-2"])
    }

    @Test("a recently modified post still groups by its published date")
    func groupsByPublishedDate() {
        let items = [item(id: 1, daysAgo: 400, modifiedDaysAgo: 1)]
        #expect(entries(items).first == .header(.monthAndYear(label: "December 2025"), ordinal: 0))
    }

    @Test("a repeated group gets a distinct header id")
    func repeatedGroupIDs() {
        // A sticky post floats to the top regardless of its date.
        let result = entries([item(id: 1, daysAgo: 1), item(id: 2, daysAgo: 400), item(id: 3, daysAgo: 1)])
        let headerIDs = result.compactMap { entry -> String? in
            if case .header = entry { return entry.id }
            return nil
        }
        #expect(headerIDs.count == 3)
        #expect(Set(headerIDs).count == 3)
    }
}
