import AFNetworking
import Foundation
import RxSwift

class AccountSettingsRemote: ServiceRemoteREST {
    func settings() -> Observable<AccountSettings> {
        let api = self.api

        return Observable.create { observer in
            let remote = AccountSettingsRemote(api: api)
            let operation = remote.getSettings(
                success: { settings in
                    observer.onNext(settings)
                    observer.onCompleted()
                }, failure: { error in
                    DDLogSwift.logError("Error refreshing settings: \(error)")
                    observer.onError(error)
            })
            return AnonymousDisposable() {
                if let operation = operation {
                    if !operation.finished {
                        DDLogSwift.logError("Canceled refreshing settings")
                        operation.cancel()
                    }
                }
            }
        }
    }

    func getSettings(success success: AccountSettings -> Void, failure: ErrorType -> Void) -> AFHTTPRequestOperation? {
        let endpoint = "me/settings"
        let parameters = ["context": "edit"]
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        return api.GET(path,
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
            primarySiteID = response["primary_site_ID"] as? Int,
            webAddress = response["user_URL"] as? String,
            language = response["language"] as? String else {
                DDLogSwift.logError("Error decoding me/settings response: \(responseObject)")
                throw Error.DecodeError
        }

        let aboutMeText = aboutMe.stringByDecodingXMLCharacters()

        return AccountSettings(firstName: firstName, lastName: lastName, displayName: displayName, aboutMe: aboutMeText, username: username, email: email, primarySiteID: primarySiteID, webAddress: webAddress, language: language)
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
            return "email"
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