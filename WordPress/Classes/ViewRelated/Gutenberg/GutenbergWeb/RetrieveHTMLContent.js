window.getHTMLPostContent = () => {
    const blocks = window.wp.data.select('core/block-editor').getBlocks();
    const HTML = window.wp.blocks.serialize( blocks );
    window.webkit.messageHandlers.htmlPostContent.postMessage(HTML);
};

(function(open) {
  XMLHttpRequest.prototype.open = function(arg1, arg2) {
    this.URL = arg2;
    this.method = arg1;
    open.apply(this, arguments);
  };
})(XMLHttpRequest.prototype.open);

(function(send) {
  XMLHttpRequest.prototype.send = function(arg1) {
      window.webkit.messageHandlers.log.postMessage(String(this.method + ': ' + this.URL));
    if (this.URL.includes('/autosaves') && this.method === "POST") {
      window.webkit.messageHandlers.log.postMessage("Prevented autosave");
      this.abort();
      return;
    }
    send.apply(this, arguments);
  };
})(XMLHttpRequest.prototype.send);
