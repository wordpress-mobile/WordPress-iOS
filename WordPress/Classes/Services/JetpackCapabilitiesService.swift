import WordPressKit

@objc class JetpackCapabilitiesService: NSObject {

    let capabilitiesServiceRemote: JetpackCapabilitiesServiceRemote

    init(coreDataStack: CoreDataStack, capabilitiesServiceRemote: JetpackCapabilitiesServiceRemote?) {
        if let capabilitiesServiceRemote {
            self.capabilitiesServiceRemote = capabilitiesServiceRemote
        } else {
            var api: WordPressComRestApi!
            coreDataStack.performAndSave {
                api = WordPressComRestApi.defaultApi(in: $0, localeKey: WordPressComRestApi.LocaleKeyV2)
            }

            self.capabilitiesServiceRemote = JetpackCapabilitiesServiceRemote(wordPressComRestApi: api)
        }
    }

    override convenience init() {
        self.init(coreDataStack: ContextManager.shared, capabilitiesServiceRemote: nil)
    }

    /// Returns an array of [RemoteBlog] with the Jetpack capabilities added in `capabilities`
    /// - Parameters:
    ///   - blogs: An array of RemoteBlog
    ///   - success: A block that accepts an array of RemoteBlog
    @objc func sync(blogs: [RemoteBlog], success: @escaping ([RemoteBlog]) -> Void) {
        capabilitiesServiceRemote.for(siteIds: blogs.compactMap { $0.blogID as? Int },
                 success: { capabilities in
                    blogs.forEach { blog in
                        if let cap = capabilities["\(blog.blogID)"] as? [String] {
                            cap.forEach { blog.capabilities[$0] = true }
                        }
                    }
                    success(blogs)
                 })
    }

}
