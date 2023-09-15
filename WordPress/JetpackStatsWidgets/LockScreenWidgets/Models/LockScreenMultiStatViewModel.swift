import Foundation

struct LockScreenMultiStatViewModel {
    struct Field {
        let title: String
        let value: Int
    }

    let siteName: String
    let updatedTime: Date
    let primaryField: Field
    let secondaryField: Field
}
