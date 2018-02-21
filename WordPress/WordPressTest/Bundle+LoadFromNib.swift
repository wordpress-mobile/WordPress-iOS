
// MARK: - Helper method to load UIViews from their xib file.
extension Bundle {
    static func loadRootViewFromNib<T: AnyObject>(type: T.Type) -> T? {
        let bundle = Bundle(for: type as AnyClass)
        return bundle.loadNibNamed(String(describing: type), owner: nil, options: nil)?.first as? T
    }
}

