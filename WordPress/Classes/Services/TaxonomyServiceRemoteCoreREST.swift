import Foundation
import WordPressKit
import WordPressCore
import WordPressData
import WordPressAPI

@objc public class TaxonomyServiceRemoteCoreREST: NSObject, TaxonomyServiceRemote {
    let client: WordPressClient

    @objc public convenience init?(blog: Blog) {
        guard let site = try? WordPressSite(blog: blog) else { return nil }

        self.init(client: WordPressClientFactory.shared.instance(for: site))
    }

    init(client: WordPressClient) {
        self.client = client
    }

    public func createCategory(_ category: RemotePostCategory, success: ((RemotePostCategory) -> Void)?, failure: ((any Error) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let params = TermCreateParams(
                    name: category.name ?? "",
                    parent: category.parentID?.int64Value
                )
                let response = try await client.api.terms.create(termEndpointType: .categories, params: params)
                let remoteCategory = RemotePostCategory(category: response.data)
                success?(remoteCategory)
            } catch {
                failure?(error)
            }
        }
    }

    public func getCategoriesWithSuccess(_ success: @escaping ([RemotePostCategory]) -> Void, failure: ((any Error) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let sequence = await client.api.terms.sequenceWithEditContext(
                    type: .categories,
                    params: TermListParams(perPage: 100)
                )
                let categories: [RemotePostCategory] = try await sequence.reduce(into: []) {
                    let page = $1.map(RemotePostCategory.init(category:))
                    $0.append(contentsOf: page)
                }
                success(categories)
            } catch {
                failure?(error)
            }
        }
    }

    public func getCategoriesWith(_ paging: RemoteTaxonomyPaging, success: @escaping ([RemotePostCategory]) -> Void, failure: ((any Error) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let params = TermListParams(
                    page: paging.page?.uint32Value,
                    perPage: paging.number?.uint32Value,
                    offset: paging.offset?.uint32Value,
                    order: WpApiParamOrder(paging.order),
                    orderby: WpApiParamTermsOrderBy(paging.orderBy)
                )
                let response = try await client.api.terms.listWithEditContext(
                    termEndpointType: .categories,
                    params: params
                )
                let categories = response.data.map(RemotePostCategory.init(category:))
                success(categories)
            } catch {
                failure?(error)
            }
        }
    }

    public func searchCategories(withName nameQuery: String, success: @escaping ([RemotePostCategory]) -> Void, failure: ((any Error) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let params = TermListParams(search: nameQuery)
                let response = try await client.api.terms.listWithEditContext(
                    termEndpointType: .categories,
                    params: params
                )
                let categories = response.data.map(RemotePostCategory.init(category:))
                success(categories)
            } catch {
                failure?(error)
            }
        }
    }

    public func createTag(_ tag: RemotePostTag, success: ((RemotePostTag) -> Void)?, failure: ((any Error) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let params = TermCreateParams(
                    name: tag.name ?? "",
                    description: tag.tagDescription,
                    slug: tag.slug
                )
                let response = try await client.api.terms.create(
                    termEndpointType: .tags,
                    params: params
                )
                let remoteTag = RemotePostTag(tag: response.data)
                success?(remoteTag)
            } catch {
                failure?(error)
            }
        }
    }

    public func update(_ tag: RemotePostTag, success: ((RemotePostTag) -> Void)?, failure: ((any Error) -> Void)? = nil) {
        guard let tagID = tag.tagID else {
            failure?(URLError(.unknown))
            return
        }

        Task { @MainActor in
            do {
                let params = TermUpdateParams(
                    name: tag.name,
                    description: tag.tagDescription,
                    slug: tag.slug
                )
                let response = try await client.api.terms.update(
                    termEndpointType: .tags,
                    termId: tagID.int64Value,
                    params: params
                )
                let remoteTag = RemotePostTag(tag: response.data)
                success?(remoteTag)
            } catch {
                failure?(error)
            }
        }
    }

    public func delete(_ tag: RemotePostTag, success: (() -> Void)?, failure: ((any Error) -> Void)? = nil) {
        guard let tagID = tag.tagID else {
            failure?(URLError(.unknown))
            return
        }

        Task { @MainActor in
            do {
                let _ = try await client.api.terms.delete(termEndpointType: .tags, termId: tagID.int64Value)
                success?()
            } catch {
                failure?(error)
            }
        }
    }

    public func getTagsWithSuccess(_ success: @escaping ([RemotePostTag]) -> Void, failure: ((any Error) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let response = try await client.api.terms.listWithEditContext(
                    termEndpointType: .tags,
                    params: TermListParams()
                )
                let tags = response.data.map(RemotePostTag.init(tag:))
                success(tags)
            } catch {
                failure?(error)
            }
        }
    }

    public func getTagsWith(_ paging: RemoteTaxonomyPaging, success: @escaping ([RemotePostTag]) -> Void, failure: ((any Error) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let params = TermListParams(
                    page: paging.page?.uint32Value,
                    perPage: paging.number?.uint32Value,
                    offset: paging.offset?.uint32Value,
                    order: WpApiParamOrder(paging.order),
                    orderby: WpApiParamTermsOrderBy(paging.orderBy)
                )
                let response = try await client.api.terms.listWithEditContext(
                    termEndpointType: .tags,
                    params: params
                )
                let tags = response.data.map(RemotePostTag.init(tag:))
                success(tags)
            } catch {
                failure?(error)
            }
        }
    }

    public func searchTags(withName nameQuery: String, success: @escaping ([RemotePostTag]) -> Void, failure: ((any Error) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let response = try await client.api.terms.listWithEditContext(
                    termEndpointType: .tags,
                    params: TermListParams(search: nameQuery)
                )
                let tags = response.data.map(RemotePostTag.init(tag:))
                success(tags)
            } catch {
                failure?(error)
            }
        }
    }
}

private extension RemotePostCategory {
    convenience init(category: AnyTermWithEditContext) {
        self.init()
        self.categoryID = NSNumber(value: category.id)
        self.name = category.name
        self.parentID = NSNumber(value: category.parent ?? 0)
    }
}

private extension RemotePostTag {
    convenience init(tag: AnyTermWithEditContext) {
        self.init()
        self.tagID = NSNumber(value: tag.id)
        self.name = tag.name
        self.slug = tag.slug
        self.tagDescription = tag.description
        self.postCount = NSNumber(value: tag.count)
    }
}

private extension WpApiParamOrder {
    init(_ other: RemoteTaxonomyPagingResultsOrder) {
        switch other {
        case .orderAscending:
            self = .asc
        case .orderDescending:
            self = .desc
        @unknown default:
            self = .asc
        }
    }
}

private extension WpApiParamTermsOrderBy {
    init(_ other: RemoteTaxonomyPagingResultsOrdering) {
        switch other {
        case .byName:
            self = .name
        case .byCount:
            self = .count
        @unknown default:
            self = .name
        }
    }
}
