window.setTimeout(() => {
    const blockHTML = `%@`;
    let blocks = window.wp.blocks.parse(blockHTML);
    window.wp.data.dispatch('core/block-editor').resetBlocks(blocks);
    window.wp.data.dispatch( 'core/block-editor' ).selectBlock( blocks[0].clientId );
    window.webkit.messageHandlers.log.postMessage("Block inserted");
}, 0);
