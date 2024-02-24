// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import FileSaver from "../vendor/file-saver";

let Hooks = {};

function genId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

Hooks.AssignUserId = {
  mounted() {
    let userId = localStorage.getItem("userId");
    if (!userId) {
      userId = genId(); // replace this with your user id generation logic
      localStorage.setItem("userId", userId);
    }
    this.pushEvent("assign-user-id", { userId: userId });
  },
};

Hooks.DownloadImage = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      const link = this.el.getAttribute("phx-value-image");
      const name = this.el.getAttribute("phx-value-name");

      fetch(link)
        .then((response) => response.blob())
        .then((blob) => {
          FileSaver.saveAs(blob, `${name}.png`);
        });
    });
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

window.addEventListener("phx:copy", async (event) => {
  let button = event.detail.dispatcher;
  // Assuming you want to share the URL stored in a data attribute named 'data-url'
  let urlToShare =
    event.target.getAttribute("data-url") || event.target.dataset.url;

  // Check if the Web Share API is available
  if (navigator.share) {
    try {
      await navigator.share({
        title: "Check out my AI generated sticker", // Optional: Title of the content to share
        url: urlToShare, // The URL you want to share
      });
      console.log("Content shared successfully");
    } catch (error) {
      console.error("Error sharing content:", error);
    }
  } else {
    // Fallback for browsers that do not support the Web Share API
    // For example, copy the URL to clipboard
    navigator.clipboard.writeText(urlToShare).then(() => {
      button.innerText = "Link copied to clipboard!";
      setTimeout(() => {
        button.innerText = "Share";
      }, 2000);
    });
  }
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
