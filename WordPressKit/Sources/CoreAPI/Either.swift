import Foundation

enum Either<L, R> {
    case left(L)
    case right(R)

    func map<T>(left: (L) -> T, right: (R) -> T) -> T {
        switch self {
        case let .left(value):
            return left(value)
        case let .right(value):
            return right(value)
        }
    }
}
