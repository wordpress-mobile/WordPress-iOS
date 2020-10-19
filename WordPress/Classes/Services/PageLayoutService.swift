import UIKit
import CoreData
import Gutenberg
import WordPressKit

class PageLayoutService {
    private struct Parameters {
        static let supportedBlocks = "supported_blocks"
        static let previewWidth = "preview_width"
        static let scale = "scale"
    }

    typealias CompletionHandler = (Swift.Result<Void, Error>) -> Void
    static func fetchLayouts(forBlog blog: Blog, withThumbnailSize thumbnailSize: CGSize, completion: CompletionHandler? = nil) {
        let api: WordPressComRestApi
        let blogID: Int?
        if let dotComID = blog.dotComID,
           blog.isAccessibleThroughWPCom(),
           let restAPI = blog.wordPressComRestApi() {
            api = restAPI
            blogID = dotComID.intValue
        } else {
            api = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress())
            blogID = nil
        }

        fetchLayouts(api, forBlogID: blogID, withThumbnailSize: thumbnailSize, completion: completion)
    }

    private static func fetchLayouts(_ api: WordPressComRestApi, forBlogID blogID: Int?, withThumbnailSize thumbnailSize: CGSize, completion: CompletionHandler?) {
        let params = parameters(thumbnailSize)
        PageLayoutServiceRemote.fetchLayouts(api, forBlogID: blogID, withParameters: params) { (result) in
            switch result {
            case .success(let remoteLayouts):
                persistToCoreData(remoteLayouts) { (persistanceResult) in
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
            Parameters.previewWidth: previewWidth(thumbnailSize) as AnyObject,
            Parameters.scale: scale as AnyObject
        ]
    }

    private static let supportedBlocks: String = {
        let isDevMode = BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        return Gutenberg.supportedBlocks(isDev: isDevMode).joined(separator: ",")
    }()

    private static func previewWidth(_ thumbnailSize: CGSize) -> String {
        return "\(thumbnailSize.width)"
    }

    private static let scale = UIScreen.main.nativeScale
}

extension PageLayoutService {

    static func resultsController(delegate: NSFetchedResultsControllerDelegate? = nil) -> NSFetchedResultsController<PageTemplateCategory> {
        let context = ContextManager.shared.mainContext
        let request: NSFetchRequest<PageTemplateCategory> = PageTemplateCategory.fetchRequest()
        let sort = NSSortDescriptor(key: "title", ascending: true)
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

    private static func persistToCoreData(_ layouts: RemotePageLayouts, _ completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        let context = ContextManager.shared.newDerivedContext()
        context.perform {
            do {
                try persistCategoriesToCoreData(layouts.categories, context: context)
                try persistLayoutsToCoreData(layouts.layouts, context: context)
            } catch {
                completion(.failure(error))
                return
            }
            ContextManager.shared.save(context)
            completion(.success(()))
        }
    }

    private static func persistCategoriesToCoreData(_ categories: [RemoteLayoutCategory], context: NSManagedObjectContext) throws {
        context.deleteAllObjects(ofType: PageTemplateCategory.self)
        for category in categories {
            let _ = PageTemplateCategory(context: context, category: category)
        }
    }

    private static func persistLayoutsToCoreData(_ layouts: [RemoteLayout], context: NSManagedObjectContext) throws {
        context.deleteAllObjects(ofType: PageTemplateLayout.self)

        for layout in layouts {
            let localLayout = PageTemplateLayout(context: context, layout: layout)
            try associate(layout: localLayout, toCategories: layout.categories, context: context)
        }
    }

    private static func associate(layout: PageTemplateLayout, toCategories categories: [RemoteLayoutCategory], context: NSManagedObjectContext) throws {
        let categoryList = categories.map({ $0.slug })
        let request: NSFetchRequest<PageTemplateCategory> = PageTemplateCategory.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(PageTemplateCategory.slug)) IN %@", categoryList)
        let fetchedCategories = try context.fetch(request)
        layout.categories = Set(fetchedCategories)
    }
}
