window.DocsBotAI = window.DocsBotAI || {};

DocsBotAI.init = function (c) {
  return new Promise(function (e, o) {
    var t = document.createElement("script");
    t.type = "text/javascript";
    t.async = true;
    t.src = "https://widget.docsbot.ai/chat.js";

    var n = document.getElementsByTagName("script")[0];
    n.parentNode.insertBefore(t, n);

    t.addEventListener("load", function () {
      window.DocsBotAI.mount({
        id: c.id,
        supportCallback: c.supportCallback,
        identify: c.identify,
        options: c.options,
      });

      function findElement(n) {
        return new Promise(function (e) {
          if (document.querySelector(n)) {
            return e(document.querySelector(n));
          }

          var o = new MutationObserver(function (t) {
            if (document.querySelector(n)) {
              e(document.querySelector(n));
              o.disconnect();
            }
          });
          o.observe(document.body, { childList: true, subtree: true });
        });
      }

      findElement("#docsbotai-root").then(e).catch(o);
    });

    t.addEventListener("error", function (t) {
      o(t.message);
    });
  });
};
