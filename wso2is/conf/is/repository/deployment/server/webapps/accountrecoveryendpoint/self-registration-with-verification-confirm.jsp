<%--
  ~ Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~  WSO2 Inc. licenses this file to you under the Apache License,
  ~  Version 2.0 (the "License"); you may not use this file except
  ~  in compliance with the License.
  ~  You may obtain a copy of the License at
  ~
  ~    http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied.  See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
  --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.apache.commons.lang.StringUtils" %>
<%@ page import="org.wso2.carbon.base.MultitenantConstants" %>
<%@ page import="org.wso2.carbon.core.SameSiteCookie" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointConstants" %>
<%@ page import="org.wso2.carbon.identity.recovery.IdentityRecoveryConstants" %>
<%@ page import="org.wso2.carbon.identity.base.IdentityRuntimeException" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointUtil" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.PreferenceRetrievalClient" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.api.SelfRegisterApi" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.model.CodeValidationRequest" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.model.Property" %>
<%@ page import="org.wso2.carbon.identity.core.util.IdentityTenantUtil" %>
<%@ page import="java.io.File" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="javax.ws.rs.HttpMethod" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.model.User" %>
<%@ page import="org.wso2.carbon.identity.recovery.util.Utils" %>
<%@ page import="org.wso2.carbon.core.util.SignatureUtil" %>
<%@ page import="org.json.simple.JSONObject" %>
<%@ page import="javax.servlet.http.Cookie" %>
<%@ page import="java.util.Base64" %>

<jsp:directive.include file="includes/localize.jsp"/>
<jsp:directive.include file="tenant-resolve.jsp"/>

<%
    boolean error = IdentityManagementEndpointUtil.getBooleanValue(request.getAttribute("error"));
    String errorMsg = IdentityManagementEndpointUtil.getStringValue(request.getAttribute("errorMsg"));
    String AUTO_LOGIN_COOKIE_NAME = "ALOR";
    String AUTO_LOGIN_COOKIE_DOMAIN = "AutoLoginCookieDomain";
    String AUTO_LOGIN_FLOW_TYPE = "SIGNUP";
    String username = null;

    String confirmationKey = request.getParameter("confirmation");
    String callback = request.getParameter("callback");
    String httpMethod = request.getMethod();
    PreferenceRetrievalClient preferenceRetrievalClient = new PreferenceRetrievalClient();
    Boolean isAutoLoginEnable = preferenceRetrievalClient.checkAutoLoginAfterSelfRegistrationEnabled(tenantDomain);

    // Some mail providers initially sends a HEAD request to
    // check the validity of the link before redirecting users.
    if (StringUtils.equals(httpMethod, HttpMethod.HEAD)) {
        response.setStatus(response.SC_OK);
        return;
    }

    try {
        if (StringUtils.isNotBlank(callback) && !Utils.validateCallbackURL(callback, tenantDomain,
            IdentityRecoveryConstants.ConnectorConfig.SELF_REGISTRATION_CALLBACK_REGEX)) {
            request.setAttribute("error", true);
            request.setAttribute("errorMsg", IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                "Callback.url.format.invalid"));
            request.getRequestDispatcher("error.jsp").forward(request, response);
            return;
        }
    } catch (IdentityRuntimeException e) {
        request.setAttribute("error", true);
        request.setAttribute("errorMsg", e.getMessage());
        request.getRequestDispatcher("error.jsp").forward(request, response);
        return;
    }

    if (StringUtils.isBlank(callback)) {
        callback = IdentityManagementEndpointUtil.getUserPortalUrl(
                application.getInitParameter(IdentityManagementEndpointConstants.ConfigConstants.USER_PORTAL_URL), tenantDomain);
    }


    if (StringUtils.isBlank(confirmationKey)) {
        confirmationKey = IdentityManagementEndpointUtil.getStringValue(request.getAttribute("confirmationKey"));
    }
    String message = "" ;

    try {
        SelfRegisterApi selfRegisterApi = new SelfRegisterApi();
        CodeValidationRequest validationRequest = new CodeValidationRequest();
        List<Property> properties = new ArrayList<>();
        Property tenantDomainProperty = new Property();
        tenantDomainProperty.setKey(MultitenantConstants.TENANT_DOMAIN);
        tenantDomainProperty.setValue(tenantDomain);
        properties.add(tenantDomainProperty);

        validationRequest.setCode(confirmationKey);
        validationRequest.setProperties(properties);

        User user = selfRegisterApi.validateCodeUserPostCall(validationRequest);
        username = user.getUsername();
        String userStoreDomain = user.getRealm();
        tenantDomain = user.getTenantDomain();
        if (isAutoLoginEnable) {
            username = userStoreDomain + "/" + username + "@" + tenantDomain;

            String cookieDomain = application.getInitParameter(AUTO_LOGIN_COOKIE_DOMAIN);
            JSONObject contentValueInJson = new JSONObject();
            contentValueInJson.put("username", username);
            contentValueInJson.put("createdTime", System.currentTimeMillis());
            contentValueInJson.put("flowType", AUTO_LOGIN_FLOW_TYPE);
            if (StringUtils.isNotBlank(cookieDomain)) {
                contentValueInJson.put("domain", cookieDomain);
            }
            String content = contentValueInJson.toString();

            JSONObject cookieValueInJson = new JSONObject();
            cookieValueInJson.put("content", content);
            String signature = Base64.getEncoder().encodeToString(SignatureUtil.doSignature(content));
            cookieValueInJson.put("signature", signature);
            String cookieValue = Base64.getEncoder().encodeToString(cookieValueInJson.toString().getBytes());

            IdentityManagementEndpointUtil.setCookie(request, response, AUTO_LOGIN_COOKIE_NAME, cookieValue,
                300, SameSiteCookie.NONE, "/", cookieDomain);
            request.setAttribute("isAutoLoginEnabled", true);
        }

    } catch (Exception e) {
        IdentityManagementEndpointUtil.addErrorInformation(request, e);
        request.getRequestDispatcher("error.jsp").forward(request, response);
        return;
    }
