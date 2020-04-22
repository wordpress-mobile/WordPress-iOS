window.insertBlock = () => {
    window.setTimeout(() => {
        const blockHTML = `%@`;
        let blocks = window.wp.blocks.parse(blockHTML);
        window.wp.data.dispatch('core/block-editor').resetBlocks(blocks);
        window.webkit.messageHandlers.log.postMessage("Block incerted");
    }, 0);
};

window.onload = () => {
    const content = document.getElementById('wpbody-content');
    if (content) {
        window.insertBlock();
        const callback = function(mutationsList, observer) {
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
