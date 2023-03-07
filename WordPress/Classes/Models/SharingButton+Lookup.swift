extension SharingButton {

    /// Returns an array of all cached `SharingButtons` objects.
    ///
    /// - Returns: An array of `SharingButton`s.  The array is empty if no objects are cached.
    ///
    @objc(allSharingButtonsForBlog:inContext:error:)
    static func allSharingButtons(for blog: Blog, in context: NSManagedObjectContext) throws -> [SharingButton] {
        let request = NSFetchRequest<SharingButton>(entityName: SharingButton.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "blog = %@", blog)
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        return try context.fetch(request)
    }

    /// Finds a cached `SharingButton` by its `buttonID` for the specified `Blog`
    ///
    /// - Parameters:
    ///     - buttonID: The button ID of the `SharingButton`.
    ///     - blog: The blog that owns the sharing button.
    ///
    /// - Returns: The requested `SharingButton` or nil.
    ///
    static func lookupSharingButton(byID buttonID: String, for blog: Blog, in context: NSManagedObjectContext) throws -> SharingButton? {
        let request = NSFetchRequest<SharingButton>(entityName: SharingButton.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "buttonID = %@ AND blog = %@", buttonID, blog)
        return try context.fetch(request).first
    }

}