%>

    <html lang="en-US">
    <head>
        <%-- header --%>
        <%
            File headerFile = new File(getServletContext().getRealPath("extensions/przyjazny-urzad-header.jsp"));
            if (headerFile.exists()) {
        %>
                <jsp:include page="extensions/przyjazny-urzad-header.jsp"/>
        <% } else { %>
                <jsp:include page="includes/header.jsp"/>
        <% } %>

        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%-- title --%>
        <%
            File titleFile = new File(getServletContext().getRealPath("extensions/title.jsp"));
            if (titleFile.exists()) {
        %>
                <jsp:include page="extensions/title.jsp"/>
        <% } else { %>
                <jsp:include page="includes/title.jsp"/>
        <% } %>

        <script>
            const DOMAINS = [".pm.bydgoszcz.pl", ".pm-torun.pl", ".pm-grudziadz.pl"];

            function findDomain(){
                const domain = DOMAINS.find((value) => {
                    return window.location.hostname.includes(value);
                })
                return domain ?? "localhost";
            }

            function updateCookie(cookiePartials) {
                const cookie = getCookie();
                const expires = '; expires=' + new Date(2099, 1, 1).toUTCString();
                let cookieValue = '';
                if (cookie) {
                    const newCookie = {...cookie, ...cookiePartials};
                    cookieValue = JSON.stringify(newCookie);
                } else {
                    cookieValue = JSON.stringify(cookiePartials);
                }
                let cookieString = "applicationContext="+cookieValue+"; expires="+expires+"; path=/";
                const domain = findDomain();
                cookieString += '; domain=' + domain;

                document.cookie = cookieString;
            }

            function getCookie() {
                const name = "applicationContext=";
                const decodedCookie = decodeURIComponent(document.cookie);
                const cookieArray = decodedCookie.split(';');
                for (const cookie of cookieArray) {
                    const trimmedCookie = cookie.trim();
                    if (trimmedCookie.startsWith(name)) {
                        const cookieValue = trimmedCookie.substring(name.length);
                        try {
                            const parsedValue = JSON.parse(cookieValue);
                            if (parsedValue && typeof parsedValue === 'object') {
                                return parsedValue;
                            }
                        } catch (error) {
                            console.error('Błąd podczas parsowania wartości ciasteczka:', error);
                        }
                    }
                }
                return null;
            }
        </script>
    </head>

    <body class="overflow-hidden">
      <header class="pu-header">
        <div class="pu-header__wcag">
          <div class="pu-header__wcag__wrapper">
            <div class="pu-header__wcag__elements">
              <jsp:include page="extensions/connect-with-translator.jsp" />

              <jsp:include page="extensions/high-contrast-toggle.jsp" />

              <jsp:include page="extensions/font-size-toggle.jsp" />

              <jsp:include page="extensions/language-change.jsp" />
            </div>

            <button
              class="pu-header__submenu"
              aria-label="Otwórz panel"
              type="button"
            >
              <span class="vertical-dots" />
            </button>

            <div class="pu-header__mobile">
              <button class="pu-header__mobile__close">
                <span class="sr-only">Zamknij mobilne menu</span>
              </button>
              <div class="pu-header__mobile__container">
                <jsp:include
                  page="extensions/connect-with-translator.jsp"
                />

                <jsp:include page="extensions/high-contrast-toggle.jsp" />

                <jsp:include page="extensions/font-size-toggle.jsp" />

                <jsp:include page="extensions/language-change.jsp" />
              </div>
            </div>
          </div>
        </div>

        <script>
          document.addEventListener("DOMContentLoaded", function () {
            var submenuButton = document.querySelector(
              ".pu-header__submenu"
            );
            var mobileMenu = document.querySelector(".pu-header__mobile");
            var closeButton = document.querySelector(
              ".pu-header__mobile__close"
            );

            function openMenu() {
              mobileMenu.classList.add("active");
            }

            function closeMenu() {
              mobileMenu.classList.remove("active");
            }

            submenuButton.addEventListener("click", openMenu);
            closeButton.addEventListener("click", closeMenu);
          });
        </script>
      </header>

    <%-- page content --%>
    <main>
        <div class="pu-login">
          <div class="pu-login__wrapper">
            <div class="pu-login__hero">
              <div class="pu-login__hero__logo">
                <img
                  src="./images/logo-BPL-white.svg"
                  alt="Bydgoska Platforma Miejska"
                />
              </div>
              <div class="pu-login__hero__image">
                <img src="./images/ilu.svg" alt="" />
              </div>
            </div>

            <div class="pu-login__main min-height alert">
              <img class="pu-login__alert" src="./images/icon-alert-ok.svg" alt="" />
              <h3
                id="login__title"
                class="pu-login__title two-lines"
                data-testid="password-reset-complete-page-header"
              >
                <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                "self.registration.with.verification.confirm.title.one")%>
                <br />
                <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                "self.registration.with.verification.confirm.title.two")%>
              </h3>
              <div class="content">
                <p>
                  <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                  "self.registration.with.verification.confirm.title.description")%>
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="pu-login__action">
          <a href="https://test-portal.pm.bydgoszcz.pl/" class="pu-btn pu-btn--primary">
              <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "Next")%>
          </a>
        </div>

        <div class="pu-login__decorative" aria-hidden="true">
          <img
            class="pu-login__decorative__one"
            src="./images/decorative/ilu-1.svg"
            alt=""
          />
          <img
            class="pu-login__decorative__two"
            src="./images/decorative/ilu-2.svg"
            alt=""
          />
          <img
            class="pu-login__decorative__three"
            src="./images/decorative/repeat-grid-18.svg"
            alt=""
          />
          <img
            class="pu-login__decorative__four"
            src="./images/decorative/repeat-grid-63.svg"
            alt=""
          />
        </div>
      </main>

    <%-- footer --%>
    <%
        File footerFile = new File(getServletContext().getRealPath("extensions/footer.jsp"));
        if (footerFile.exists()) {
    %>
            <jsp:include page="extensions/footer.jsp"/>
    <% } else { %>
            <jsp:include page="includes/footer.jsp"/>
    <% } %>

    <script src="libs/jquery_3.6.0/jquery-3.6.0.min.js"></script>
    <script src="libs/bootstrap_3.4.1/js/bootstrap.min.js"></script>
    </body>
    </html>
