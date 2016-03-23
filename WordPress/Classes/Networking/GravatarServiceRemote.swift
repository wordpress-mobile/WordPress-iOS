import Foundation


/// This ServiceRemote encapsulates all of the interaction with the Gravatar endpoint.
///
public class GravatarServiceRemote
{
    /// Designated Initializer
    ///
    /// - Parameters:
    ///     - accountToken: A valid WordPress.com User Token
    ///     - accountEmail: Account Email
    ///
    public init(accountToken: String, accountEmail: String) {
        self.accountToken   = accountToken
        self.accountEmail   = accountEmail
    }
    
    
    /// This method hits the Gravatar Endpoint, and uploads a new image, to be used as profile.
    ///
    /// - Parameters:
    ///     - image: The new Gravatar Image, to be uploaded
    ///     - completion: An optional closure to be executed on completion.
    ///
    public func uploadImage(image: UIImage, completion: ((error: NSError?) -> ())?) {
        guard let targetURL = NSURL(string: UploadParameters.endpointURL) else {
            assertionFailure()
            return
        }
        
        // Boundary
        let boundary = boundaryForRequest()
        
        // Request
        let request = NSMutableURLRequest(URL: targetURL)
        request.HTTPMethod = UploadParameters.HTTPMethod
        request.setValue("Bearer \(accountToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Body
        let gravatarData = UIImagePNGRepresentation(image)!
        let requestBody = bodyWithGravatarData(gravatarData, account: accountEmail, boundary: boundary)
        
        // Task
        let session = NSURLSession.sharedSession()
        let task = session.uploadTaskWithRequest(request, fromData: requestBody) { (data, response, error) in
            completion?(error: error)
        }
        
        task.resume()
    }
    
    
    
    // MARK: - Private Helpers
    
    /// Returns a new (randomized) Boundary String
    ///
    private func boundaryForRequest() -> String {
        return "Boundary-" + NSUUID().UUIDString
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
    private func bodyWithGravatarData(gravatarData: NSData, account: String, boundary: String) -> NSData {
        let body = NSMutableData()
        
        // Image Payload
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\(UploadParameters.imageKey); ")
        body.appendString("filename=\(UploadParameters.filename)\r\n")
        body.appendString("Content-Type: \(UploadParameters.contentType);\r\n\r\n")
        body.appendData(gravatarData)
        body.appendString("\r\n")
        
        // Account Payload
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(UploadParameters.accountKey)\"\r\n\r\n")
        body.appendString("\(account)\r\n")
        
        // EOF!
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
    
    
    
    // MARK: - Private Properties
    private let accountEmail    : String
    private let accountToken    : String
    
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
