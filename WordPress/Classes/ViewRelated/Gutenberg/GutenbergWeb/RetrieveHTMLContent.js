window.getHTMLPostContent = () => {
    const blocks = window.wp.data.select('core/block-editor').getBlocks();
    const HTML = window.wp.blocks.serialize( blocks );
    window.webkit.messageHandlers.htmlPostContent.postMessage(HTML);
};
