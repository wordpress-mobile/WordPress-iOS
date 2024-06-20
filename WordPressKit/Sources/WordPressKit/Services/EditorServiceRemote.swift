import Foundation
import WordPressShared

public class EditorServiceRemote: ServiceRemoteWordPressComREST {
    public func postDesignateMobileEditor(_ siteID: Int, editor: EditorSettings.Mobile, success: @escaping (EditorSettings) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/gutenberg?platform=mobile&editor=\(editor.rawValue)"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        wordPressComRESTAPI.post(path, parameters: nil, success: { (responseObject, _) in
            do {
                let settings = try EditorSettings(with: responseObject)
                success(settings)
            } catch {
                failure(error)
            }
        }) { (error, _) in
            failure(error)
        }
    }

    public func postDesignateMobileEditorForAllSites(_ editor: EditorSettings.Mobile, setOnlyIfEmpty: Bool = true, success: @escaping ([Int: EditorSettings.Mobile]) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "me/gutenberg"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        let parameters = [
            "platform": "mobile",
            "editor": editor.rawValue,
            "set_only_if_empty": setOnlyIfEmpty
        ] as [String: AnyObject]

        wordPressComRESTAPI.post(path, parameters: parameters, success: { (responseObject, _) in
            guard let response = responseObject as? [String: String] else {
                if let boolResponse = responseObject as? Bool, boolResponse == false {
                    return failure(EditorSettings.Error.badRequest)
                }
                return failure(EditorSettings.Error.badResponse)
            }

            let mappedResponse = response.reduce(into: [Int: EditorSettings.Mobile](), { (result, response) in
                if let id = Int(response.key), let editor = EditorSettings.Mobile(rawValue: response.value) {
                    result[id] = editor
                }
            })
            success(mappedResponse)
        }) { (error, _) in
            failure(error)
        }
    }

    public func getEditorSettings(_ siteID: Int, success: @escaping (EditorSettings) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/gutenberg"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        wordPressComRESTAPI.get(path, parameters: nil, success: { (responseObject, _) in
            do {
                let settings = try EditorSettings(with: responseObject)
                success(settings)
            } catch {
                failure(error)
            }
        }) { (error, _) in
            failure(error)
        }
    }
}
