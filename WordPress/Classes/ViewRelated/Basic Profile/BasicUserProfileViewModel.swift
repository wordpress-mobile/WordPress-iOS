import Foundation

final class BasicUserProfileViewModel {
    let email: String?
    let avatarURL: URL?
    let emailHash: String

    private lazy var blogService = BlogServiceRemoteREST(wordPressComRestApi: .defaultApi(),
                                                         siteID: NSNumber(value: 0))

    init?(email: String?, avatarURL: URL?) {
        if let email = email, (email as NSString).isValidEmail() {
            emailHash = (email as NSString).md5()
            self.email = email
            self.avatarURL = nil
        } else if let avatarURL = avatarURL {
            emailHash = avatarURL.lastPathComponent
            self.email = nil
            self.avatarURL = avatarURL
        } else {
            return nil
        }
    }

    func fetchSiteIcon(url: String, completion: @escaping (String, String?) -> Void) {
        guard let siteURL = URL(string: url),
            siteURL.isHostedAtWPCom else {
                completion(url, nil)
                return
        }
        blogService.fetchSiteInfo(forAddress: siteURL.host, success: { (dict) in
            let blog = RemoteBlog(jsonDictionary: dict)
            if let iconUrl = blog?.icon {
                completion(url, iconUrl)
            }
            completion(url, nil)
        }) { _ in
            completion(url, nil)
        }
    }

    func fetchUserDetails(completion: @escaping (GravatarProfile?) -> Void) {
        let service = GravatarService()
        service.fetchProfile(hash: emailHash, onCompletion: completion)
    }
}
