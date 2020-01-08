import AutomatticTracks
import WebKit

/// This extension contains a hack used to make it possible to
/// evaluate JavaScript code synchronously.
///
extension WKWebView {

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

        while (!finished) {
            RunLoop.current.run(mode: .default, before: NSDate.distantFuture)
        }

        return result
    }
    /*
    - (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script; {
        __block NSString *resultString = nil;
        __block BOOL finished = NO;

        [self evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
            if (error == nil) {
                if (result != nil) {
                    resultString = [NSString stringWithFormat:@"%@", result];
                }
            } else {
                NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);
            }
            
            finished = YES;
        }];

        while (!finished)
        {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }

        return resultString;
    }*/
}
