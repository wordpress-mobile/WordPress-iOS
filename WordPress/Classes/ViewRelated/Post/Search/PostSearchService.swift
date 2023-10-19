import Foundation
import CoreData

protocol PostSearchServiceDelegate: AnyObject {
    func service(_ service: PostSearchService, didAppendPosts page: [PostSearchResult])
    func serviceDidUpdateState(_ service: PostSearchService)
}

/// Loads post search results with pagination.
final class PostSearchService {
    private(set) var isLoading = false
    private(set) var error: Error?

    weak var delegate: PostSearchServiceDelegate?

    private let blog: Blog
    private let settings: PostListFilterSettings
    private let criteria: PostSearchCriteria
    private let coreDataStack: CoreDataStack

    private var postIDs: Set<NSManagedObjectID> = []
    private var offset = 0
    private var hasMore = true

    init(blog: Blog,
         settings: PostListFilterSettings,
         criteria: PostSearchCriteria,
         coreDataStack: CoreDataStack = ContextManager.shared
    ) {
        self.blog = blog
        self.settings = settings
        self.criteria = criteria
        self.coreDataStack = coreDataStack
    }

    func loadMore() {
        guard !isLoading && hasMore else {
            return
        }
        isLoading = true
        error = nil
        delegate?.serviceDidUpdateState(self)

        _loadMore()
    }

    private func _loadMore() {
        let options = PostServiceSyncOptions()
        options.number = 20
        options.offset = NSNumber(value: offset)
        options.purgesLocalSync = false
        options.search = criteria.searchTerm
        options.authorID = criteria.authorID
        options.tag = criteria.tag

        let postService = PostService(managedObjectContext: coreDataStack.mainContext)
        postService.syncPosts(
            ofType: settings.postType,
            with: options,
            for: blog,
            success: { [weak self] in
                self?.didLoad(with: .success($0 ?? []))
            },
            failure: { [weak self] in
                self?.didLoad(with: .failure($0 ?? URLError(.unknown)))
            }
        )
    }

    private func didLoad(with result: Result<[AbstractPost], Error>) {
        assert(Thread.isMainThread)

        switch result {
        case .success(let posts):
            offset += posts.count
            hasMore = !posts.isEmpty

            let newPosts = posts.filter { !postIDs.contains($0.objectID) }
            postIDs.formUnion(newPosts.map(\.objectID))

            preprocess(newPosts) { [weak self] in
                guard let self else { return }
                self.delegate?.service(self, didAppendPosts: $0)
            }
        case .failure(let error):
            self.error = error
        }
        isLoading = false
        delegate?.serviceDidUpdateState(self)
    }

    private func preprocess(_ posts: [AbstractPost], _ completion: @escaping ([PostSearchResult]) -> Void) {
        let rawTitles = posts.map(\.postTitle)
        let searchTerm = criteria.searchTerm
        DispatchQueue.global().async {
            let terms = searchTerm
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            let titles = rawTitles.map { PostSearchService.makeTitle(for: $0 ?? "", terms: terms) }
            let results = zip(posts, titles).map {
                PostSearchResult(post: $0, title: $1, searchTerm: searchTerm)
            }
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
}

struct PostSearchResult {
    let post: AbstractPost
    /// Preprocessed titles with highlighted search ranges.
    let title: NSAttributedString
    let searchTerm: String

    var id: ID { ID(objectID: post.objectID, searchTerm: searchTerm) }

    struct ID: Hashable {
        let objectID: NSManagedObjectID
        /// Adding search term because the cell updates as the term changes.
        let searchTerm: String
    }
}

struct PostSearchCriteria: Hashable {
    let searchTerm: String
    let authorID: NSNumber?
    let tag: String?
}

extension PostSearchService {
    // Both decoding & searching are expensive, so the service performs these
    // operations in the background.
    static func makeTitle(for title: String, terms: [String]) -> NSAttributedString {
        let title = title
            .trimmingCharacters(in: .whitespaces)
            .stringByDecodingXMLCharacters()

        let ranges = terms.flatMap {
            title.ranges(of: $0, options: [.caseInsensitive, .diacriticInsensitive])
        }.sorted { $0.lowerBound < $1.lowerBound }

        let string = NSMutableAttributedString(string: title, attributes: [
            .font: WPStyleGuide.fontForTextStyle(.body)
        ])
        for range in collapseAdjacentRanges(ranges, in: title) {
            string.setAttributes([
                .backgroundColor: UIColor.systemYellow.withAlphaComponent(0.25)
            ], range: NSRange(range, in: title))
        }
        return string
    }

    private static func collapseAdjacentRanges(_ ranges: [Range<String.Index>], in string: String) -> [Range<String.Index>] {
        var output: [Range<String.Index>] = []
        var ranges = ranges
        while let rhs = ranges.popLast() {
            if let lhs = ranges.last,
               rhs.lowerBound > string.startIndex,
               lhs.upperBound == string.index(before: rhs.lowerBound),
               string[string.index(before: rhs.lowerBound)].isWhitespace {
                let range = lhs.lowerBound..<rhs.upperBound
                ranges.removeLast()
                ranges.append(range)
            } else {
                output.append(rhs)
            }
        }
        return output
    }
}

private extension String {
    func ranges(of string: String, options: String.CompareOptions) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = range(of: string, options: options, range: startIndex..<endIndex) {
            ranges.append(range)
            startIndex = range.upperBound
        }
        return ranges
    }
}
