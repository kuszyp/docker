<select
  id="language-change-select"
  class="pu-language-change"
  onchange="LanguageChange(event)"
>
  <option value="pl_PL">PL</option>
  <option value="en_GB">ENG</option>
</select>

<script defer type="text/javascript">
  function LanguageChange(event) {
    const selectedOption = event.target.value;
    document.cookie = "lang=" + selectedOption + "; path=/;";
    window.location.reload();
  }

  const langCookie = document.cookie
    .split("; ")
    .find((cookie) => cookie.startsWith("lang="));
  if (langCookie) {
    const defaultLang = langCookie.split("=")[1];
    document.querySelector("#language-change-select").value = defaultLang;
  }
</script>
