import Foundation
import Aztec


// MARK: - ParagraphProcessor
//
class ParagraphProcessor: Processor {
    func process(text: String) -> String {

        let paragraphs = text.components(separatedBy: "\n\n")
        let output = paragraphs.reduce("") { (result, paragraph) in
            return result + "<p>" + paragraph + "</p>"
        }

        return output.replacingOccurrences(of: "\n", with: "<br>")
    }
}
