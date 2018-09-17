import GiphyCoreSDK

/// Encapsulates search parameters (text, pagination, etc)
struct GiphySearchParams {
    let text: String
    let pageable: Pageable?

    init(text: String?, pageable: Pageable?) {
        self.text = text ?? ""
        self.pageable = pageable
    }
}

struct GiphyService {
    static let giphy: GPHClient = {
        GiphyCore.configure(apiKey: ApiCredentials.giphyAppId())
        return GiphyCore.shared
    }()

    func search(params: GiphySearchParams, completion: @escaping (GiphyResultsPage) -> Void) {
        let offset = params.pageable?.pageIndex ?? 0
        let pageSize = params.pageable?.pageSize ?? GiphyPageable.defaultPageSize

        GiphyService.giphy.search(params.text, offset: offset, limit: pageSize, rating: .ratedG) { (response, error) in
            DispatchQueue.main.async {
                if let _ = error as NSError? {
                    completion(GiphyResultsPage.empty())
                    return
                }

                if let response = response, let data = response.data {
                    let media = data.compactMap({ GiphyMedia(gphMedia: $0) })
                    let page = GiphyPageable(gphPagination: response.pagination)

                    completion(GiphyResultsPage(results: media, pageable: page))
                } else {
                    completion(GiphyResultsPage.empty())
                }
            }
        }
    }
}

// MARK: GPHMedia Parsing

extension GiphyImageCollection {
    init?(gphMedia: GPHMedia) {
        guard let images = gphMedia.images,
            let thumbnail = images.fixedHeightStill?.gifUrl,
            let thumbnailURL = URL(string: thumbnail),
            let downsizedURLString = images.downsized?.gifUrl,
            let downsizedURL = URL(string: downsizedURLString),
            let large = images.downsizedLarge,
            let largeURLString = large.gifUrl,
            let largeURL = URL(string: largeURLString) else {
                return nil
        }

        let size = CGSize(width: large.width, height: large.height)

        self.init(largeURL: largeURL,
                  previewURL: downsizedURL,
                  staticThumbnailURL: thumbnailURL,
                  largeSize: size)
    }
}

extension GiphyMedia {
    convenience init?(gphMedia: GPHMedia) {
        guard let images = GiphyImageCollection(gphMedia: gphMedia) else {
            return nil
        }

        self.init(id: gphMedia.id,
                  name: gphMedia.title ?? "",
                  caption: gphMedia.caption ?? "",
                  images: images,
                  date: gphMedia.updateDate)
    }
}

// Allows us to mock out the pagination in tests
protocol GPHPaginationType {
    /// Total Result Count.
    var totalCount: Int { get }

    /// Actual Result Count (not always == limit)
    var count: Int { get }

    /// Offset to start next set of results.
    var offset: Int { get }
}

extension GPHPagination: GPHPaginationType {}

extension GiphyPageable {
    init?(gphPagination: GPHPaginationType?) {
        guard let pagination = gphPagination else {
            return nil
        }

        let newOffset = pagination.offset + pagination.count
        guard newOffset < pagination.totalCount else {
            return nil
        }

        self.init(itemsPerPage: GiphyPageable.defaultPageSize,
                  pageHandle: newOffset)
    }
}
