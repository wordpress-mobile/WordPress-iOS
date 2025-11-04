import Foundation
import WordPressKit
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal

protocol TaxonomyServiceProtocol {
    func getTags(page: Int, recentlyUsed: Bool) async throws -> [AnyTermWithViewContext]
    func searchTags(with query: String) async throws -> [AnyTermWithViewContext]
    func createTag(name: String, description: String) async throws -> AnyTermWithViewContext
    func updateTag(_ term: AnyTermWithViewContext, name: String, description: String) async throws -> AnyTermWithViewContext
    func deleteTag(_ term: AnyTermWithViewContext) async throws
}

class TagsService: TaxonomyServiceProtocol {
    private let remote: TaxonomyServiceRemote?

    init(blog: Blog) {
        self.remote = Self.createRemote(for: blog)
    }

    private static func createRemote(for blog: Blog) -> TaxonomyServiceRemote? {
        if let siteID = blog.dotComID, let api = blog.wordPressComRestApi {
            return TaxonomyServiceRemoteREST(wordPressComRestApi: api, siteID: siteID)
        }

        if let username = blog.username, let password = blog.password, let xmlrpcApi = blog.xmlrpcApi {
            return TaxonomyServiceRemoteXMLRPC(api: xmlrpcApi, username: username, password: password)
        }

        return nil
    }

    func getTags(
        page: Int = 0,
        recentlyUsed: Bool = false
    ) async throws -> [AnyTermWithViewContext] {
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

        let pageSize = 100
        let paging = RemoteTaxonomyPaging()
        paging.number = NSNumber(value: pageSize)
        paging.offset = NSNumber(value: page * pageSize)
        paging.orderBy = recentlyUsed ? .byCount : .byName
        paging.order = recentlyUsed ? .orderDescending : .orderAscending

        return try await withCheckedThrowingContinuation { continuation in
            remote.getTagsWith(paging, success: { remoteTags in
                continuation.resume(returning: remoteTags.map { AnyTermWithViewContext(tag: $0) })
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    func searchTags(with query: String) async throws -> [AnyTermWithViewContext] {
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

        guard !query.isEmpty else {
            return []
        }

        return try await withCheckedThrowingContinuation { continuation in
            remote.searchTags(withName: query, success: { remoteTags in
                continuation.resume(returning: remoteTags.map { AnyTermWithViewContext(tag: $0) })
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    func createTag(name: String, description: String) async throws -> AnyTermWithViewContext {
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

        let tag = RemotePostTag()
        tag.name = name
        tag.tagDescription = description

        return try await withCheckedThrowingContinuation { continuation in
            remote.createTag(tag, success: { savedTag in
                continuation.resume(returning: AnyTermWithViewContext(tag: savedTag))
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    func updateTag(_ term: AnyTermWithViewContext, name: String, description: String) async throws -> AnyTermWithViewContext {
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

        let tag = term.tag
        tag.name = name
        tag.tagDescription = description

        return try await withCheckedThrowingContinuation { continuation in
            remote.update(tag, success: { savedTag in
                continuation.resume(returning: AnyTermWithViewContext(tag: savedTag))
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    func deleteTag(_ term: AnyTermWithViewContext) async throws {
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

        let tag = term.tag
        guard tag.tagID != nil else {
            throw TagsServiceError.invalidTag
        }

        return try await withCheckedThrowingContinuation { continuation in
            remote.delete(tag, success: {
                continuation.resume()
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }
}

enum TagsServiceError: Error {
    case noRemoteService
    case invalidTag
}

extension TagsServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noRemoteService:
            return NSLocalizedString(
                "tags.error.no_remote_service",
                value: "Unable to connect to your site. Please check your connection and try again.",
                comment: "Error message when the tags service cannot connect to the remote site"
            )
        case .invalidTag:
            return NSLocalizedString(
                "tags.error.invalid_tag",
                value: "The tag information is invalid. Please try again.",
                comment: "Error message when tag data is invalid"
            )
        }
    }
}

extension AnyTermWithViewContext: @retroactive Identifiable {}

extension AnyTermWithViewContext {
    init(tag: RemotePostTag) {
        self.init(
            id: tag.tagID?.int64Value ?? 0,
            count: tag.postCount?.int64Value ?? 0,
            description: tag.tagDescription ?? "",
            link: "",
            name: tag.name ?? "",
            slug: tag.slug ?? "",
            taxonomy: .postTag,
            parent: nil
        )
    }

    var tag: RemotePostTag {
        let tag = RemotePostTag()
        tag.tagID = id == 0 ? nil : NSNumber(value: id)
        tag.name = name
        tag.slug = slug.isEmpty ? nil : slug
        tag.tagDescription = description
        tag.postCount = NSNumber(value: count)
        return tag
    }
}

class AnyTermService: TaxonomyServiceProtocol {
    private let api: WordPressAPI
    let endpoint: TermEndpointType

    init(api: WordPressAPI, endpoint: TermEndpointType) {
        self.endpoint = endpoint
        self.api = api
    }

    func getTags(page: Int = 0, recentlyUsed: Bool = false) async throws -> [AnyTermWithViewContext] {
        let perPage: UInt32 = 100
        let params = TermListParams(
            page: UInt32(page + 1),
            perPage: perPage,
            order: recentlyUsed ? .desc : .asc,
            orderby: recentlyUsed ? .count : .name
        )

        let response = try await api.terms.listWithViewContext(
            termEndpointType: endpoint,
            params: params
        )

        return response.data
    }

    func searchTags(with query: String) async throws -> [AnyTermWithViewContext] {
        guard !query.isEmpty else {
            return []
        }

        let params = TermListParams(
            perPage: 100,
            search: query
        )

        let response = try await api.terms.listWithViewContext(
            termEndpointType: endpoint,
            params: params
        )

        return response.data
    }

    func createTag(name: String, description: String) async throws -> AnyTermWithViewContext {
        let params = TermCreateParams(
            name: name,
            description: description.isEmpty ? nil : description
        )

        let response = try await api.terms.create(
            termEndpointType: endpoint,
            params: params
        )

        return response.data.toViewContext()
    }

    func updateTag(_ term: AnyTermWithViewContext, name: String, description: String) async throws -> AnyTermWithViewContext {
        let params = TermUpdateParams(
            name: name,
            description: description
        )

        let response = try await api.terms.update(
            termEndpointType: endpoint,
            termId: term.id,
            params: params
        )

        return response.data.toViewContext()
    }

    func deleteTag(_ term: AnyTermWithViewContext) async throws {
        _ = try await api.terms.delete(
            termEndpointType: endpoint,
            termId: term.id
        )
    }
}

extension AnyTermWithEditContext {
    func toViewContext() -> AnyTermWithViewContext {
        return AnyTermWithViewContext(
            id: id,
            count: count,
            description: description,
            link: link,
            name: name,
            slug: slug,
            taxonomy: taxonomy,
            parent: parent
        )
    }
}
