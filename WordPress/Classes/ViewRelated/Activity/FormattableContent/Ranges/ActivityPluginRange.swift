
class ActivityPluginRange: ActivityRange {
    let siteSlug: String
    let pluginSlug: String

    init(range: NSRange, pluginSlug: String, siteSlug: String) {
        self.pluginSlug = pluginSlug
        self.siteSlug = siteSlug

        super.init(kind: .plugin, range: range, url: nil)
    }

    override var url: URL? {
        return URL(string: urlString)
    }

    private var urlString: String {
        return "https://wordpress.com/plugins/\(pluginSlug)/\(siteSlug)"
    }

    private static func urlWith(pluginSlug: String, siteSlug: String) -> URL? {
        let urlString = "https://wordpress.com/plugins/\(pluginSlug)/\(siteSlug)"
        return URL(string: urlString)
    }
}
