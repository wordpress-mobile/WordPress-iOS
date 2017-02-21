extension AbstractPost {
    /// Represent the supported properties used to sort posts.
    ///
    enum SortField {
        case dateCreated
        case dateModified

        /// The keyPath to access the underlying property.
        ///
        var keyPath: String {
            switch self {
            case .dateCreated:
                return #keyPath(AbstractPost.date_created_gmt)
            case .dateModified:
                return #keyPath(AbstractPost.dateModified)
            }
        }
    }
}
