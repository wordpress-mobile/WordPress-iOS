import WordPressFlux

enum ThemeSupportStoreState {
    case empty
    case loading
    case loaded([AnyHashable])
    case error(Error)
}

class ThemeSupportStore: StatefulStore<ThemeSupportStoreState> {

}
