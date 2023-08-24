window.onerror = (msg, url, line, column, error) => {
  const message = {
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
