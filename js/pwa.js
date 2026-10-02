if ("serviceWorker" in navigator)
  window.addEventListener("load", () =>
    navigator.serviceWorker.register("sw.js").catch(() => {}),
  );
let deferred;
window.addEventListener("beforeinstallprompt", (e) => {
  e.preventDefault();
  deferred = e;
  const b = document.createElement("button");
  b.className = "btn b1 install show";
  b.textContent = "Install app";
  b.onclick = async () => {
    b.remove();
    deferred.prompt();
    await deferred.userChoice;
    deferred = null;
  };
  document.body.appendChild(b);
});
window.addEventListener(
  "appinstalled",
  () =>
    document.querySelector(".install") &&
    document.querySelector(".install").remove(),
);
