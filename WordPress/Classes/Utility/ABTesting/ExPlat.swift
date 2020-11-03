import Foundation

class ExPlat: ABTesting {
    let wordPressComRestApi: WordPressComRestApi

    init(wordPressComRestApi: WordPressComRestApi) {
        self.wordPressComRestApi = wordPressComRestApi
    }

    func refresh() {
        let assignmentsPath = "wpcom/v2/experiments/0.1.0/assignments/calypso"

        wordPressComRestApi.GET(assignmentsPath,
                                parameters: nil,
                                success: { responseObject, httpResponse in
                                    do {
                                        let decoder = JSONDecoder()
                                        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])
                                        let assignments = try decoder.decode(Assignments.self, from: data)
                                        UserDefaults.standard.setValue(assignments.variations, forKey: "explat")
                                    } catch {
                                        DDLogError("Error parsing the experiment response: \(error)")
                                    }
        }, failure: { error, _ in

        })
    }
}

extension ExPlat {
    class func withDefaultApi() -> ExPlat {
        let accountService = AccountService(managedObjectContext: ContextManager.shared.mainContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        let api = WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
        return ExPlat(wordPressComRestApi: api)
    }
}
