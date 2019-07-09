import WordPressComStatsiOS

extension BlogDetailsViewController {
    @objc func statsService(siteId: NSNumber, siteTimeZone: TimeZone, oauth2Token: String, cacheExpirationInterval: TimeInterval) -> WPStatsService {
        return WPStatsService(siteId: siteId,
                              siteTimeZone: siteTimeZone,
                              oauth2Token: oauth2Token,
                              andCacheExpirationInterval: cacheExpirationInterval,
                              apiBaseUrlString: Environment.current.wordPressComApiBase)
    }
}
