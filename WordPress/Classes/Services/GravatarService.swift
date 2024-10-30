import Foundation
import WordPressKit
import Gravatar

@objc public enum GravatarServiceError: Int, Error {
    case invalidAccountInfo
}

public protocol GravatarImageUploader {
    @discardableResult
    func upload(_ image: UIImage, selectionBehavior: AvatarSelection, accessToken: String) async throws -> AvatarType
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
            DDLogError("\(error.debugDescription)")
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
                // The `/v3` gravatar upload endpoint expects the image to be a perfect square, otherwise fails.
                // Thus, we call `.squared()` (which will do nothing if the image is already square).
                // cropping(to: ...) sometimes generates edges a few pixels uneven. So `.squared()` will compensate.
                try await imageUploader.upload(image.squared(), selectionBehavior: .selectUploadedImage(for: Email(email)), accessToken: accountToken)
                DDLogInfo("GravatarService.uploadImage Success!")
                completion?(nil)
            } catch {
                DDLogError("GravatarService.uploadImage Error: \(error)")
                completion?(error)
            }
        }
    }
}
