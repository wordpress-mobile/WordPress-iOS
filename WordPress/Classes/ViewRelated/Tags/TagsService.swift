import Foundation
import WordPressKit
import WordPressData
import WordPressAPI

class TagsService {
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
