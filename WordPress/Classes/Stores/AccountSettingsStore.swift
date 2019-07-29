import WordPressFlux

enum AccountSettingsAction: Action {
    case validate(username: String)
    case saveUsername(username: String)
}

class AccountSettingsStore {
}
