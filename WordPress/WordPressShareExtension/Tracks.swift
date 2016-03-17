import Foundation


public class Tracks
{
    // MARK: - Properties
    private let groupName           : String
    
    // MARK: - Constants
    private static let version      = "1.0"
    private static let userAgent    = "Nosara Extensions Client for iOS Mark " + version
    
    // MARK: - Initializers
    init(groupName: String) {
        self.groupName = groupName
    }
    
    
    // MARK: - Public Methods
    public func track(eventName: String) {
        let payload  = payloadWithEventName(eventName)
        let uploader = Uploader(groupName: groupName)

        uploader.send(payload)
    }
    
    
    
    // MARK: - Private Helpers
    private func payloadWithEventName(eventName: String) -> [String: AnyObject] {
        let timestamp   = NSDate().timeIntervalSince1970 * 1000
        let userID      = NSUUID().UUIDString
        let device      = UIDevice.currentDevice()
        let bundle      = NSBundle.mainBundle()
        let appName     = bundle.objectForInfoDictionaryKey("CFBundleName") as? String
        let appVersion  = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String
        let appCode     = bundle.objectForInfoDictionaryKey("CFBundleVersion") as? String
        
        return [
            "_en"                                   : eventName,
            "_ts"                                   : timestamp,
            "_ui"                                   : userID,
            "_ut"                                   : "anon",
            "_via_ua"                               : Tracks.userAgent,
            "_rt"                                   : timestamp,
            "device_info_app_name"                  : appName       ?? "WordPress",
            "device_info_app_version"               : appVersion    ?? "Unknown",
            "device_info_app_version_code"          : appCode       ?? "Unknown",
            "device_info_os"                        : device.systemName,
            "device_info_os_version"                : device.systemVersion
        ] as [String: AnyObject]
    }
    
    
    
    /// Private Internal Helper:
    /// Encapsulates all of the Backend Tracks Interaction, and deals with NSURLSession's API.
    ///
    private class Uploader: NSObject, NSURLSessionDelegate
    {
        // MARK: - Properties
        private let groupName : String
        
        // MARK: - Constants
        private let tracksURL   = "https://public-api.wordpress.com/rest/v1.1/tracks/record"
        private let httpMethod  = "POST"
        private let headers     = [ "Content-Type"  : "application/json",
                                    "Accept"        : "application/json",
                                    "User-Agent"    : "WPiOS App Extension"]
        
        // MARK: - Initializers
        init(groupName: String) {
            self.groupName = groupName
        }
        
        
        
        // MARK: - Public Methods
        func send(event: [String: AnyObject]) {
            // Build the targetURL
            let targetURL = NSURL(string: tracksURL)!
            
            // Payload
            let dataToSend = [ "events" : [event], "commonProps" : [] ]
            let requestBody = try? NSJSONSerialization.dataWithJSONObject(dataToSend, options: .PrettyPrinted)
            
            // Request
            let request = NSMutableURLRequest(URL: targetURL)
            request.HTTPMethod = httpMethod
            request.HTTPBody = requestBody
            
            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field)
            }
            
            // Task!
            let sc = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(groupName)
            sc.sharedContainerIdentifier = groupName

            let session = NSURLSession(configuration: sc, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
            let task = session.downloadTaskWithRequest(request)
            task.resume()
        }
        
        
        
        // MARK: - NSURLSessionDelegate
        @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
            print("<> Tracker.didCompleteWithError: \(error)")
        }
        
        @objc func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
            print("<> Tracker.didBecomeInvalidWithError: \(error)")
        }
        
        @objc func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
            print("<> Tracker.URLSessionDidFinishEventsForBackgroundURLSession")
        }
    }
}
