import Foundation

class AccountSettingsRemote: ServiceRemoteREST {
    func getSettings(success success: AccountSettings -> Void, failure: ErrorType -> Void) {
        let endpoint = "me/settings"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
            parameters: nil,
            success: {
                (operation, responseObject) -> Void in

                do {
                    let settings = try self.settingsFromResponse(responseObject)
                    success(settings)
                } catch {
                    failure(error)
                }
            },
            failure: { (operation, error) -> Void in
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
            primarySiteID = response["primary_site_ID"] as? Int,
            webAddress = response["user_URL"] as? String,
            language = response["language"] as? String else {
                DDLogSwift.logError("Error decoding me/settings response: \(responseObject)")
                throw Error.DecodeError
        }

        return AccountSettings(firstName: firstName, lastName: lastName, displayName: displayName, aboutMe: aboutMe, username: username, email: email, primarySiteID: primarySiteID, webAddress: webAddress, language: language)
    }

    enum Error: ErrorType {
        case DecodeError
    }
}