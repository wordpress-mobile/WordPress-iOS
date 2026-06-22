import Testing

@testable import WordPressMediaLibrary

@MainActor
struct MediaLibraryViewModelFilterTests {
    // The pure type-filter is the only view-model logic testable without a real
    // `WpService` / `WordPressClient`. The load, observe, empty-state, and error
    // paths run through the app, not unit tests, because the view model builds
    // its collection directly from the service (no injection seam).

    private let mixed: [MediaGridItem] = [
        MediaGridItem(testID: 1, kind: .image),
        MediaGridItem(testID: 2, kind: .video),
        MediaGridItem(testID: 3, kind: nil) // unknown
    ]

    @Test func noFilterShowsEverything() {
        let result = MediaLibraryViewModel.applyingKindFilter(mixed, kind: nil)
        #expect(result.map(\.id) == [1, 2, 3])
    }

    @Test func videoFilterShowsOnlyVideos() {
        let result = MediaLibraryViewModel.applyingKindFilter(mixed, kind: .video)
        #expect(result.map(\.id) == [2])
    }

    @Test func unknownKindExcludedFromSpecificFilter() {
        let result = MediaLibraryViewModel.applyingKindFilter(mixed, kind: .image)
        #expect(result.map(\.id) == [1]) // id 3 (unknown) excluded
    }
}
