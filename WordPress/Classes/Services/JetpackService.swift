/// Local service for Jetpack
///
class JetpackService {
    private let service = JetpackServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi())

    /// This method installs remotely Jetpack in a self-hosted blog.
    ///
    /// - Parameters:
    ///   - url: The self-hosted site url string
    ///   - username: The username for the self-hosted site
    ///   - password: The password for the self-hosted site
    ///   - completion: The completion block used to handle if the service will succeed or fail with a specific error
    func installJetpack(url: String,
                        username: String,
                        password: String,
                        completion: @escaping (Bool, JetpackInstallError?) -> Void) {
        service.installJetpack(url: url, username: username, password: password, completion: completion)
    }
}
