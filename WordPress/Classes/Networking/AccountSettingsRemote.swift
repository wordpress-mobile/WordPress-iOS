import AFNetworking
import Foundation

class AccountSettingsRemote: ServiceRemoteREST {
    static let remotes = NSMapTable(keyOptions: .StrongMemory, valueOptions: .WeakMemory)

    /// Returns an AccountSettingsRemote with the given api, reusing a previous
    /// remote if it exists.
    static func remoteWithApi(api: WordPressComApi) -> AccountSettingsRemote {
        // We're hashing on the authToken because we don't want duplicate api
        // objects for the same account.
        //
        // In theory this would be taken care of by the fact that the api comes
        // from a WPAccount, and since WPAccount is a managed object Core Data
        // guarantees there's only one of it.
        //
        // However it might be possible that the account gets deallocated and
        // when it's fetched again it would create a different api object.
        let key = api.authToken.hashValue
        // FIXME: not thread safe
        // @koke 2016-01-21
        if let remote = remotes.objectForKey(key) {
            return remote as! AccountSettingsRemote
        } else {
            let remote = AccountSettingsRemote(api: api)
            remotes.setObject(remote, forKey: key)
            return remote
        }
    }

    func getSettings(success success: AccountSettings -> Void, failure: ErrorType -> Void) {
        let endpoint = "me/settings"
        let parameters = ["context": "edit"]
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
                parameters: parameters,
                success: {
                    operation, responseObject in

                    do {
                        let settings = try self.settingsFromResponse(responseObject)
                        success(settings)
                    } catch {
                        failure(error)
                    }
            },
                failure: { operation, error in
                    failure(error)
        })
    }

    func updateSetting(change: AccountSettingsChange, success: () -> Void, failure: ErrorType -> Void) {
        let endpoint = "me/settings"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
        let parameters = [fieldNameForChange(change): change.stringValue]

        api.POST(path,
            parameters: parameters,
            success: {
                operation, responseObject in

                success()
            },
            failure: { operation, error in
                failure(error)
        })
    }

    private func settingsFromResponse(responseObject: AnyObject) throws -> AccountSettings {
        guard let
            response = responseObject as? [String: AnyObject],
            firstName = response["first_name"] as? String,
            lastName = response["last_name"] as? String,
            displayName = response["display_name"] as? String,
            aboutMe = response["description"] as? String,
            username = response["user_login"] as? String,
            email = response["user_email"] as? String,
            emailPendingAddress = response["new_user_email"] as? String?,
            emailPendingChange = response["user_email_change_pending"] as? Bool,
            primarySiteID = response["primary_site_ID"] as? Int,
            webAddress = response["user_URL"] as? String,
            language = response["language"] as? String else {
                DDLogSwift.logError("Error decoding me/settings response: \(responseObject)")
                throw Error.DecodeError
        }

        let aboutMeText = aboutMe.stringByDecodingXMLCharacters()

        return AccountSettings(firstName: firstName,
                               lastName: lastName,
                               displayName: displayName,
                               aboutMe: aboutMeText,
                               username: username,
                               email: email,
                               emailPendingAddress: emailPendingAddress,
                               emailPendingChange: emailPendingChange,
                               primarySiteID: primarySiteID,
                               webAddress: webAddress,
                               language: language)
    }

    private func fieldNameForChange(change: AccountSettingsChange) -> String {
        switch change {
        case .FirstName(_):
            return "first_name"
        case .LastName(_):
            return "last_name"
        case .DisplayName(_):
            return "display_name"
        case .AboutMe(_):
            return "description"
        case .Email(_):
            return "user_email"
        case .EmailRevertPendingChange(_):
            return "user_email_change_pending"
        case .PrimarySite(_):
            return "primary_site_ID"
        case .WebAddress(_):
            return "user_URL"
        case .Language(_):
            return "language"
        }
    }

    enum Error: ErrorType {
        case DecodeError
    }
}
