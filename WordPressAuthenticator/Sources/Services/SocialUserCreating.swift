/// A type that can create WordPress.com users given a social users, either coming from Google or Apple.
protocol SocialUserCreating: AnyObject {

    func createWPComUserWithGoogle(
        token: String,
        success: @escaping (_ newAccount: Bool, _ username: String, _ wpcomToken: String) -> Void,
        failure: @escaping (_ error: Error) -> Void
    )

    func createWPComUserWithApple(
        token: String,
        email: String,
        fullName: String?,
        success: @escaping (
            _ newAccount: Bool,
            _ existingNonSocialAccount: Bool,
            _ existing2faAccount: Bool,
            _ username: String,
            _ wpcomToken: String
        ) -> Void,
        failure: @escaping (_ error: Error) -> Void
    )
}
