import UIKit
import CoreData
import Gutenberg
import WordPressKit

class PageLayoutService {
    private struct Parameters {
        static let supportedBlocks = "supported_blocks"
        static let previewWidth = "preview_width"
        static let previewHeight = "preview_height"
        static let scale = "scale"
        static let type = "type"
        static let isBeta = "is_beta"
    }

    typealias CompletionHandler = (Swift.Result<Void, Error>) -> Void
    static func fetchLayouts(forBlog blog: Blog, withThumbnailSize thumbnailSize: CGSize, completion: CompletionHandler? = nil) {
        let blogPersistentID = blog.objectID
        let api: WordPressComRestApi
        let dotComID: Int?
        if blog.isAccessibleThroughWPCom(),
           let blogID = blog.dotComID?.intValue,
           let restAPI = blog.account?.wordPressComRestV2Api {
            api = restAPI
            dotComID = blogID
        } else {
            api = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress(), localeKey: WordPressComRestApi.LocaleKeyV2)
            dotComID = nil
        }

        fetchLayouts(api, dotComID, blogPersistentID, thumbnailSize, completion)
    }

    private static func fetchLayouts(_ api: WordPressComRestApi, _ dotComID: Int?, _ blogPersistentID: NSManagedObjectID, _ thumbnailSize: CGSize, _ completion: CompletionHandler?) {
        let params = parameters(thumbnailSize)

        PageLayoutServiceRemote.fetchLayouts(api, forBlogID: dotComID, withParameters: params) { (result) in
            switch result {
            case .success(let remoteLayouts):
                persistToCoreData(blogPersistentID, remoteLayouts) { (persistanceResult) in
                    switch persistanceResult {
                    case .success:
                        completion?(.success(()))
                    case .failure(let error):
                        completion?(.failure(error))
                    }
                }
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    // Parameter Generation
    private static func parameters(_ thumbnailSize: CGSize) -> [String: AnyObject] {
        return [
            Parameters.supportedBlocks: supportedBlocks as AnyObject,
            Parameters.previewWidth: "\(thumbnailSize.width)" as AnyObject,
            Parameters.previewHeight: "\(thumbnailSize.height)" as AnyObject,
            Parameters.scale: scale as AnyObject,
            Parameters.type: type as AnyObject,
            Parameters.isBeta: isBeta as AnyObject
        ]
    }

    private static let supportedBlocks: String = {
        let isDevMode = BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        return Gutenberg.supportedBlocks(isDev: isDevMode).joined(separator: ",")
    }()

    private static let scale = UIScreen.main.nativeScale

    private static let type = "mobile"

    // Return "true" or "false" for isBeta that gets passed into the endpoint.
    private static let isBeta = String(BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest])

}

extension PageLayoutService {

    static func resultsController(forBlog blog: Blog, delegate: NSFetchedResultsControllerDelegate? = nil) -> NSFetchedResultsController<PageTemplateCategory> {
        let context = ContextManager.shared.mainContext
        let request: NSFetchRequest<PageTemplateCategory> = PageTemplateCategory.fetchRequest(forBlog: blog)
        let sort = NSSortDescriptor(key: #keyPath(PageTemplateCategory.ordinal), ascending: true)
        request.sortDescriptors = [sort]

        let resultsController = NSFetchedResultsController<PageTemplateCategory>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        resultsController.delegate = delegate
        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("Failed to fetch entities: \(error)")
        }

        return resultsController
    }

    /// This will use a wipe all and rebuild strategy for managing the stored layouts. They are stored and associated per blog to prevent weird edge cases of downloading one set of layouts then having that bleed to another site (like a self hosted one) which may have a different set of suggested layouts.
    private static func persistToCoreData(_ blogPersistentID: NSManagedObjectID, _ layouts: RemotePageLayouts, _ completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        let context = ContextManager.shared.newDerivedContext()
        context.perform {
            do {
                guard let blog = context.object(with: blogPersistentID) as? Blog else {
                    let userInfo = [NSLocalizedFailureReasonErrorKey: "Couldn't find blog to save the fetched results to."]
                    completion(.failure(NSError(domain: "PageLayoutService.persistToCoreData", code: 0, userInfo: userInfo)))
                    return
                }
                cleanUpStoredLayouts(forBlog: blog, context: context)
                try persistCategoriesToCoreData(blog, layouts.categories, context: context)
                try persistLayoutsToCoreData(blog, layouts.layouts, context: context)
            } catch {
                completion(.failure(error))
                return
            }
            ContextManager.shared.save(context)
            completion(.success(()))
        }
    }

    private static func cleanUpStoredLayouts(forBlog blog: Blog, context: NSManagedObjectContext) {
        // PageTemplateCategories have a cascade deletion rule to PageTemplateLayout. Deleting each category for the blog will cascade to also clean up the layouts.
        blog.pageTemplateCategories?.forEach({ context.delete($0) })
    }

    private static func persistCategoriesToCoreData(_ blog: Blog, _ categories: [RemoteLayoutCategory], context: NSManagedObjectContext) throws {
        for (index, category) in categories.enumerated() {
            let category = PageTemplateCategory(context: context, category: category, ordinal: index)
            blog.pageTemplateCategories?.insert(category)
        }
    }

    private static func persistLayoutsToCoreData(_ blog: Blog, _ layouts: [RemoteLayout], context: NSManagedObjectContext) throws {
        for layout in layouts {
            let localLayout = PageTemplateLayout(context: context, layout: layout)
            try associate(blog, layout: localLayout, toCategories: layout.categories, context: context)
        }
    }

    private static func associate(_ blog: Blog, layout: PageTemplateLayout, toCategories categories: [RemoteLayoutCategory], context: NSManagedObjectContext) throws {
        let categoryList = categories.map({ $0.slug })
        let request: NSFetchRequest<PageTemplateCategory> = PageTemplateCategory.fetchRequest(forBlog: blog, categorySlugs: categoryList)
        let fetchedCategories = try context.fetch(request)
        layout.categories = Set(fetchedCategories)
    }
}
