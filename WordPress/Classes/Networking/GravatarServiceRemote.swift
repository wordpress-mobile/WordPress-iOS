import Foundation


/// This ServiceRemote encapsulates all of the interaction with the Gravatar endpoint.
///
open class GravatarServiceRemote {

    /// This method hits the Gravatar Endpoint, and uploads a new image, to be used as profile.
    ///
    /// - Parameters:
    ///     - image: The new Gravatar Image, to be uploaded
    ///     - completion: An optional closure to be executed on completion.
    ///
    open func uploadImage(_ image: UIImage, accountEmail: String, accountToken: String, completion: ((_ error: NSError?) -> ())?) {
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
        let gravatarData = UIImagePNGRepresentation(image)!
        let requestBody = bodyWithGravatarData(gravatarData, account: accountEmail, boundary: boundary)

        // Task
        let session = URLSession.shared
        let task = session.uploadTask(with: request as URLRequest, from: requestBody, completionHandler: { (data, response, error) in
            completion?(error as NSError?)
        })

        task.resume()
    }


    // MARK: - Private Helpers

    /// Returns a new (randomized) Boundary String
    ///
    fileprivate func boundaryForRequest() -> String {
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
    fileprivate func bodyWithGravatarData(_ gravatarData: Data, account: String, boundary: String) -> Data {
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
    fileprivate struct UploadParameters {
        static let endpointURL          = "https://api.gravatar.com/v1/upload-image"
        static let HTTPMethod           = "POST"
        static let contentType          = "application/octet-stream"
        static let filename             = "profile.png"
        static let imageKey             = "filedata"
        static let accountKey           = "account"
    }
}
