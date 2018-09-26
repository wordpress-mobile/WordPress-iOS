import UIKit

open class Tracks {
    // MARK: - Public Properties
    open var wpcomUsername: String?

    // MARK: - Private Properties
    fileprivate let uploader: Uploader

    // MARK: - Constants
    fileprivate static let version      = "1.0"
    fileprivate static let userAgent    = "Nosara Extensions Client for iOS Mark " + version



    // MARK: - Initializers
    init(appGroupName: String) {
        uploader = Uploader(appGroupName: appGroupName)
    }



    // MARK: - Public Methods
    open func track(_ eventName: String, properties: [String: Any]? = nil) {
        let payload  = payloadWithEventName(eventName, properties: properties)
        uploader.send(payload)
    }



    // MARK: - Private Helpers
    fileprivate func payloadWithEventName(_ eventName: String, properties: [String: Any]?) -> [String: Any] {
        let timestamp   = NSNumber(value: Int64(Date().timeIntervalSince1970 * 1000) as Int64)
        let userID      = UUID().uuidString
        let device      = UIDevice.current
        let bundle      = Bundle.main
        let appName     = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        let appVersion  = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let appCode     = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        // Main Payload
        var payload = [
            "_en": eventName as Any,
            "_ts": timestamp,
            "_via_ua": Tracks.userAgent as Any,
            "_rt": timestamp,
            "device_info_app_name": appName as Any?       ?? "WordPress" as Any,
            "device_info_app_version": appVersion as Any?    ?? "Unknown",
            "device_info_app_version_code": appCode       ?? "Unknown",
            "device_info_os": device.systemName,
            "device_info_os_version": device.systemVersion
        ] as [String: Any]

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
    fileprivate class Uploader: NSObject, URLSessionDelegate {
        // MARK: - Properties
        fileprivate var session: Foundation.URLSession!

        // MARK: - Constants
        fileprivate let tracksURL   = "https://public-api.wordpress.com/rest/v1.1/tracks/record"
        fileprivate let httpMethod  = "POST"
        fileprivate let headers     = [ "Content-Type": "application/json",
                                    "Accept": "application/json",
                                    "User-Agent": "WPiOS App Extension"]


        // MARK: - Deinitializers
        deinit {
            session.finishTasksAndInvalidate()
        }


        // MARK: - Initializers
        init(appGroupName: String) {
            super.init()

            // Random Identifier (Each Time)
            let identifier = appGroupName + "." + UUID().uuidString

            // Session Configuration
            let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
            configuration.sharedContainerIdentifier = appGroupName

            // URL Session
            session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        }



        // MARK: - Public Methods
        func send(_ event: [String: Any]) {
            // Build the targetURL
            let targetURL = URL(string: tracksURL)!

            // Payload
            let dataToSend = [ "events": [event], "commonProps": [] ]
            let requestBody = try? JSONSerialization.data(withJSONObject: dataToSend, options: .prettyPrinted)

            // Request
            var request = URLRequest(url: targetURL)
            request.httpMethod = httpMethod
            request.httpBody = requestBody

            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field)
            }

            // Task!
            let task = session.downloadTask(with: request)
            task.resume()
        }



        // MARK: - NSURLSessionDelegate
        @objc func URLSession(_ session: Foundation.URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
            print("<> Tracker.didCompleteWithError: \(String(describing: error))")
        }

        @objc func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            print("<> Tracker.didBecomeInvalidWithError: \(String(describing: error))")
        }

        @objc func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            print("<> Tracker.URLSessionDidFinishEventsForBackgroundURLSession")
        }
    }
}
