import Foundation

struct AllDomainsListEmptyStateViewModel {

    let title: String
    let description: String
    let button: Button

    struct Button {
        let title: String
        let action: () -> Void
    }
}
