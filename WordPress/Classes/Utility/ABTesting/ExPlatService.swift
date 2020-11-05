import Foundation

class ExPlatService {
    let platform: String
    let oAuthToken: String?
    let userAgent: String?
    let anonId: String?

    var assignmentsEndpoint: String {
        return "https://public-api.wordpress.com/wpcom/v2/experiments/0.1.0/assignments/\(platform)"
    }

    init(platform: String,
         oAuthToken: String? = nil,
         userAgent: String? = nil,
         anonId: String? = nil) {
        self.platform = platform
        self.oAuthToken = oAuthToken
        self.userAgent = userAgent
        self.anonId = anonId
    }

    func getAssignments(completion: @escaping (Assignments?) -> Void) {
        guard var urlComponents = URLComponents(string: assignmentsEndpoint) else {
            completion(nil)
            return
        }

        // Query items
        urlComponents.queryItems = [URLQueryItem(name: "_locale", value: Locale.current.languageCode)]

        if let anonId = anonId {
            urlComponents.queryItems?.append(URLQueryItem.init(name: "anon_id", value: anonId))
        }

        guard let url = urlComponents.url else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // HTTP fields (including oAuthToken if provided)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        if let oAuthToken = oAuthToken {
            request.setValue( "Bearer \(oAuthToken)", forHTTPHeaderField: "Authorization")
        }

        // User-Agent
        if let userAgent = userAgent {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let assignments = try decoder.decode(Assignments.self, from: data)
                completion(assignments)
            } catch {
                DDLogError("Error parsing the experiment response: \(error)")
                completion(nil)
            }
        }

        task.resume()
    }
}

extension ExPlatService {
    class func withDefaultApi() -> ExPlatService {
        let accountService = AccountService(managedObjectContext: ContextManager.shared.mainContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return ExPlatService(platform: "calypso", oAuthToken: token, userAgent: WPUserAgent.wordPress())
    }
}
