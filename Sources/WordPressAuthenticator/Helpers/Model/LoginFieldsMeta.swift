import WordPressKit

class LoginFieldsMeta {

    /// Indicates where the Magic Link Email was sent from.
    ///
    var emailMagicLinkSource: EmailMagicLinkSource?

    /// Indicates whether a self-hosted user is attempting to log in to Jetpack
    ///
    var jetpackLogin: Bool

    /// Indicates whether a user is logging in via the wpcom flow or a self-hosted flow.  Used by the
    /// the LoginFacade in its branching logic.
    /// This is a good candidate to refactor out and call the proper login method directly.
    ///
    var userIsDotCom: Bool

    /// Indicates a wpcom account created via social sign up that requires either a magic link, or a social log in option.
    /// If a user signed up via social sign up and subsequently reset their password this field will be false.
    ///
    var passwordless: Bool

    /// Should point to the site's xmlrpc.php for a self-hosted log in.  Should be the value returned via XML-RPC discovery.
    ///
    var xmlrpcURL: NSURL?

    /// Meta data about a site. This information is fetched and then displayed on the login epilogue.
    ///
    var siteInfo: WordPressComSiteInfo?

    /// Flags whether a 2FA challenge had to be satisfied before a log in could be complete.
    /// Included in analytics after a successful login.
    ///
    /// A `false` value means that a 2FA prompt was needed.
    ///
    var requiredMultifactor: Bool

    /// Identifies a social login and the service used.
    ///
    var socialService: SocialServiceName?

    var socialServiceIDToken: String?

    var socialUser: SocialUser?

    init(emailMagicLinkSource: EmailMagicLinkSource? = nil,
         jetpackLogin: Bool = false,
         userIsDotCom: Bool = true,
         passwordless: Bool = false,
         xmlrpcURL: NSURL? = nil,
         siteInfo: WordPressComSiteInfo? = nil,
         requiredMultifactor: Bool = false,
         socialService: SocialServiceName? = nil,
         socialServiceIDToken: String? = nil,
         socialUser: SocialUser? = nil) {
        self.emailMagicLinkSource = emailMagicLinkSource
        self.jetpackLogin = jetpackLogin
        self.userIsDotCom = userIsDotCom
        self.passwordless = passwordless
        self.xmlrpcURL = xmlrpcURL
        self.siteInfo = siteInfo
        self.requiredMultifactor = requiredMultifactor
        self.socialService = socialService
        self.socialServiceIDToken = socialServiceIDToken
        self.socialUser = socialUser
    }
}

extension LoginFieldsMeta {
    func copy() -> LoginFieldsMeta {
        .init(emailMagicLinkSource: emailMagicLinkSource,
              jetpackLogin: jetpackLogin,
              userIsDotCom: userIsDotCom,
              passwordless: passwordless,
              xmlrpcURL: xmlrpcURL,
              siteInfo: siteInfo,
              requiredMultifactor: requiredMultifactor,
              socialService: socialService,
              socialServiceIDToken: socialServiceIDToken,
              socialUser: socialUser)
    }
}
