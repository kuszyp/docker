<script>
  document
    .getElementById("toggleButton")
    .addEventListener("click", function () {
      const content = document.querySelector(".pu-login__social__content");
      const isExpanded = this.getAttribute("aria-expanded") === "true";

      this.setAttribute("aria-expanded", !isExpanded);
      content.style.display = isExpanded ? "none" : "grid";
    });
</script>
