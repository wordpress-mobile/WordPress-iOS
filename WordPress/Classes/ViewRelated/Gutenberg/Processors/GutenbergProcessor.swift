import Foundation

public protocol GutenbergProcessor {
    func process(_ blocks: [GutenbergParsedBlock])
}
