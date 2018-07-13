class ActivityLogTestData {

    let contextManager = TestContextManager()

    let testPostID = 441
    let testSiteID = 137726971

    let pingbackText = "Pingback to Camino a Machu Picchu from Tren de Machu Picchu a Cusco – eToledo"
    let postText = "Tren de Machu Picchu a Cusco"
    let commentText = "Comment by levitoledo on Hola Lima! 🇵🇪: Great post! True talent!"
    let themeText = "Spatial"
    let settingsText = "Default post category changed from \"subcategory\" to \"viajes\""
    let siteText = "Atomic"
    let pluginText = "WP Job Manager 1.31.1"

    let testPluginSlug = "wp-job-manager"
    let testSiteSlug = "etoledomatomicsite01.blog"

    var testPostUrl: String {
        return "https://wordpress.com/read/blogs/\(testSiteID)/posts/\(testPostID)"
    }
    var testPluginUrl: String {
        return "https://wordpress.com/plugins/\(testPluginSlug)/\(testSiteSlug)"
    }

    private func getDictionaryFromFile(named fileName: String) -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String: AnyObject]
    }

    func getPingbackDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-pingback-content.json")
    }

    func getPostContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-post-content.json")
    }

    func getCommentContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-comment-content.json")
    }

    func getThemeContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-theme-content.json")
    }

    func getSettingsContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-settings-content.json")
    }

    func getSiteContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-site-content.json")
    }

    func getPluginContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-plugin-content.json")
    }

    func getCommentRangeDictionary() -> [String: AnyObject] {
        let dictionary = getCommentContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    func getPostRangeDictionary() -> [String: AnyObject] {
        let dictionary = getPostContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    func getThemeRangeDictionary() -> [String: AnyObject] {
        let dictionary = getThemeContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    func getItalicRangeDictionary() -> [String: AnyObject] {
        let dictionary = getSettingsContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    func getSiteRangeDictionary() -> [String: AnyObject] {
        let dictionary = getSiteContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    func getPluginRangeDictionary() -> [String: AnyObject] {
        let dictionary = getPluginContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    private func getRange(at index: Int, from dictionary: [String: AnyObject]) -> [String: AnyObject] {
        let ranges = getRanges(from: dictionary)
        return ranges[index]
    }

    private func getRanges(from dictionary: [String: AnyObject]) -> [[String: AnyObject]] {
        return dictionary["ranges"] as! [[String: AnyObject]]
    }
}
