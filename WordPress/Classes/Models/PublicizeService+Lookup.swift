extension PublicizeService {
    /// Finds a cached `PublicizeService` matching the specified service name.
    ///
    /// - Parameter name: The name of the service. This is the `serviceID` attribute for a `PublicizeService` object.
    ///
    /// - Returns: The requested `PublicizeService` or nil.
    ///
    static func lookupPublicizeServiceNamed(_ name: String, in context: NSManagedObjectContext) throws -> PublicizeService? {
        let request = NSFetchRequest<PublicizeService>(entityName: PublicizeService.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "serviceID = %@", name)
        return try context.fetch(request).first
    }

    @objc(lookupPublicizeServiceNamed:inContext:)
    static func objc_lookupPublicizeServiceNamed(_ name: String, in context: NSManagedObjectContext) -> PublicizeService? {
        try? lookupPublicizeServiceNamed(name, in: context)
    }

    /// Returns an array of all cached `PublicizeService` objects.
    ///
    /// - Returns: An array of `PublicizeService`.  The array is empty if no objects are cached.
    ///
    @objc(allPublicizeServicesInContext:error:)
    static func allPublicizeServices(in context: NSManagedObjectContext) throws -> [PublicizeService] {
        let request = NSFetchRequest<PublicizeService>(entityName: PublicizeService.classNameWithoutNamespaces())
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        return try context.fetch(request)
    }
}
