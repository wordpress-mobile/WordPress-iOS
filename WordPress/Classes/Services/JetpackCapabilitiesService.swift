import WordPressKit

@objc class JetpackCapabilitiesService: NSObject {

    let capabilitiesServiceRemote: JetpackCapabilitiesServiceRemote

    init(context: NSManagedObjectContext = ContextManager.shared.mainContext,
         capabilitiesServiceRemote: JetpackCapabilitiesServiceRemote? = nil) {
        let api = WordPressComRestApi.defaultApi(in: context, localeKey: WordPressComRestApi.LocaleKeyV2)

        self.capabilitiesServiceRemote = capabilitiesServiceRemote ?? JetpackCapabilitiesServiceRemote(wordPressComRestApi: api)
    }

    override init() {
        let api = WordPressComRestApi.defaultApi(in: ContextManager.shared.mainContext, localeKey: WordPressComRestApi.LocaleKeyV2)

        self.capabilitiesServiceRemote = JetpackCapabilitiesServiceRemote(wordPressComRestApi: api)
        super.init()
    }

    /// Returns an array of [RemoteBlog] with the Jetpack capabilities added in `capabilities`
    /// - Parameters:
    ///   - blogs: An array of RemoteBlog
    ///   - success: A block that accepts an array of RemoteBlog
    @objc func sync(blogs: [RemoteBlog], success: @escaping ([RemoteBlog]) -> Void) {
        capabilitiesServiceRemote.for(siteIds: blogs.compactMap { $0.blogID as? Int },
                 success: { capabilities in
                    blogs.forEach { blog in
                        if let cap = capabilities["\(blog.blogID!)"] as? [String] {
                            cap.forEach { blog.capabilities[$0] = true }
                        }
                    }
                    success(blogs)
                 })
    }

}
