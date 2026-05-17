import Foundation
import WordPressAPI
import WordPressAPIInternal

struct MediaListItem: Identifiable, Equatable {
    let id: Int64
    let title: String?
    let thumbnailURL: URL?
    let state: State

    enum State: Equatable {
        case loaded(isUpToDate: Bool)
        case loading
        case error(message: String)
    }

    init(item: MediaMetadataCollectionItem) {
        self.id = item.id

        switch item.state {
        case .fresh(let entity):
            self.title = MediaListItem.makeTitle(from: entity.data)
            self.thumbnailURL = MediaListItem.makeThumbnailURL(from: entity.data)
            self.state = .loaded(isUpToDate: true)

        case .stale(let entity):
            self.title = MediaListItem.makeTitle(from: entity.data)
            self.thumbnailURL = MediaListItem.makeThumbnailURL(from: entity.data)
            self.state = .loaded(isUpToDate: false)

        case .fetchingWithData(let entity):
            self.title = MediaListItem.makeTitle(from: entity.data)
            self.thumbnailURL = MediaListItem.makeThumbnailURL(from: entity.data)
            self.state = .loading

        case .fetching, .missing:
            self.title = nil
            self.thumbnailURL = nil
            self.state = .loading

        case .failed(let error):
            self.title = nil
            self.thumbnailURL = nil
            self.state = .error(message: error)

        case .failedWithData(let error, let entity):
            self.title = MediaListItem.makeTitle(from: entity.data)
            self.thumbnailURL = MediaListItem.makeThumbnailURL(from: entity.data)
            self.state = .error(message: error)
        }
    }

    /// Prefer `title.raw`, fall back to `slug`, fall back to nil. The view
    /// renders `Strings.untitled` when this is nil.
    private static func makeTitle(from media: MediaWithEditContext) -> String? {
        let raw = (media.title.raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty { return raw }
        return media.slug.isEmpty ? nil : media.slug
    }

    /// Uses `sourceUrl` as the thumbnail for now. A future change will pick a
    /// smaller size from `media.mediaDetails.sizes` for grid rendering.
    private static func makeThumbnailURL(from media: MediaWithEditContext) -> URL? {
        URL(string: media.sourceUrl)
    }
}
