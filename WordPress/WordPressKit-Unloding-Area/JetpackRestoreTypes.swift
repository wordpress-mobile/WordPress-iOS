public struct JetpackRestoreTypes {
    public var themes: Bool
    public var plugins: Bool
    public var uploads: Bool
    public var sqls: Bool
    public var roots: Bool
    public var contents: Bool

    public init(themes: Bool = true,
                plugins: Bool = true,
                uploads: Bool = true,
                sqls: Bool = true,
                roots: Bool = true,
                contents: Bool = true) {
        self.themes = themes
        self.plugins = plugins
        self.uploads = uploads
        self.sqls = sqls
        self.roots = roots
        self.contents = contents
    }

    func toDictionary() -> [String: AnyObject] {
        return [
            "themes": themes as AnyObject,
            "plugins": plugins as AnyObject,
            "uploads": uploads as AnyObject,
            "sqls": sqls as AnyObject,
            "roots": roots as AnyObject,
            "contents": contents as AnyObject
        ]
    }
}
