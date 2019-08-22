import Foundation

extension UUID {
    static func extract(from content: String) -> [UUID] {
        let nsContent = content as NSString
        let results = content.matches(regex: "[0-9a-fA-F]{8}\\-[0-9a-fA-F]{4}\\-[0-9a-fA-F]{4}\\-[0-9a-fA-F]{4}\\-[0-9a-fA-F]{12}")
        
        return results.compactMap { result in
            if result.range(at: 0).location != NSNotFound,
                let uuid = UUID(uuidString: nsContent.substring(with: result.range(at: 0))) {
                return uuid
            }
            
            return nil
        }
    }
}
