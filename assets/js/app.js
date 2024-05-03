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
import Hammer from "../vendor/hammer.js";

let Hooks = {};

function genId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

Hooks.AssignUserId = {
  mounted() {
    let userId = localStorage.getItem("userId");
    if (!userId) {
      userId = genId();
      localStorage.setItem("userId", userId);
    }
    this.pushEvent("assign-user-id", { userId: userId });
    fetch(`/api/session?local_user_id=${encodeURIComponent(userId)}`, {
      method: "post",
    });
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

Hooks.Tinder = {
  mounted() {
    var tinderContainer = document.querySelector(".tinder");
    var allCards = document.querySelectorAll(".tinder--card");
    var nope = document.getElementById("nope");
    var love = document.getElementById("love");
    var nopeButton = document.getElementById("nope");
    var loveButton = document.getElementById("love");
    const liveview = this;

    const addShakeAnimation = (button) => {
      console.log("adding shake animation to button", button);
      button.classList.add("animate-shake");
      // Remove the class after the animation duration (500ms)
      setTimeout(() => {
        button.classList.remove("animate-shake");
      }, 500);
    };

    document.addEventListener("keydown", function (event) {
      const nopeButton = document.getElementById("nope");
      const loveButton = document.getElementById("love");

      if (event.key === "ArrowLeft") {
        // Simulate a left swipe
        nopeButton.click();
      } else if (event.key === "ArrowRight") {
        // Simulate a right swipe
        loveButton.click();
      }
    });

    function initCards(card, index) {
      var newCards = document.querySelectorAll(".tinder--card:not(.removed)");

      newCards.forEach(function (card, index) {
        card.style.zIndex = allCards.length - index;
        card.style.transform =
          "scale(" + (20 - index) / 20 + ") translateY(-" + 30 * index + "px)";
        card.style.opacity = (10 - index) / 10;
      });

      tinderContainer.classList.add("loaded");
    }

    initCards();

    allCards.forEach(function (el) {
      var hammertime = new Hammer(el);

      hammertime.on("pan", function (event) {
        el.classList.add("moving");
      });

      hammertime.on("pan", function (event) {
        if (event.deltaX === 0) return;
        if (event.center.x === 0 && event.center.y === 0) return;

        tinderContainer.classList.toggle("tinder_love", event.deltaX > 0);
        tinderContainer.classList.toggle("tinder_nope", event.deltaX < 0);

        var xMulti = event.deltaX * 0.03;
        var yMulti = event.deltaY / 80;
        var rotate = xMulti * yMulti;

        event.target.style.transform =
          "translate(" +
          event.deltaX +
          "px, " +
          event.deltaY +
          "px) rotate(" +
          rotate +
          "deg)";
      });

      hammertime.on("panend", (event) => {
        el.classList.remove("moving");
        tinderContainer.classList.remove("tinder_love");
        tinderContainer.classList.remove("tinder_nope");

        var moveOutWidth = document.body.clientWidth;
        var keep =
          Math.abs(event.deltaX) < 80 || Math.abs(event.velocityX) < 0.5;

        event.target.classList.toggle("removed", !keep);

        if (keep) {
          event.target.style.transform = "";
        } else {
          var endX = Math.max(
            Math.abs(event.velocityX) * moveOutWidth,
            moveOutWidth
          );
          var toX = event.deltaX > 0 ? endX : -endX;
          var endY = Math.abs(event.velocityY) * moveOutWidth;
          var toY = event.deltaY > 0 ? endY : -endY;
          var xMulti = event.deltaX * 0.03;
          var yMulti = event.deltaY / 80;
          var rotate = xMulti * yMulti;

          event.target.style.transform =
            "translate(" +
            toX +
            "px, " +
            (toY + event.deltaY) +
            "px) rotate(" +
            rotate +
            "deg)";
          initCards();
        }
        var direction = event.deltaX > 0 ? "allow" : "disallow";

        var predictionData = event.target.getAttribute("data-prediction-id");
        console.log("Panned card prediction data:", predictionData);

        if (direction === "allow") {
          addShakeAnimation(loveButton);
        } else {
          addShakeAnimation(nopeButton);
        }

        liveview.pushEvent("swipe_prediction", {
          prediction: predictionData,
          action: direction,
        });
      });
    });

    function createButtonListener(love) {
      return function (event) {
        var cards = document.querySelectorAll(".tinder--card:not(.removed)");
        var moveOutWidth = document.body.clientWidth * 1.5;

        if (!cards.length) return false;

        var card = cards[0];

        // Retrieve the prediction data from the card
        var predictionData = card.getAttribute("data-prediction-id");
        console.log("Swiped prediction:", predictionData); // Log or handle the prediction data as needed

        card.classList.add("removed");
        if (love) {
          card.style.transform =
            "translate(" + moveOutWidth + "px, -100px) rotate(-30deg)";
          addShakeAnimation(loveButton);
        } else {
          card.style.transform =
            "translate(-" + moveOutWidth + "px, -100px) rotate(30deg)";
          console.log("swipe left!");
          addShakeAnimation(nopeButton);
        }

        initCards();

        // Push the event to the LiveView with the prediction data and the action
        liveview.pushEvent("swipe_prediction", {
          prediction: predictionData,
          action: love ? "allow" : "disallow",
        });

        event.preventDefault();
      };
    }

    var nopeListener = createButtonListener(false);
    var loveListener = createButtonListener(true);

    nope.addEventListener("click", nopeListener);
    love.addEventListener("click", loveListener);
  },
  destroyed() {
    if (this.hammer) {
      this.hammer.destroy();
      this.hammer = null;
    }
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
  let urlToShare = event.target.getAttribute("data-url");

  // Check if the Web Share API is available
  if (navigator.share) {
    try {
      await navigator.share({
        title: "Check out this AI sticker I made", // Optional: Title of the content to share
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
