import Foundation

struct NullBlogPropertySanitizer {
    func sanitize() {
        let context = ContextManager.shared.mainContext
        context.perform {
            [Post.entityName(),
             Page.entityName(),
             Media.entityName(),
             PostCategory.entityName()].forEach { entityName in
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                let predicate = NSPredicate(format: "blog == NULL")
                request.predicate = predicate
                let results = try? context.fetch(request)
                results?.forEach(context.delete)
            }
            try? context.save()
        }
    }
}
