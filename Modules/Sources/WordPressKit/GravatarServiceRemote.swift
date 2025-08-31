import Foundation

/// This ServiceRemote encapsulates all of the interaction with the Gravatar endpoint.
///
open class GravatarServiceRemote {
    let baseGravatarURL = "https://www.gravatar.com/"

    public init() {}

    /// This method fetches the Gravatar profile for the specified email address.
    ///
    /// - Parameters:
    ///     - email: The email address of the gravatar profile to fetch.
    ///     - success: A success block.
    ///     - failure: A failure block.
    ///
    open func fetchProfile(_ email: String, success: @escaping ((_ profile: RemoteGravatarProfile) -> Void), failure: @escaping ((_ error: Error?) -> Void)) {
        guard let hash = (email as NSString).md5() else {
            assertionFailure()
            return
        }

        fetchProfile(hash: hash, success: success, failure: failure)
    }

    /// This method fetches the Gravatar profile for the specified user hash value.
    ///
    /// - Parameters:
    ///     - hash: The hash value of the email address of the gravatar profile to fetch.
    ///     - success: A success block.
    ///     - failure: A failure block.
    ///
    open func fetchProfile(hash: String, success: @escaping ((_ profile: RemoteGravatarProfile) -> Void), failure: @escaping ((_ error: Error?) -> Void)) {
        let path = baseGravatarURL + hash + ".json"
        guard let targetURL = URL(string: path) else {
            assertionFailure()
            return
        }

        let session = URLSession.shared
        let task = session.dataTask(with: targetURL) { (data: Data?, _: URLResponse?, error: Error?) in
            guard error == nil, let data = data else {
                failure(error)
                return
            }
            do {
                let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

                guard let jsonDictionary = jsonData as? [String: [Any]],
                    let entry = jsonDictionary["entry"],
                    let profileData = entry.first as? NSDictionary else {
                        DispatchQueue.main.async {
                            // This case typically happens when the endpoint does
                            // successfully return but doesn't find the user.
                            failure(nil)
                        }
                        return
                }

                let profile = RemoteGravatarProfile(dictionary: profileData)
                DispatchQueue.main.async {
                    success(profile)
                }
                return

            } catch {
                failure(error)
                return
            }
        }

        task.resume()
    }

    /// This method hits the Gravatar Endpoint, and uploads a new image, to be used as profile.
    ///
    /// - Parameters:
    ///     - image: The new Gravatar Image, to be uploaded
    ///     - completion: An optional closure to be executed on completion.
    ///
    open func uploadImage(_ image: UIImage, accountEmail: String, accountToken: String, completion: ((_ error: NSError?) -> Void)?) {
        guard let targetURL = URL(string: UploadParameters.endpointURL) else {
            assertionFailure()
            return
        }

        // Boundary
        let boundary = boundaryForRequest()

        // Request
        let request = NSMutableURLRequest(url: targetURL)
        request.httpMethod = UploadParameters.HTTPMethod
        request.setValue("Bearer \(accountToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Body
        let gravatarData = image.pngData()!
        let requestBody = bodyWithGravatarData(gravatarData, account: accountEmail, boundary: boundary)

        // Task
        let session = URLSession.shared
        let task = session.uploadTask(with: request as URLRequest, from: requestBody, completionHandler: { (_, _, error) in
            completion?(error as NSError?)
        })

        task.resume()
    }

    // MARK: - Private Helpers

    /// Returns a new (randomized) Boundary String
    ///
    private func boundaryForRequest() -> String {
        return "Boundary-" + UUID().uuidString
    }

    /// Returns the Body for a Gravatar Upload OP.
    ///
    /// - Parameters:
    ///     - gravatarData: The NSData-Encoded Image
    ///     - account: The account that will get updated
    ///     - boundary: The request's Boundary String
    ///
    /// - Returns: A NSData instance, containing the Request's Payload.
    ///
    private func bodyWithGravatarData(_ gravatarData: Data, account: String, boundary: String) -> Data {
        let body = NSMutableData()

        // Image Payload
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\(UploadParameters.imageKey); ")
        body.appendString("filename=\(UploadParameters.filename)\r\n")
        body.appendString("Content-Type: \(UploadParameters.contentType);\r\n\r\n")
        body.append(gravatarData)
        body.appendString("\r\n")

        // Account Payload
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(UploadParameters.accountKey)\"\r\n\r\n")
        body.appendString("\(account)\r\n")

        // EOF!
        body.appendString("--\(boundary)--\r\n")

        return body as Data
    }

    // MARK: - Private Structs
    private struct UploadParameters {
        static let endpointURL          = "https://api.gravatar.com/v1/upload-image"
        static let HTTPMethod           = "POST"
        static let contentType          = "application/octet-stream"
        static let filename             = "profile.png"
        static let imageKey             = "filedata"
        static let accountKey           = "account"
    }
}
