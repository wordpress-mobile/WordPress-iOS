import Foundation


public class Tracks
{
    // MARK: - Public Properties
    public var wpcomUsername        : String?

    // MARK: - Private Properties
    private let uploader            : Uploader

    // MARK: - Constants
    private static let version      = "1.0"
    private static let userAgent    = "Nosara Extensions Client for iOS Mark " + version



    // MARK: - Initializers
    init(appGroupName: String) {
        uploader = Uploader(appGroupName: appGroupName)
    }



    // MARK: - Public Methods
    public func track(eventName: String, properties: [String: AnyObject]? = nil) {
        let payload  = payloadWithEventName(eventName, properties: properties)
        uploader.send(payload)
    }



    // MARK: - Private Helpers
    private func payloadWithEventName(eventName: String, properties: [String: AnyObject]?) -> [String: AnyObject] {
        let timestamp   = NSDate().timeIntervalSince1970 * 1000
        let userID      = NSUUID().UUIDString
        let device      = UIDevice.currentDevice()
        let bundle      = NSBundle.mainBundle()
        let appName     = bundle.objectForInfoDictionaryKey("CFBundleName") as? String
        let appVersion  = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String
        let appCode     = bundle.objectForInfoDictionaryKey("CFBundleVersion") as? String

        // Main Payload
        var payload = [
            "_en"                           : eventName,
            "_ts"                           : timestamp,
            "_via_ua"                       : Tracks.userAgent,
            "_rt"                           : timestamp,
            "device_info_app_name"          : appName       ?? "WordPress",
            "device_info_app_version"       : appVersion    ?? "Unknown",
            "device_info_app_version_code"  : appCode       ?? "Unknown",
            "device_info_os"                : device.systemName,
            "device_info_os_version"        : device.systemVersion
        ] as [String: AnyObject]

        // Username
        if let username = wpcomUsername {
            payload["_ul"] = username
            payload["_ut"] = "wpcom:user_id"
        } else {
            payload["_ui"] = userID
            payload["_ut"] = "anon"
        }

        // Inject the custom properties
        if let theProperties = properties {
            for (key, value) in theProperties {
                payload[key] = value
            }
        }

        return payload
    }



    /// Private Internal Helper:
    /// Encapsulates all of the Backend Tracks Interaction, and deals with NSURLSession's API.
    ///
    private class Uploader: NSObject, NSURLSessionDelegate
    {
        // MARK: - Properties
        private var session : NSURLSession!

        // MARK: - Constants
        private let tracksURL   = "https://public-api.wordpress.com/rest/v1.1/tracks/record"
        private let httpMethod  = "POST"
        private let headers     = [ "Content-Type"  : "application/json",
                                    "Accept"        : "application/json",
                                    "User-Agent"    : "WPiOS App Extension"]


        // MARK: - Deinitializers
        deinit {
            session.finishTasksAndInvalidate()
        }


        // MARK: - Initializers
        init(appGroupName: String) {
            super.init()

            // Random Identifier (Each Time)
            let identifier = appGroupName + "." + NSUUID().UUIDString

            // Session Configuration
            let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
            configuration.sharedContainerIdentifier = appGroupName

            // URL Session
            session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
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
