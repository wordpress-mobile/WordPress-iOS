import Foundation
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal

class CustomPostTypeService {
    let blog: TaggedManagedObjectID<Blog>
    let client: WordPressClient

    private(set) var wpService: WpSelfHostedService?
    private var collection: PostTypeCollectionWithEditContext?

    init(client: WordPressClient, blog: Blog) {
        self.client = client
        self.blog = TaggedManagedObjectID(blog)
    }

    init?(blog: Blog) {
        guard FeatureFlag.customPostTypes.enabled,
              let site = try? WordPressSite(blog: blog),
              case .selfHosted = site else { return nil }
        self.blog = TaggedManagedObjectID(blog)
        self.client = WordPressClientFactory.shared.instance(for: site)
    }

    func refresh() async throws {
        let service = try await resolveService()
        _ = try await service.postTypes().syncPostTypes()

        // If the user has not manually pinned any post types (typically right after first fetching post types),
        // we automatically pin 3 post types, so that the user can see their content straight from the top-level screens.
        if !SiteStorageAccess.pinnedPostTypesUpdated(for: blog) {
            let pinned = try await customTypes()
                .prefix(3)
                .map { PinnedPostType(slug: $0.slug, name: $0.name, icon: $0.icon) }
            SiteStorageAccess.writePinnedPostTypes(pinned, for: blog)
        }
    }

    func customTypes() async throws -> [PostTypeDetailsWithEditContext] {
        let collection = try await resolveCollection()
        return try await collection.loadData()
            .compactMap { entry -> PostTypeDetailsWithEditContext? in
                let details = entry.data
                if case .custom = details.toPostEndpointType(), details.slug != "attachment" {
                    return details
                }
                return nil
            }
            .sorted { $0.slug < $1.slug }
    }

    func resolvePostType(slug: String) async throws -> PostTypeDetailsWithEditContext? {
        let service = try await resolveService()
        let postTypes = service.postTypes()

        if let details = postTypes.getBySlug(slug: slug) {
            return details
        }

        _ = try await postTypes.syncPostTypes()

        return postTypes.getBySlug(slug: slug)
    }

    private func resolveService() async throws -> WpSelfHostedService {
        if let wpService {
            return wpService
        }
        let service = try await client.service
        self.wpService = service
        return service
    }

    private func resolveCollection() async throws -> PostTypeCollectionWithEditContext {
        if let collection {
            return collection
        }
        let service = try await resolveService()
        let collection = service.postTypes().createPostTypeCollectionWithEditContext()
        self.collection = collection
        return collection
    }
}
