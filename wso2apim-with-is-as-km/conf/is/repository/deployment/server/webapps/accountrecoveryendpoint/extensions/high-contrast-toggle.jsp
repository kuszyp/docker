<%@ include file="../includes/localize.jsp" %>

<button
  id="high-contrast-button"
  class="pu-header__wcag__element active"
  type="button"
  onClick="{handleButtonClick()}"
>
  <span id="high-contrast-text"><%= IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "high.contrast") %></span>
  <span class="pu-header__wcag__element__image">
    <img src="images/icon-navbar-high-contrast.svg" alt=""
  /></span>
</button>

<script>
  const className = "pu-highcontrast";
  const storageName = "highContrast";
  const highContrastButton = document.querySelector("#high-contrast-button");

  function applyHighContrastToButton() {
      highContrastButton.classList.add("active");
      highContrastButton.setAttribute("aria-pressed", "true");
      highContrastButton.setAttribute("aria-label",  "<%= IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "high.contrast.turn.off") %>");
  }

  function removeHighContrastFromButton() {
      highContrastButton.classList.remove("active");
      highContrastButton.setAttribute("aria-pressed", "false");
      highContrastButton.setAttribute("aria-label", "<%= IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "high.contrast.turn.on") %>");
  }

  function handleButtonClick() {
      const highContrast = document.querySelector('body').classList.contains(className);
      document.querySelector('body').classList.toggle(className, !highContrast);
      updateCookie({
        highContrast: !highContrast,
      })

      if (highContrast) removeHighContrastFromButton();
      else applyHighContrastToButton();
  }

  const highContrast = getCookie()?.highContrast ?? false;
  if (highContrast) {
      document.querySelector('body').classList.add(className);
      applyHighContrastToButton();
  } else removeHighContrastFromButton();
</script>
