// 1. Custom SHiny message handler for bookmarks
Shiny.addCustomMessageHandler("scrollTo", function(sectionId) {
  const el = document.getElementById(sectionId);
  if (el) {
    el.scrollIntoView({ behavior: "smooth", block: "start" });
  }
});

// 2. DOM Content Loaded event to set up the navigation toggle
document.addEventListener("DOMContentLoaded", function () {
  // Slide navigation toggle
  const toggle = document.getElementById("nav-toggle");
  const nav = document.getElementById("side-nav");
  
  // When toggle button is clicked, sidebar is hidden or shown
  toggle.addEventListener("click", function () {
    nav.classList.toggle("nav-hidden");

    // side bookmark toggle icon
    if (toggle.innerText === "❯") {
      toggle.innerText = "❮";
    } else {
      toggle.innerText = "❯";
    }
  });
});
