import WebKit

private struct File {
    enum FileError: Error {
        case sourceFileNotFound(String)
    }

    enum Extension: String {
        case css
        case js
    }
    private let name: String
    private let type: Extension

    func getContent() throws -> String {
        guard let path = Bundle.main.path(forResource: name, ofType: type.rawValue) else {
            throw FileError.sourceFileNotFound("\(name).\(type)")
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }
}

extension File {
    static let editorStyle = File(name: "GutenbergWebStyle", type: .css)
    static let wpBarsStyle = File(name: "WPBarsStyle", type: .css)
    static let injectCss = File(name: "InjectCss", type: .js)
    static let retrieveHtml = File(name: "RetrieveHTMLContent", type: .js)
    static let insertBlock = File(name: "InsertBlock", type: .js)
}

struct GutenbergWebJavascriptInjection {
    enum JSMessage: String, CaseIterable {
        case htmlPostContent
        case log
    }

    private let userContentScripts: [WKUserScript]

    let injectWPBarsCssScript: WKUserScript
    let injectEditorCssScript: WKUserScript
    let injectCssScript: WKUserScript
    let getHtmlContentScript = WKUserScript(source: "window.getHTMLPostContent()", injectionTime: .atDocumentEnd, forMainFrameOnly: false)


    /// Init an instance of GutenbergWebJavascriptInjection or throws if any of the required sources doesn't exist.
    /// This helps to cach early any possible error due to missing source files.
    /// - Parameter blockHTML: The block HTML code to be injected.
    /// - Throws: Throws an error if any required source doesn't exist.
    init(blockHTML: String) throws {
        func script(with source: File, argument: String? = nil) throws -> WKUserScript {
            let finalSource = String(format: try source.getContent(), argument ?? [])
            return WKUserScript(source: finalSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        }

        func getInjectCssScript(with source: File) throws -> WKUserScript {
            let css = try source.getContent()
            return WKUserScript(source: "window.injectCss(`\(css)`)", injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        }

        userContentScripts = [
            try script(with: .retrieveHtml),
            try script(with: .insertBlock, argument: blockHTML),
        ]

        injectCssScript = try script(with: .injectCss)
        injectWPBarsCssScript = try getInjectCssScript(with: .wpBarsStyle)
        injectEditorCssScript = try getInjectCssScript(with: .editorStyle)
    }

    func userContent(messageHandler handler: WKScriptMessageHandler, blockHTML: String) -> WKUserContentController {
        let userContent = WKUserContentController()
        userContent.addUserScripts(userContentScripts)
        JSMessage.allCases.forEach {
            userContent.add(handler, name: $0.rawValue)
        }
        return userContent
    }
}

private extension WKUserContentController {
    func addUserScripts(_ scripts: [WKUserScript]) {
        scripts.forEach {
            addUserScript($0)
        }
    }
}
