import Combine
import Foundation
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal

/// The part of ``CustomPostTypeService`` the site menu depends on.
protocol CustomPostTypeServiceProtocol {
    /// Emits whenever the cache records a change that may affect ``customTypes()``.
    func customTypesUpdates() async throws -> AnyPublisher<Void, Never>
    func customTypes() async throws -> [PostTypeDetailsWithEditContext]
}

class CustomPostTypeService: CustomPostTypeServiceProtocol {
    let client: WordPressClient

    private var wpService: WpService?
    private var collection: PostTypeCollectionWithEditContext?

    init(client: WordPressClient) {
        self.client = client
    }

    init?(blog: Blog) {
        guard blog.supportsCoreRESTAPI, let site = try? WordPressSite(blog: blog) else { return nil }
        self.client = WordPressClientFactory.shared.instance(for: site)
    }

    func refresh() async throws {
        let service = try await resolveService()
        _ = try await service.postTypes().syncPostTypes()
    }

    func customTypesUpdates() async throws -> AnyPublisher<Void, Never> {
        let collection = try await resolveCollection()
        return await client.cache.databaseUpdatesPublisher()
            .filter { collection.isRelevantUpdate(hook: $0) }
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func customTypes() async throws -> [PostTypeDetailsWithEditContext] {
        let collection = try await resolveCollection()
        return try await collection.loadData()
            .compactMap { entry -> PostTypeDetailsWithEditContext? in
                let details = entry.data

                // TODO: Determine if we should support post types without "editor"
                // (title-only posts, e.g. GiveWP's `give_forms`).
                //
                // Currently wordpress-rs requires the `content` field in API responses,
                // which is absent for post types that don't support "editor".
                //
                // For these post types, the app also needs to hide "open in editor"
                // options since there is no content body to edit.
                //
                // Most plugins that set `show_in_rest = true` do so for block editor
                // support, which requires "editor". Plugins with data-only post types
                // (e.g. WooCommerce orders) typically keep `show_in_rest = false` and
                // use custom REST routes instead. So this may not be worth supporting.
                guard details.supports.supports(feature: .editor) else {
                    return nil
                }

                if case .custom = details.toPostEndpointType(), details.slug != "attachment" {
                    return details
                }
                return nil
            }
            .sorted(using: KeyPathComparator(\.name))
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

    private func resolveService() async throws -> WpService {
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
