import Foundation

final class BasicUserProfileViewModel {

    let email: String

    init(email: String) {
        self.email = email
    }

    func fetchUserDetails(completion: @escaping (GravatarProfile?) -> Void) {
        let service = GravatarService()
        service.fetchProfile(email: email, onCompletion: completion)
    }
}
