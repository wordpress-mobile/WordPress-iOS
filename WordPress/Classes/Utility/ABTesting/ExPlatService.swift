import Foundation

class ExPlatService {
    let wordPressComRestApi: WordPressComRestApi

    let assignmentsPath = "wpcom/v2/experiments/0.1.0/assignments/calypso"

    init(wordPressComRestApi: WordPressComRestApi) {
        self.wordPressComRestApi = wordPressComRestApi
    }

    func getAssignments(completion: @escaping (Assignments?) -> Void) {
        wordPressComRestApi.GET(assignmentsPath,
                                parameters: nil,
                                success: { responseObject, _ in
                                    do {
                                        let decoder = JSONDecoder()
                                        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])
                                        let assignments = try decoder.decode(Assignments.self, from: data)
                                        completion(assignments)
                                    } catch {
                                        DDLogError("Error parsing the experiment response: \(error)")
                                        completion(nil)
                                    }
        }, failure: { error, _ in
            completion(nil)
        })
    }
}

extension ExPlatService {
    class func withDefaultApi() -> ExPlatService {
        let accountService = AccountService(managedObjectContext: ContextManager.shared.mainContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        let api = WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
        return ExPlatService(wordPressComRestApi: api)
    }
}
