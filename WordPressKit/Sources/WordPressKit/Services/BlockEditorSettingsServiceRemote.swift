import Foundation

public class BlockEditorSettingsServiceRemote {
    let remoteAPI: WordPressOrgRestApi
    public init(remoteAPI: WordPressOrgRestApi) {
        self.remoteAPI = remoteAPI
    }
}

// MARK: Editor `theme_supports` support
public extension BlockEditorSettingsServiceRemote {
    typealias EditorThemeCompletionHandler = (Swift.Result<RemoteEditorTheme?, Error>) -> Void

    func fetchTheme(completion: @escaping EditorThemeCompletionHandler) {
        let requestPath = "/wp/v2/themes"
        let parameters = ["status": "active"]
        Task { @MainActor in
            let result = await self.remoteAPI.get(path: requestPath, parameters: parameters, type: [RemoteEditorTheme].self)
                .map { $0.first }
                .mapError { error -> Error in error }
            completion(result)
        }
    }

}

// MARK: Editor Global Styles support
public extension BlockEditorSettingsServiceRemote {
    typealias BlockEditorSettingsCompletionHandler = (Swift.Result<RemoteBlockEditorSettings?, Error>) -> Void

    func fetchBlockEditorSettings(completion: @escaping BlockEditorSettingsCompletionHandler) {
        Task { @MainActor in
            let result = await self.remoteAPI.get(path: "/wp-block-editor/v1/settings", parameters: ["context": "mobile"], type: RemoteBlockEditorSettings.self)
                .map { settings -> RemoteBlockEditorSettings? in settings }
                .flatMapError { original in
                    if case let .unparsableResponse(response, _, underlyingError) = original, response?.statusCode == 200, underlyingError is DecodingError {
                        return .success(nil)
                    }
                    return .failure(original)
                }
                .mapError { error -> Error in error }
            completion(result)
        }
    }
}
