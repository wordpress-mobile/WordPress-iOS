@objc public class ActivityServiceRemote_ApiVersion1_0: ServiceRemoteWordPressComREST {

    public enum ResponseError: Error {
        case decodingFailure
    }

    /// Makes a request to Restore a site to a previous state.
    ///
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - rewindID: The rewindID to restore to.
    ///     - types: The types of items to restore.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: A restoreID and jobID to check the status of the rewind request.
    ///
    public func restoreSite(_ siteID: Int,
                            rewindID: String,
                            types: JetpackRestoreTypes? = nil,
                            success: @escaping (_ restoreID: String, _ jobID: Int) -> Void,
                            failure: @escaping (Error) -> Void) {
        let endpoint = "activity-log/\(siteID)/rewind/to/\(rewindID)"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_0)
        var parameters: [String: AnyObject] = [:]

        if let types = types {
            parameters["types"] = types.toDictionary() as AnyObject
        }

        wordPressComRestApi.POST(path,
                                 parameters: parameters,
                                 success: { response, _ in
                                    guard let restoreID = response["restore_id"] as? Int,
                                          let jobID = response["job_id"] as? Int else {
                                        failure(ResponseError.decodingFailure)
                                        return
                                    }
                                    success(String(restoreID), jobID)
        },
                                 failure: { error, _ in
                                    failure(error)
        })
    }
}
