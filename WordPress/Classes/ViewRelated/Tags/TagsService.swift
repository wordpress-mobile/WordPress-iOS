import Foundation
import WordPressKit
import WordPressData

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
        number: Int = 100,
        offset: Int = 0,
        orderBy: RemoteTaxonomyPagingResultsOrdering = .byName,
        order: RemoteTaxonomyPagingResultsOrder = .orderAscending
    ) async throws -> [RemotePostTag] {
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

        let paging = RemoteTaxonomyPaging()
        paging.number = NSNumber(value: number)
        paging.offset = NSNumber(value: offset)
        paging.orderBy = .byCount
        paging.order = .orderDescending

        return try await withCheckedThrowingContinuation { continuation in
            remote.getTagsWith(paging, success: { remoteTags in
                continuation.resume(returning: remoteTags)
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    func searchTags(with query: String) async throws -> [RemotePostTag] {
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

        guard !query.isEmpty else {
            return []
        }

        return try await withCheckedThrowingContinuation { continuation in
            remote.searchTags(withName: query, success: { remoteTags in
                continuation.resume(returning: remoteTags)
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    func createTag(named name: String) async throws -> RemotePostTag {
        // Do not create a new tag if a tag with the same name already exists.
        let existing = try await searchTags(with: name)
            .first { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }
        if let existing {
            return existing
        }

        let tag = RemotePostTag()
        tag.name = name
        return try await saveTag(tag)
    }

    func deleteTag(_ tag: RemotePostTag) async throws {
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

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

    func saveTag(_ tag: RemotePostTag) async throws -> RemotePostTag {
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

        return try await withCheckedThrowingContinuation { continuation in
            if tag.tagID == nil {
                remote.createTag(tag, success: { savedTag in
                    continuation.resume(returning: savedTag)
                }, failure: { error in
                    continuation.resume(throwing: error)
                })
            } else {
                remote.update(tag, success: { savedTag in
                    continuation.resume(returning: savedTag)
                }, failure: { error in
                    continuation.resume(throwing: error)
                })
            }
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
