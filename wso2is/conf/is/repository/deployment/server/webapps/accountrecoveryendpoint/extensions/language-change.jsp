<%@ include file="../includes/localize.jsp" %>

<div
  role="combobox"
  aria-haspopup="listbox"
  aria-expanded="false"
  aria-owns="pu-dropdown"
  class="pu-dropdown"
  id="language-dropdown"
>
  <button
    class="pu-header__wcag__element"
    aria-label="<%= IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "language.open") %>"
    onclick="toggleDropdown()"
    type="button"
  >
    <%= IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "language.title") %>
    <span class="pu-header__wcag__element__image">
      <img
        alt=""
        width="24"
        height="24"
        src="images/icon-navbar-languages.svg"
      />
    </span>
    <span class="pu-header__wcag__element__activeLanguage">pl</span>
  </button>
  <ul
    role="listbox"
    id="pu-dropdown"
    class="pu-dropdown__content"
    style="display: none"
  >
    <li
      role="option"
      aria-selected="true"
      class="pu-dropdown__option"
      onclick="LanguageChange('pl')"
    >
      <%= IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "language.polish") %>
      <span class="pu-dropdown__option__check" style="display: none">
        <img alt="" width="24" height="24" src="images/icon-check.svg" />
      </span>
    </li>
    <li
      role="option"
      aria-selected="false"
      class="pu-dropdown__option"
      onclick="LanguageChange('en')"
    >
      <%= IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "language.english") %>
      <span class="pu-dropdown__option__check" style="display: none">
        <img alt="" width="24" height="24" src="images/icon-check.svg" />
      </span>
    </li>
  </ul>
</div>

<script defer type="text/javascript">
  const languageSpan = document.querySelector(".pu-header__wcag__element__activeLanguage");

  function LanguageChange(selectedOption) {
    document.cookie = "lang=" + selectedOption + "; path=/;";
    updateCookie({
      language: selectedOption,
    })
    window.location.reload();
  }

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
      closeDropdown();
    } else {
      handleArrowNavigation(event);
    }
  });

  function handleArrowNavigation(event) {
    const dropdown = document.getElementById("pu-dropdown");
    if (dropdown.style.display === "none") {
      return;
    }

    const options = Array.from(
      dropdown.querySelectorAll(".pu-dropdown__option")
    );

    let highlightedIndex = options.findIndex((option) =>
      option.classList.contains("highlighted")
    );

    if (event.key === "ArrowDown") {
      event.preventDefault();
      highlightedIndex = (highlightedIndex + 1) % options.length;
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      highlightedIndex =
        (highlightedIndex - 1 + options.length) % options.length;
    } else if (event.key === "Enter") {
      event.preventDefault();
      if (highlightedIndex >= 0) {
        const selectedOptionValue = options[highlightedIndex]
          .getAttribute("onclick")
          .split("'")[1];
        LanguageChange(selectedOptionValue);
      }
    }

    updateHighlightedOption(highlightedIndex, options);
  }

  function updateHighlightedOption(index, options) {
    options.forEach((option, i) => {
      option.classList.remove("highlighted");
      const checkMark = option.querySelector(".pu-dropdown__option__check");
      if (checkMark) {
        checkMark.style.display = "none";
      }
      if (i === index) {
        option.classList.add("highlighted");
        if (checkMark) {
          checkMark.style.display = "block";
        }
      }
    });
  }

  document.addEventListener("click", function (event) {
    const dropdown = document.getElementById("pu-dropdown");
    const languageDropdown = document.getElementById("language-dropdown");
    const isClickInsideLanguageDropdown = languageDropdown.contains(
      event.target
    );

    if (dropdown.style.display !== "none" && !isClickInsideLanguageDropdown) {
      closeDropdown();
    }
  });

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
      closeDropdown();
    }
  });

  function closeDropdown() {
    const dropdown = document.getElementById("pu-dropdown");
    if (dropdown.style.display !== "none") {
      dropdown.style.display = "none";
      document
        .getElementById("language-dropdown")
        .setAttribute("aria-expanded", "false");
    }
  }

  function updateLanguageSelection(selectedLang) {
    languageSpan.innerHTML = selectedLang;
    const options = document.querySelectorAll("#pu-dropdown li");
    options.forEach((option) => {
      option.classList.remove("highlighted");
      const checkMark = option.querySelector(".pu-dropdown__option__check");
      if (checkMark) {
        checkMark.style.display = "none";
      }

      if (option.innerText.toLowerCase().includes(selectedLang)) {
        option.classList.add("highlighted");
        if (checkMark) {
          checkMark.style.display = "block";
        }
      }
    });
  }

  function toggleDropdown() {
    const dropdown = document.getElementById("pu-dropdown");
    const isExpanded = dropdown.style.display !== "none";
    dropdown.style.display = isExpanded ? "none" : "block";
    document
      .getElementById("language-dropdown")
      .setAttribute("aria-expanded", !isExpanded);
  }

  const langCookie = document.cookie
    .split("; ")
    .find((cookie) => cookie.startsWith("lang="));

  const lang = getCookie()?.language;

  if (lang && !langCookie) {
    updateLanguageSelection(lang)
  } else if (langCookie && !lang) {
    const defaultLang = langCookie.split("=")[1] // "pl | en";
    updateLanguageSelection(defaultLang)
  } else if (langCookie && lang) {
    const defaultLang = langCookie.split("=")[1] // "pl | en";
    if (defaultLang !== lang) {
      document.cookie = "lang=" + lang + "; path=/;";
      window.location.reload();
    }
    updateLanguageSelection(lang)
  } else {
    updateLanguageSelection("pl")
  }
</script>
