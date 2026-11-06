Shiny.addCustomMessageHandler("set-disabled", function (msg) {
  document.getElementById(msg.id).disabled = msg.disabled;
});

// Lets the same file be chosen again, which otherwise doesn't fire a change event
Shiny.addCustomMessageHandler("reset-file-input", function (msg) {
  const el = document.getElementById(msg.id);
  el.value = "";
  if (msg.clear) {
    const group = el.closest(".shiny-input-container");
    group.querySelector("input[type='text']").value = "";
    group.querySelector(".progress").style.visibility = "hidden";
  }
});
