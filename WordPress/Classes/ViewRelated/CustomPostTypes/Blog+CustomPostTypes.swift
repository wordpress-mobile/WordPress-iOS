import WordPressData

extension Blog {
    var usesCustomPostTypeViewsForPostsAndPages: Bool {
        isSelfHosted && isXMLRPCDisabled
    }
}
