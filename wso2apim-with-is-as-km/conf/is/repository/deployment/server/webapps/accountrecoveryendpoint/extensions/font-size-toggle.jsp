<%@ include file="../includes/localize.jsp" %>

<div class="pu-header__wcag__font">
    <span id="font-size-text" class="pu-header__wcag__font__title"><%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,"font.size")%></span>
    <div class="pu-header__wcag__font__action">
      <button
        id="font-normal-button"
        class="pu-header__wcag__font__button normal"
        type="button"
        [class.active]="contextOptionsService.normalActive"
        aria-label="<%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,"font.size.small")%>"
        onClick={setFontSize("normal")}
      >
        A</button
      ><button
        id="font-bigger-button"
        class="pu-header__wcag__font__button bigger"
        type="button"
        [class.active]="contextOptionsService.biggerActive"
        aria-label="<%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,"font.size.big")%>"
        onClick={setFontSize("large")}
      >
        A
      </button>
    </div>
</div>

<script>
  const normalButton = document.getElementById("font-normal-button");
  const biggerButton = document.getElementById("font-bigger-button");

  function setFontSize(size) {
    if (size === "large") {
      document.documentElement.classList.add("pu-font--bigger");
      document.documentElement.classList.remove("pu-font--normal");
      biggerButton.setAttribute("aria-pressed", "true");
      biggerButton.classList.add("active");

      normalButton.setAttribute("aria-pressed", "false");
      normalButton.classList.remove("active");
      updateCookie({
          fontSize: "large",
      })
      return;
    }

    document.documentElement.classList.remove("pu-font--bigger");
    document.documentElement.classList.add("pu-font--normal");

    normalButton.setAttribute("aria-pressed", "true");
    normalButton.classList.add("active");

    biggerButton.setAttribute("aria-pressed", "false");
    biggerButton.classList.remove("active");


    updateCookie({
        fontSize: "normal",
    })
  }

  const fontSize = getCookie()?.fontSize || "normal";
  setFontSize(fontSize);
</script>

