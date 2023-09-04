import Foundation

struct LockScreenMultiStatViewModel {
    struct Field {
        let title: String
        let value: Int
    }

    let siteName: String
    let updatedTime: Date
    let firstField: Field
    let secondaryField: Field
}
