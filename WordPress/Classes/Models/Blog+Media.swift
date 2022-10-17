import Foundation

extension Blog {

    /// Get the number of items in a blog media library that are of a certain type.
    ///
    /// - Parameter mediaTypes: set of media type values to be considered in the counting.
    /// - Returns: Number of media assets matching the criteria.
    @objc(mediaLibraryCountForTypes:)
    func mediaLibraryCount(types mediaTypes: NSSet) -> Int {
        guard let context = managedObjectContext else {
            return 0
        }

        var count = 0
        context.performAndWait {
            var predicate = NSPredicate(format: "blog == %@", self)

            if mediaTypes.count > 0 {
                let types = mediaTypes
                    .map { obj in
                        guard let rawValue = (obj as? NSNumber)?.uintValue,
                              let type = MediaType(rawValue: rawValue) else {
                            fatalError("Can't convert \(obj) to MediaType")
                        }
                        return Media.string(from: type)
                    }
                let filterPredicate = NSPredicate(format: "mediaTypeString IN %@", types)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, filterPredicate])
            }

            count = context.countObjects(ofType: Media.self, matching: predicate)
        }
        return count
    }

}
