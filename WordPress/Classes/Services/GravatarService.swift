import Foundation
import CocoaLumberjack
import WordPressKit
import Gravatar

@objc public enum GravatarServiceError: Int, Error {
    case invalidAccountInfo
}

public protocol GravatarImageUploader {
    @discardableResult
    func upload(_ image: UIImage, email: Email, accessToken: String) async throws -> URLResponse
}

extension AvatarService: GravatarImageUploader { }

/// This Service exposes all of the valid operations we can execute, to interact with the Gravatar Service.
///
public class GravatarService {

    let imageUploader: GravatarImageUploader

    init(imageUploader: GravatarImageUploader? = nil) {
        self.imageUploader = imageUploader ?? AvatarService()
    }

    /// This method fetches the Gravatar profile for the specified email address.
    ///
    /// - Parameters:
    ///     - email: The email address of the gravatar profile to fetch.
    ///     - completion: A completion block.
    ///
    open func fetchProfile(email: String, onCompletion: @escaping ((_ profile: GravatarProfile?) -> Void)) {
        let remote = GravatarServiceRemote()
        remote.fetchProfile(email, success: { remoteProfile in
            var profile = GravatarProfile()
            profile.profileID = remoteProfile.profileID
            profile.hash = remoteProfile.hash
            profile.requestHash = remoteProfile.requestHash
            profile.profileUrl = remoteProfile.profileUrl
            profile.preferredUsername = remoteProfile.preferredUsername
            profile.thumbnailUrl = remoteProfile.thumbnailUrl
            profile.name = remoteProfile.name
            profile.displayName = remoteProfile.displayName
            onCompletion(profile)

        }, failure: { error in
            DDLogError(error.debugDescription)
            onCompletion(nil)
        })
    }

    /// This method hits the Gravatar Endpoint, and uploads a new image, to be used as profile.
    ///
    /// - Parameters:
    ///     - image: The new Gravatar Image, to be uploaded
    ///     - account: The WPAccount instance for which to upload a new image.
    ///     - completion: An optional closure to be executed on completion.
    ///
    open func uploadImage(_ image: UIImage, forAccount account: WPAccount, completion: ((_ error: Error?) -> ())? = nil) {
        guard
            let accountToken = account.authToken, !accountToken.isEmpty,
            let accountEmail = account.email, !accountEmail.isEmpty else {
                completion?(GravatarServiceError.invalidAccountInfo)
                return
        }

        let email = accountEmail.trimmingCharacters(in: CharacterSet.whitespaces).lowercased()

        Task {
            do {
                try await imageUploader.upload(image, email: Email(email), accessToken: accountToken)
                DDLogInfo("GravatarService.uploadImage Success!")
                completion?(nil)
            } catch {
                DDLogError("GravatarService.uploadImage Error: \(error)")
                completion?(error)
            }
        }
    }
}
