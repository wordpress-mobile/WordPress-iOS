import Foundation
import WordPressShared

open class JetpackBackupServiceRemote: ServiceRemoteWordPressComREST {

    /// Prepare a downloadable backup snapshot for a site.
    ///
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - rewindID: The rewindID of the snapshot to download.
    ///     - types: The types of items to restore.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: A backup snapshot object.
    ///
    open func prepareBackup(_ siteID: Int,
                            rewindID: String? = nil,
                            types: JetpackRestoreTypes? = nil,
                            success: @escaping (_ backup: JetpackBackup) -> Void,
                            failure: @escaping (Error) -> Void) {
        let path = backupPath(for: siteID)
        var parameters: [String: AnyObject] = [:]

        if let rewindID = rewindID {
            parameters["rewindId"] = rewindID as AnyObject
        }
        if let types = types {
            parameters["types"] = types.toDictionary() as AnyObject
        }

        wordPressComRestApi.POST(path, parameters: parameters, success: { response, _ in
            do {
                let decoder = JSONDecoder.apiDecoder
                let data = try JSONSerialization.data(withJSONObject: response, options: [])
                let envelope = try decoder.decode(JetpackBackup.self, from: data)
                success(envelope)
            } catch {
                failure(error)
            }
        }, failure: { error, _ in
            failure(error)
        })
    }

    /// Get the backup download status for a site and downloadID.
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - downloadID: The download ID of the snapshot being downloaded.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: A backup snapshot object.
    ///
    open func getBackupStatus(_ siteID: Int,
                              downloadID: Int,
                              success: @escaping (_ backup: JetpackBackup) -> Void,
                              failure: @escaping (Error) -> Void) {
        getDownloadStatus(siteID, downloadID: downloadID, success: success, failure: failure)
    }

    /// Get the backup status for all the backups in a site.
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: A backup snapshot object.
    ///
    open func getAllBackupStatus(_ siteID: Int,
                              success: @escaping (_ backup: [JetpackBackup]) -> Void,
                              failure: @escaping (Error) -> Void) {
        getDownloadStatus(siteID, success: success, failure: failure)
    }

    /// Mark a backup as dismissed
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - downloadID: The download ID of the snapshot being downloaded.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on error.
    ///
    open func markAsDismissed(_ siteID: Int,
                              downloadID: Int,
                              success: @escaping () -> Void,
                              failure: @escaping (Error) -> Void) {
        let path = backupPath(for: siteID, with: "\(downloadID)")

        let parameters = ["dismissed": true] as [String: AnyObject]

        wordPressComRestApi.POST(path, parameters: parameters, success: { _, _ in
            success()
        }, failure: { error, _ in
            failure(error)
        })
    }

    // MARK: - Private

    private func getDownloadStatus<T: Decodable>(_ siteID: Int,
                              downloadID: Int? = nil,
                              success: @escaping (_ backup: T) -> Void,
                              failure: @escaping (Error) -> Void) {

        let path: String
        if let downloadID = downloadID {
            path = backupPath(for: siteID, with: "\(downloadID)")
        } else {
            path = backupPath(for: siteID)
        }

        wordPressComRestApi.GET(path, parameters: nil, success: { response, _ in
            do {
                let decoder = JSONDecoder.apiDecoder
                let data = try JSONSerialization.data(withJSONObject: response, options: [])
                let envelope = try decoder.decode(T.self, from: data)
                success(envelope)
            } catch {
                failure(error)
            }
        }, failure: { error, _ in
            failure(error)
        })
    }

    private func backupPath(for siteID: Int, with path: String? = nil) -> String {
        var endpoint = "sites/\(siteID)/rewind/downloads/"

        if let path = path {
            endpoint = endpoint.appending(path)
        }

        return self.path(forEndpoint: endpoint, withVersion: ._2_0)
    }

}
