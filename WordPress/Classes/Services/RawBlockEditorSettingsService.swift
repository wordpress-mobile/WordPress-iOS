import Foundation
import WordPressKit
import WordPressShared

class RawBlockEditorSettingsService {
    typealias CompletionHandler = (Result<[String: Any], Error>) -> Void

    private let blog: Blog
    private let remoteAPI: WordPressOrgRestApi

    init?(blog: Blog) {
        guard let remoteAPI = WordPressOrgRestApi(blog: blog) else {
            return nil
        }

        self.blog = blog
        self.remoteAPI = remoteAPI
    }

    func fetchSettings(completion: @escaping CompletionHandler) {
        Task { @MainActor in
            do {
                let result = await self.remoteAPI.get(path: "/wp-block-editor/v1/settings")
                switch result {
                case .success(let response):
                    guard let dictionary = response as? [String: Any] else {
                        completion(.failure(NSError(domain: "RawBlockEditorSettingsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                        return
                    }
                    completion(.success(dictionary))
                case .failure(let error):
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    @MainActor
    func fetchSettings() async throws -> [String: Any] {
        let result = await self.remoteAPI.get(path: "/wp-block-editor/v1/settings", parameters: ["context": "mobile"])
        switch result {
        case .success(let response):
            guard let dictionary = response as? [String: Any] else {
                throw NSError(domain: "RawBlockEditorSettingsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            return dictionary
        case .failure(let error):
            throw error
        }
    }
}
