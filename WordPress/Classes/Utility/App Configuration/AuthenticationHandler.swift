import WordPressAuthenticator

protocol AuthenticationHandler {
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void)

    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void) -> Bool
}
