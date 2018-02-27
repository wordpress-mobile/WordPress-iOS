// MARK: - Convenience extension to simplify testing code
extension Bundle {
    /// Load a xib file and returns its first view.
    /// Assumes that the xib and Swift file will have the same name
    ///
    /// - Parameter type: the actual type of the view we want to load
    /// - Returns: an optional instance of the type passed as parameter    
    static func loadRootViewFromNib<T: AnyObject>(type: T.Type) -> T? {
        let bundle = Bundle(for: type as AnyClass)
        return bundle.loadNibNamed(String(describing: type), owner: nil, options: nil)?.first as? T
    }
}
