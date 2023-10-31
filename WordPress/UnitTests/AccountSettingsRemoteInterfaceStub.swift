@testable import WordPress
import WordPressKit

class AccountSettingsRemoteInterfaceStub: AccountSettingsRemoteInterface {

    let updateSettingResult: Result<(), Error>
    let getSettingsResult: Result<AccountSettings, Error>
    let changeUsernameShouldSucceed: Bool
    let suggestUsernamesResult: [String]
    let updatePasswordResult: Result<(), Error>
    let closeAccountResult: Result<(), Error>

    init(
        updateSettingResult: Result<Void, Error> = .success(()),
        // Defaulting to failure to avoid having to create AccountSettings here, because it required an NSManagedContext
        getSettingsResult: Result<AccountSettings, Error> = .failure(testError()),
        changeUsernameShouldSucceed: Bool = true,
        suggestUsernamesResult: [String] = [],
        updatePasswordResult: Result<Void, Error> = .success(()),
        closeAccountResult: Result<Void, Error> = .success(())
    ) {
        self.updateSettingResult = updateSettingResult
        self.getSettingsResult = getSettingsResult
        self.changeUsernameShouldSucceed = changeUsernameShouldSucceed
        self.suggestUsernamesResult = suggestUsernamesResult
        self.updatePasswordResult = updatePasswordResult
        self.closeAccountResult = closeAccountResult
    }

    func updateSetting(_ change: AccountSettingsChange, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        switch updateSettingResult {
        case .success:
            success()
        case .failure(let error):
            failure(error)
        }
    }

    func getSettings(success: @escaping (WordPressKit.AccountSettings) -> Void, failure: @escaping (Error) -> Void) {
        switch getSettingsResult {
        case .success(let settings):
            success(settings)
        case .failure(let error):
            failure(error)
        }
    }

    func changeUsername(to username: String, success: @escaping () -> Void, failure: @escaping () -> Void) {
        if changeUsernameShouldSucceed {
            success()
        } else {
            failure()
        }
    }

    func suggestUsernames(base: String, finished: @escaping ([String]) -> Void) {
        finished(suggestUsernamesResult)
    }

    func updatePassword(_ password: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        switch updatePasswordResult {
        case .success:
            success()
        case .failure(let error):
            failure(error)
        }
    }

    func closeAccount(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        switch closeAccountResult {
        case .success:
            success()
        case .failure(let error):
            failure(error)
        }
    }
}
