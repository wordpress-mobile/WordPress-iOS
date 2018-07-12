
class ActivityPluginRange: ActivityRange {
    init(range: NSRange, pluginSlug: String, siteSlug: String) {
        let url = ActivityPluginRange.urlWith(pluginSlug: pluginSlug, siteSlug: siteSlug)
        super.init(kind: .plugin, range: range, url: url)
    }

    private static func urlWith(pluginSlug: String, siteSlug: String) -> URL? {
        let urlString = "https://wordpress.com/plugins/\(pluginSlug)/\(siteSlug)"
        return URL(string: urlString)
    }
}
