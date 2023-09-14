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

/**
 * Prepares the DocsBot for presentation by altering its appearance and behavior.
 */
window.prepareDocsBotForPresentation = function () {
  var chatBotSelector = "#docsbotai-root";
  var sendButtonSelector = ".docsbot-chat-btn-send";

  // Begin observation once chat bot is mounted
  onElementMounted(chatBotSelector, document, function (element) {
    waitForShadowRoot(element, function (shadowRoot) {
      resetDocsBotConversation();
      openDocsBot();

      // Inject a custom css to hide unnecessary elements
      var linkElem = document.createElement("link");
      linkElem.setAttribute("rel", "stylesheet");
      linkElem.setAttribute("href", "support_chat_widget.css");
      shadowRoot.appendChild(linkElem);

      // Hide keyboard after sending the message to reveal the whole content
      // https://github.com/wordpress-mobile/WordPress-iOS/issues/21549
      onElementMounted(sendButtonSelector, shadowRoot, function (sendButton) {
        sendButton.addEventListener("click", function () {
          setTimeout(() => {
            document.activeElement.blur();
          }, 0);
        });
      });
    });
  });

  /**
   * Clears the DocsBot conversation history.
   */
  function resetDocsBotConversation() {
    localStorage.removeItem("docsbot_chat_history");
  }

  /**
   * Opens the DocsBot chat.
   */
  function openDocsBot() {
    DocsBotAI.open();
  }

  /**
   * Observes for an element's appearance in the DOM and triggers a callback once it's found.
   *
   * @param {string} selector - The CSS selector of the element to watch for.
   * @param {function} callback - Function to call when the element is found.
   * @param {HTMLElement} root - The root DOM element to begin the search from (default is 'document').
   */
  function onElementMounted(selector, root, callback) {
    var element = root.querySelector(selector);
    if (element) {
      callback(element);
      return;
    }

    var observer = new MutationObserver(function (mutations, observer) {
      var element = root.querySelector(selector);
      if (element) {
        callback(element);
        observer.disconnect();
      }
    });

    observer.observe(root, {
      childList: true,
      subtree: true,
    });
  }

  /**
   * Waits for an element to have its shadow root loaded and triggers a callback once it's ready.
   *
   * @param {HTMLElement} element - The element with a shadow root.
   * @param {function} callback - Function to call when the shadow root is loaded.
   */
  function waitForShadowRoot(element, callback) {
    var observer = new MutationObserver(function (mutations) {
      for (var i = 0; i < mutations.length; i++) {
        var mutation = mutations[i];
        if (mutation.type === "childList" && element.shadowRoot) {
          callback(element.shadowRoot);
          observer.disconnect();
          return;
        }
      }
    });

    observer.observe(element, { childList: true });
  }
};
