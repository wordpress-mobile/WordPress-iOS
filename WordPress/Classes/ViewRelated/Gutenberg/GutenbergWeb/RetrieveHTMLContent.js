window.getHTMLPostContent = () => {
    const blocks = window.wp.data.select('core/block-editor').getBlocks();
    const HTML = window.wp.blocks.serialize( blocks );
    window.webkit.messageHandlers.htmlPostContent.postMessage(HTML);
};

// Prevent posting autosaves to remote
(function(open) {
  XMLHttpRequest.prototype.open = function(arg1, arg2) {
    this.URL = arg2;
    this.method = arg1;
    open.apply(this, arguments);
  };
})(XMLHttpRequest.prototype.open);

(function(send) {
  XMLHttpRequest.prototype.send = function(arg1) {
    if (this.URL.includes('/autosaves') && this.method === "POST") {
      this.abort();
      return;
    }
    send.apply(this, arguments);
  };
})(XMLHttpRequest.prototype.send);
