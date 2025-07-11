import Foundation
import WordPressKit
import WordPressData

@MainActor
class TagsService {
    private let blog: Blog
    private let remote: TaxonomyServiceRemote?

    init(blog: Blog) {
        self.blog = blog
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
}

enum TagsServiceError: Error {
    case noRemoteService
}
