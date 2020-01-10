import AutomatticTracks
import WebKit

/// This extension contains a hack used to make it possible to
/// evaluate JavaScript code synchronously.
///
extension WKWebView {

    /// Synchronous evaluation of JavaScript in WKWebView.
    ///
    /// - Parameters:
    ///     - javascriptString: the JavaScript string to evaluate.
    ///
    /// - Returns: the result of the evaluation.
    ///
    @objc
    func stringByEvaluatingJavaScript(fromString javascriptString: String) -> String {
        var result = ""
        var finished = false

        evaluateJavaScript(javascriptString) { (output, error) in
            defer {
                finished = true
            }

            guard error == nil else {
                CrashLogging.logMessage(
                    "Failed to evaluate JavaScript",
                    properties: ["error": error!, "evaluatedString": javascriptString],
                    level: .error)
                return
            }

            guard let output = output as? String else {
                return
            }

            result = output
        }

        while !finished {
            RunLoop.current.run(mode: .default, before: .distantFuture)
        }

        return result
    }
}
