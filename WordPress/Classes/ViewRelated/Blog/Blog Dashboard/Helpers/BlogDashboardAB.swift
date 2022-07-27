import Foundation

class BlogDashboardAB {
    static let shared = BlogDashboardAB()

    enum Variant {
        case control
        case treatment
    }

    public var variant: Variant {
        calculateVariant()
    }

    private init() {
    }

    private func calculateVariant() -> Variant {
        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        let token: String? = defaultAccount?.authToken

        if let token = token {
            return token.hashCode() % 2 == 0 ? .control : .treatment
        } else {
            return .control
        }
    }
}

private extension String {
    var asciiArray: [UInt32] {
        return unicodeScalars
            .filter { $0.isASCII }
            .map { $0.value }
    }

    func hashCode() -> Int32 {
        var h: Int32 = 0
        for i in self.asciiArray {
            h = 31 &* h &+ Int32(i)
        }
        return h
    }
}
