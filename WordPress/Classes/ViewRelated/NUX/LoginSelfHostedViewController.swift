import UIKit

class LoginSelfHostedViewController: SigninSelfHostedViewController {
    var gravatarProfile: GravatarProfile?
    var userProfile: UserProfile?

    override func needsMultifactorCode() {
        performSegue(withIdentifier: .show2FA, sender: self)
    }


    override func dismiss() {
        configureViewLoading(false)
        performSegue(withIdentifier: .showEpilogue, sender: self)
    }


    override func finishedLogin(withUsername username: String!, password: String!, xmlrpc: String!, options: [AnyHashable: Any]!) {
        displayLoginMessage(NSLocalizedString("", comment: ""))

        BlogSyncFacade().syncBlog(withUsername: username, password: password, xmlrpc: xmlrpc, options: options) { [weak self] in
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: SigninHelpers.WPSigninDidFinishNotification), object: nil)

            let context = ContextManager.sharedInstance().mainContext
            let service = BlogService(managedObjectContext: context)
            guard let blog = service.findBlog(withXmlrpc: xmlrpc, andUsername: username) else {
                assertionFailure("A blog was just added but was not found in core data.")
                self?.dismiss()
                return
            }

            RecentSitesService().touch(blog: blog)

            self?.fetchUserProfileInfo(blog: blog, completion: {
                self?.dismiss()
            })
        }
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        // Ensure that the user info is set on the epilogue vc.
        if let vc = segue.destination as? LoginEpilogueViewController {
            vc.epilogueUserInfo = epilogueUserInfo()
        }
    }


    /// Returns an instance of LoginEpilogueUserInfo composed from
    /// a user's gravatar profile, and/or self-hosted blog profile.
    ///
    func epilogueUserInfo() -> LoginEpilogueUserInfo {
        var info = LoginEpilogueUserInfo()
        if let profile = gravatarProfile {
            info.gravatarUrl = profile.thumbnailUrl
            info.fullName = profile.displayName
        }

        // Whatever is in user profile trumps whatever is in the gravatar profile.
        if let profile = userProfile {
            info.username = profile.username
            info.fullName = profile.displayName
            info.email = profile.email
        }

        return info
    }


    /// Fetches the user's profile data from their blog. If success, it next queries
    /// the user's gravatar profile data passing the completion block.
    ///
    func fetchUserProfileInfo(blog: Blog, completion: @escaping (() -> Void )) {
        let service = UsersService()
        service.fetchProfile(blog: blog, success: { [weak self] (profile) in
            self?.userProfile = profile
            self?.fetchGravatarProfileInfo(email: profile.email, completion: completion)
        }, failure: { [weak self] (_) in
            self?.dismiss()
        })
    }


    /// Queries the user's gravatar profile data. On success calls completion.
    ///
    func fetchGravatarProfileInfo(email: String, completion: @escaping (() -> Void )) {
        let service = GravatarService()
        service.fetchProfile(email, success: { [weak self] (profile) in
            self?.gravatarProfile = profile
            completion()
        }, failure: { [weak self] (_) in
            self?.dismiss()
        })
    }
}
