Shiny.addCustomMessageHandler("set-disabled", function (msg) {
  document.getElementById(msg.id).disabled = msg.disabled;
});
