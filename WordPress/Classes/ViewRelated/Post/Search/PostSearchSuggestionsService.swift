import UIKit

protocol PostSearchToken {
    var icon: UIImage? { get }
    var value: String { get }
    var id: AnyHashable { get }
}

extension PostSearchToken {
    func asSearchToken() -> UISearchToken {
        let token = UISearchToken(icon: icon, text: value)
        token.representedObject = self
        return token
    }
}

struct PostSearchAuthorToken: Hashable, PostSearchToken {
    let authorID: NSNumber
    let displayName: String?

    var icon: UIImage? { UIImage(systemName: "person.circle") }
    var value: String { displayName ?? "" }
    var id: AnyHashable { self }

    init(author: BlogAuthor) {
        self.authorID = author.userID
        self.displayName = author.displayName
    }
}

struct PostSearchTagToken: Hashable, PostSearchToken {
    let tag: String

    var icon: UIImage? { UIImage(systemName: "number.circle") }
    var value: String { tag }
    var id: AnyHashable { self }
}

/// Suggests search token for the given input and context. Performs all of the
/// work in the background.
actor PostSearchSuggestionsService {
    private let blogID: TaggedManagedObjectID<Blog>
    private var cachedAuthorTokens: [PostSearchAuthorToken]?
    private var cachedTags: [PostSearchTagToken]?
    private let coreData: CoreDataStack

    init(blog: Blog, coreData: CoreDataStack = ContextManager.shared) {
        self.blogID = TaggedManagedObjectID(blog)
        self.coreData = coreData
    }

    func getSuggestion(for searchTerm: String, selectedTokens: [any PostSearchToken]) async -> [any PostSearchToken] {
        guard searchTerm.count > 1 else {
            return [] // Not enough input
        }

        async let authors = getAuthorTokens(for: searchTerm, selectedTokens: selectedTokens)
        async let tags = getTagTokens(for: searchTerm, selectedTokens: selectedTokens)

        let tokens = await [authors, tags]
        let selectedTokenIDs = Set(selectedTokens.map(\.id))

        return Array(tokens
            .flatMap { $0 }
            .filter { !selectedTokenIDs.contains($0.token.id) }
            .sorted { ($0.score, $0.token.value) > ($1.score, $1.token.value) }
            .map { $0.token }
            .prefix(3))
    }

    private struct RankedToken {
        let token: PostSearchToken
        let score: Double
    }

    // MARK: - Authors

    private func getAuthorTokens(for searchTerm: String, selectedTokens: [any PostSearchToken]) async -> [RankedToken] {
        guard !selectedTokens.contains(where: { $0 is PostSearchAuthorToken }) else {
            return [] // Don't suggest authors anymore
        }
        let tokens = await getAllAuthorTokens()
        guard tokens.count > 1 else {
            return [] // Never show for blogs with a single author
        }
        let search = StringRankedSearch(searchTerm: searchTerm)
        return tokens.compactMap {
            let score = search.score(for: $0.displayName)
            guard score > 0.7 else { return nil }
            return RankedToken(token: $0, score: score)
        }
    }

    private func getAllAuthorTokens() async -> [PostSearchAuthorToken] {
        if let tokens = cachedAuthorTokens {
            return tokens
        }
        let tokens = try? await coreData.performQuery { [blogID] context in
            let blog = try context.existingObject(with: blogID)
            return (blog.authors ?? []).map(PostSearchAuthorToken.init)
        }
        self.cachedAuthorTokens = tokens
        Task { // Invalidate cache after a few seconds
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            self.cachedAuthorTokens = nil
        }
        return tokens ?? []
    }

    // MARK: - Tags

    private func getTagTokens(for searchTerm: String, selectedTokens: [any PostSearchToken]) async -> [RankedToken] {
        guard !selectedTokens.contains(where: { $0 is PostSearchTagToken }) else {
            return [] // Don't suggest authors anymore
        }
        let tokens = await getAllTagTokens()
        let search = StringRankedSearch(searchTerm: searchTerm)
        return tokens.compactMap {
            let score = search.score(for: $0.tag)
            guard score > 0.7 else { return nil }
            return RankedToken(token: $0, score: score)
        }
    }

    private func getAllTagTokens() async -> [PostSearchTagToken] {
        let tags = try? await coreData.performQuery { [blogID] context in
            let blog = try context.existingObject(with: blogID)
            let tags = (blog.tags as? Set<PostTag>) ?? []
            return tags.compactMap {
                $0.name.map(PostSearchTagToken.init)
            }
        }
        self.cachedTags = tags
        Task { // Invalidate cache after a few seconds
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            self.cachedTags = nil
        }
        return tags ?? []
    }
}
