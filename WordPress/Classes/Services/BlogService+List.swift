import Foundation

extension BlogService {
    func listBlogs(in context: NSManagedObjectContext) throws -> [Blog] {
        try context.fetch(Blog.fetchRequest()).compactMap { $0 as? Blog }
    }
}
