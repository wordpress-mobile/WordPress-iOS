window.onerror = function (msg, url, line, column, error) {
  let message = {
    message: msg,
    url: url,
    line: line,
    column: column,
    error: JSON.stringify(error),
  };

  if (window.webkit) {
    window.webkit.messageHandlers.errorCallback.postMessage(message);
  } else {
    console.log("Error:", message);
  }
};
