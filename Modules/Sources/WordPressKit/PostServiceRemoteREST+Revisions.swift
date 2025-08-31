import Foundation

public extension PostServiceRemoteREST {
    func getPostRevisions(for siteId: Int,
                                 postId: Int,
                                 success: @escaping ([RemoteRevision]?) -> Void,
                                 failure: @escaping (Error?) -> Void) {
        let endpoint = "sites/\(siteId)/post/\(postId)/diffs"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        wordPressComRESTAPI.get(path,
                                parameters: nil,
                                success: { (response, _) in
                                    do {
                                        let data = try JSONSerialization.data(withJSONObject: response, options: [])
                                        self.map(from: data) { (revisions, error) in
                                            if let error = error {
                                                failure(error)
                                            } else {
                                                success(revisions)
                                            }
                                        }
                                    } catch {
                                        failure(error)
                                    }
        }, failure: { error, _ in
            WPKitLogError("\(error)")
            failure(error)
        })
    }

    func getPostLatestRevisionID(for postId: NSNumber, success: @escaping (NSNumber?) -> Void, failure: @escaping (Error?) -> Void) {
        let endpoint = "sites/\(siteID)/posts/\(postId)"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        wordPressComRESTAPI.get(
            path,
            parameters: [
                "context": "edit",
                "fields": "revisions"
            ] as [String: AnyObject],
            success: { (response, _) in
                let latestRevision: NSNumber?
                if let json = response as? [String: Any],
                   let revisions = json["revisions"] as? NSArray,
                   let latest = revisions.firstObject as? NSNumber {
                    latestRevision = latest
                } else {
                    latestRevision = nil
                }
                success(latestRevision)
            },
            failure: { error, _ in
                WPKitLogError("\(error)")
                failure(error)
            }
        )
    }
}

private extension PostServiceRemoteREST {
    private typealias JSONRevision = [String: Any]

    private struct RemoteDiffs: Codable {
        var diffs: [RemoteDiff]
    }

    private func map(from data: Data, _ completion: @escaping ([RemoteRevision]?, Error?) -> Void) {
        do {
            var revisions: [RemoteRevision] = []

            let diffs: RemoteDiffs = try decode(data)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? JSONRevision
            let revisionsDict = jsonResult?["revisions"] as? [String: JSONRevision]

            try revisionsDict?.forEach { (key: String, value: JSONRevision) in
                let revisionData = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
                var revision: RemoteRevision = try decode(revisionData)
                revision.diff = diffs.diffs.first { $0.toRevisionId == Int(key) }
                revisions.append(revision)
            }
            completion(revisions, nil)
        } catch {
            WPKitLogError("\(error)")
            completion(nil, error)
        }
    }

    private func decode<T: Codable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
