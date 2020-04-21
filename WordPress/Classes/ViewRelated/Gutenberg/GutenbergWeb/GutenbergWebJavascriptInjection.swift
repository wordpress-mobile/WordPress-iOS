import WebKit

private extension WKUserContentController {
    func addUserScripts(_ scripts: [WKUserScript]) {
        scripts.forEach {
            addUserScript($0)
        }
    }
}

struct GutenbergWebJavascriptInjection {
    enum JSMessage: String, CaseIterable {
        case htmlPostContent
        case log
    }

    func userContent(messageHandler handler: WKScriptMessageHandler, blockHTML: String) -> WKUserContentController {
        let userContent = WKUserContentController()
        userContent.addUserScripts([
            WKUserScript(source: incertBlockScript(blockHTML: blockHTML), injectionTime: .atDocumentEnd, forMainFrameOnly: false),
            WKUserScript(source: mutationObserverScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
            WKUserScript(source: retriveContentHTMLScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
        ])
        JSMessage.allCases.forEach {
            userContent.add(handler, name: $0.rawValue)
        }
        return userContent
    }

    private let retriveContentHTMLScript = """
window.getHTMLPostContent = () => {
    const blocks = window.wp.data.select('core/block-editor').getBlocks();
    const HTML = window.wp.blocks.serialize( blocks );
    window.webkit.messageHandlers.htmlPostContent.postMessage(HTML);
}
"""

    private func incertBlockScript(blockHTML: String) -> String { return """
window.insertBlock = () => {
    window.setTimeout(() => {
        window.webkit.messageHandlers.log.postMessage("HEADER READY!!");
        const blockHTML = `\(blockHTML)`;
        let blocks = window.wp.blocks.parse(blockHTML);
        window.wp.data.dispatch('core/block-editor').resetBlocks(blocks);
    }, 0);
};
"""
    }

    /// Script that observe DOM mutations and calls `insertBlock` when it's appropiate.
    private let mutationObserverScript = """
window.onload = () => {
    const content = document.getElementById('wpbody-content');
    if (content) {
        window.insertBlock();
        const callback = function(mutationsList, observer) {
            window.webkit.messageHandlers.log.postMessage("UPDATED!");
            const header = document.getElementsByClassName("edit-post-header")[0];
            if (header) {
                window.insertBlock();
                observer.disconnect();
            }
        };
        const observer = new MutationObserver(callback);
        const config = { attributes: true, childList: true, subtree: true };
        observer.observe(content, config);
    }
}
"""

    let getHTMLPostContentScript = "window.getHTMLPostContent()"

    let insertCSSScript: String = {
            let css = """
    #wp-toolbar {
        display: none;
    }

    #wpadminbar {
        display: none;
    }

    #post-title-0 {
        display: none;
    }

    .block-list-appender {
        display: none;
    }

    .edit-post-header {
        height: 0px;
        overflow: hidden;
    }

    .edit-post-header-toolbar__block-toolbar {
        top: 0px;
    }

    .block-editor-editor-skeleton {
        top: 0px;
    }

    .edit-post-layout__metaboxes {
        display: none;
    }
    """

            return """
    const style = document.createElement('style');
    style.innerHTML = `\(css)`;
    style.type = 'text/css';
    document.head.appendChild(style);
    "CSS Injected"
    """
        }()
}
