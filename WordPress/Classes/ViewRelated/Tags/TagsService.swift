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

    func getTags(number: Int = 100, offset: Int = 0) async throws -> [RemotePostTag] {
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
        guard let remote else {
            throw TagsServiceError.noRemoteService
        }

        // Do not create a new tag if a tag with the same name already exists.
        let existing = try await searchTags(with: name)
            .first { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }
        if let existing {
            return existing
        }

        return try await withCheckedThrowingContinuation { continuation in
            let tag = RemotePostTag()
            tag.name = name
            remote.createTag(tag) {
                continuation.resume(returning: $0)
            } failure: {
                continuation.resume(throwing: $0)
            }
        }
    }
}

enum TagsServiceError: Error {
    case noRemoteService
}
