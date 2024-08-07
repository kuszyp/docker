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
<%@ page import="org.apache.commons.lang.StringUtils" %>
<%@ page import="org.wso2.carbon.core.SameSiteCookie" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointConstants" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointUtil" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.ApiException" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.api.NotificationApi" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.model.Error" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.model.Property" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.model.ResetPasswordRequest" %>
<%@ page import="org.wso2.carbon.identity.core.util.IdentityTenantUtil" %>
<%@ page import="java.io.File" %>
<%@ page import="java.net.URISyntaxException" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="javax.servlet.http.Cookie" %>
<%@ page import="java.util.Base64" %>
<%@ page import="org.wso2.carbon.core.util.SignatureUtil" %>
<%@ page import="org.json.simple.JSONObject" %>
<%@ page import="org.owasp.encoder.Encode" %>
<%@ page import="org.wso2.carbon.identity.recovery.util.Utils" %>
<%@ page import="org.apache.http.client.utils.URIBuilder" %>
<%@ page import="java.net.URI" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.model.User" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.PreferenceRetrievalClient" %>
<%@ taglib prefix="layout" uri="org.wso2.identity.apps.taglibs.layout.controller" %>

<jsp:directive.include file="includes/localize.jsp"/>
<jsp:directive.include file="tenant-resolve.jsp"/>
<jsp:directive.include file="includes/layout-resolver.jsp"/>

<%
    String ERROR_MESSAGE = "errorMsg";
    String ERROR_CODE = "errorCode";
    String PASSWORD_RESET_PAGE = "password-reset.jsp";
    String AUTO_LOGIN_COOKIE_NAME = "ALOR";
    String AUTO_LOGIN_FLOW_TYPE = "RECOVERY";
    String AUTO_LOGIN_COOKIE_DOMAIN = "AutoLoginCookieDomain";
    String RECOVERY_TYPE_INVITE = "invite";
    String passwordHistoryErrorCode = "22001";
    String passwordPatternErrorCode = "20035";
    String confirmationKey =
            IdentityManagementEndpointUtil.getStringValue(request.getSession().getAttribute("confirmationKey"));
    String newPassword = request.getParameter("reset-password");
    String callback = request.getParameter("callback");
    String userStoreDomain = request.getParameter("userstoredomain");
    String type = request.getParameter("type");
    String username = null;
    PreferenceRetrievalClient preferenceRetrievalClient = new PreferenceRetrievalClient();
    Boolean isAutoLoginEnable = preferenceRetrievalClient.checkAutoLoginAfterPasswordRecoveryEnabled(tenantDomain);
    String sessionDataKey = StringUtils.EMPTY;

    if (StringUtils.isBlank(callback)) {
        callback = IdentityManagementEndpointUtil.getUserPortalUrl(
                application.getInitParameter(IdentityManagementEndpointConstants.ConfigConstants.USER_PORTAL_URL), tenantDomain);
    }

    if (StringUtils.isNotBlank(newPassword)) {
        NotificationApi notificationApi = new NotificationApi();
        ResetPasswordRequest resetPasswordRequest = new ResetPasswordRequest();
        List<Property> properties = new ArrayList<Property>();
        Property property = new Property();
        property.setKey("callback");
        property.setValue(URLEncoder.encode(callback, "UTF-8"));
        properties.add(property);

        Property tenantProperty = new Property();
        tenantProperty.setKey(IdentityManagementEndpointConstants.TENANT_DOMAIN);
        if (tenantDomain == null) {
            tenantDomain = IdentityManagementEndpointConstants.SUPER_TENANT;
        }
        tenantProperty.setValue(URLEncoder.encode(tenantDomain, "UTF-8"));
        properties.add(tenantProperty);

        resetPasswordRequest.setKey(confirmationKey);
        resetPasswordRequest.setPassword(newPassword);
        resetPasswordRequest.setProperties(properties);

        try {
            User user = notificationApi.setUserPasswordPost(resetPasswordRequest);
            username = user.getUsername();
            userStoreDomain = user.getRealm();

            if (isAutoLoginEnable) {
                if (userStoreDomain != null) {
                    username = userStoreDomain + "/" + username + "@" + tenantDomain;
                }

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

                if (callback.contains("?")) {
                    String queryParams = callback.substring(callback.indexOf("?") + 1);
                    String[] parameterList = queryParams.split("&");
                    Map<String, String> queryMap = new HashMap<>();
                    for (String param : parameterList) {
                        String key = param.substring(0, param.indexOf("="));
                        String value = param.substring(param.indexOf("=") + 1);
                        queryMap.put(key, value);
                    }
                    sessionDataKey = queryMap.get("sessionDataKey");
                }
            }
        } catch (ApiException e) {

            Error error = IdentityManagementEndpointUtil.buildError(e);
            IdentityManagementEndpointUtil.addErrorInformation(request, error);
            if (error != null) {
                request.setAttribute(ERROR_MESSAGE, error.getDescription());
                request.setAttribute(ERROR_CODE, error.getCode());
                if (passwordHistoryErrorCode.equals(error.getCode()) ||
                        passwordPatternErrorCode.equals(error.getCode())) {
                    String i18Resource = IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, error.getCode());
                    if (!i18Resource.equals(error.getCode())) {
                        request.setAttribute(ERROR_MESSAGE, i18Resource);
                    }
                    request.setAttribute(IdentityManagementEndpointConstants.TENANT_DOMAIN, tenantDomain);
                    request.setAttribute(IdentityManagementEndpointConstants.CALLBACK, callback);
                    request.setAttribute("userstoredomain", userStoreDomain);
                    request.getRequestDispatcher(PASSWORD_RESET_PAGE).forward(request, response);
                    return;
                }
            }
            request.getRequestDispatcher("error.jsp").forward(request, response);
            return;
        }

    } else {
        request.setAttribute("error", true);
        request.setAttribute("errorMsg", IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                "Password.cannot.be.empty"));
        request.setAttribute(IdentityManagementEndpointConstants.TENANT_DOMAIN, tenantDomain);
        request.setAttribute(IdentityManagementEndpointConstants.CALLBACK, callback);
        request.setAttribute("userstoredomain", userStoreDomain);
        request.getRequestDispatcher("password-reset.jsp").forward(request, response);
        return;
    }

    session.invalidate();
%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%-- Data for the layout from the page --%>
<%
    layoutData.put("containerSize", "medium");
%>

<!doctype html>
<html lang="en-US">
<head>
    <%
        File headerFile = new File(getServletContext().getRealPath("extensions/przyjazny-urzad-header.jsp"));
        if (headerFile.exists()) {
    %>
    <jsp:include page="extensions/przyjazny-urzad-header.jsp"/>
    <% } else { %>
    <jsp:include page="includes/header.jsp"/>
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
<body class="login-portal layout blue">
    <% if (!RECOVERY_TYPE_INVITE.equalsIgnoreCase(type)) { %>
        <div>
            <form id="callbackForm" name="callbackForm" method="post" action="/commonauth">
                <div>
                    <input type="hidden" name="username" value="<%=Encode.forHtmlAttribute(username)%>"/>
                </div>
                <div>
                    <input type="hidden" name="sessionDataKey" value="<%=Encode.forHtmlAttribute(sessionDataKey)%>"/>
                </div>
            </form>
        </div>
    <% } %>

    <layout:main layoutName="<%= layout %>" layoutFileRelativePath="<%= layoutFileRelativePath %>" data="<%= layoutData %>" >
        <layout:component componentName="ProductHeader" >
            <!-- product-title -->
            <% if (RECOVERY_TYPE_INVITE.equalsIgnoreCase(type)) {
                File productTitleFile = new File(getServletContext().getRealPath("extensions/przyjazny-urzad-header.jsp"));
                if (productTitleFile.exists()) {
                %>
                <jsp:include page="extensions/przyjazny-urzad-header.jsp"/>
                <%  } else { %>
                <jsp:include page="includes/product-title.jsp"/>
                <% }
            } %>

            <header class="pu-header">
                <div class="pu-header__wcag">
                    <div class="pu-header__wcag__wrapper">
                        <div class="pu-header__wcag__elements">
                            <jsp:include page="extensions/connect-with-translator.jsp"/>

                            <jsp:include page="extensions/high-contrast-toggle.jsp"/>

                            <jsp:include page="extensions/font-size-toggle.jsp"/>

                            <%
                                File productTitleFile = new File(getServletContext().getRealPath("extensions/language-change-temporary.jsp"));
                                if (productTitleFile.exists()) {
                            %>
                            <jsp:include page="extensions/language-change-temporary.jsp"/>
                            <% } else { %>
                            <jsp:include page="includes/product-title.jsp"/>
                            <% } %>
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
                                <jsp:include page="extensions/connect-with-translator.jsp"/>

                                <jsp:include page="extensions/high-contrast-toggle.jsp"/>

                                <jsp:include page="extensions/font-size-toggle.jsp"/>

                                <jsp:include page="extensions/language-change-temporary.jsp"/>
                            </div>
                        </div>
                    </div>
                </div>

                <script>
                    document.addEventListener('DOMContentLoaded', function() {
                        var submenuButton = document.querySelector('.pu-header__submenu');
                        var mobileMenu = document.querySelector('.pu-header__mobile');
                        var closeButton = document.querySelector('.pu-header__mobile__close');

                        function openMenu() {
                            mobileMenu.classList.add('active');
                        }

                        function closeMenu() {
                            mobileMenu.classList.remove('active');
                        }

                        submenuButton.addEventListener('click', openMenu);
                        closeButton.addEventListener('click', closeMenu);
                    });
                </script>
            </header>
        </layout:component>
        <layout:component componentName="MainSection" >
        <% if (RECOVERY_TYPE_INVITE.equalsIgnoreCase(type)) { %>
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
            
                    <div class="pu-login__main">
                      <h3
                        id="loginTitle"
                        class="pu-login__title"
                        data-testid="password-reset-complete-page-header"
                      >
                        Gratulację!
                      </h3>
                      <p id="loginDescription">
                        Twoje nowe hasło zostało ustawione, możesz się zalogować.
                      </p>
                      <div class="pu-login__action center">
                        <a id="loginAction" href="https://test-admin.pm.bydgoszcz.pl/" class="pu-btn pu-btn--primary">Zaloguj się</a>
                      </div>
                    </div>
                  </div>
                </div>
            
                <div class="pu-login__decorative" aria-hidden="true">
                  <img
                    class="pu-login__decorative__one"
                    src="./images/decorative/ilu-3.svg"
                    alt=""
                  />
                  <img
                    class="pu-login__decorative__two"
                    src="./images/decorative/ilu-4.svg"
                    alt=""
                  />
                  <img
                    class="pu-login__decorative__three"
                    src="./images/decorative/repeat-grid-19.svg"
                    alt=""
                  />
                  <img
                    class="pu-login__decorative__four"
                    src="./images/decorative/repeat-grid-64.svg"
                    alt=""
                  />
                </div>
              </main>
        <% } %>
        </layout:component>
        <layout:component componentName="ProductFooter" >
            <!-- product-footer -->
            <% if (RECOVERY_TYPE_INVITE.equalsIgnoreCase(type)) {
                File productFooterFile = new File(getServletContext().getRealPath("extensions/przyjazny-urzad-product-footer.jsp"));
                if (productFooterFile.exists()) {
                %>
                <jsp:include page="extensions/przyjazny-urzad-product-footer.jsp"/>
                <% } else { %>
                <jsp:include page="includes/product-footer.jsp"/>
                <% }
            } %>
        </layout:component>
    </layout:main>

    <%-- footer --%>
    <%
        File footerFile = new File(getServletContext().getRealPath("extensions/footer.jsp"));
        if (footerFile.exists()) {
    %>
    <jsp:include page="extensions/footer.jsp"/>
    <% } else { %>
    <jsp:include page="includes/footer.jsp"/>
    <% } %>

    <script type="application/javascript">
        $(document).ready(function () {
            <%
                try {
                    if (!RECOVERY_TYPE_INVITE.equalsIgnoreCase(type)) {
                        if (isAutoLoginEnable && StringUtils.isNotBlank(sessionDataKey) && (StringUtils.isNotBlank(username))) {
                            %>
                            document.callbackForm.submit();
                            <%
                        } else {
                            URIBuilder callbackUrlBuilder = new
                                    URIBuilder(IdentityManagementEndpointUtil.encodeURL(callback));
                            URI callbackUri = callbackUrlBuilder.addParameter("passwordReset", "true").build();
                            %>
                            location.href = "<%=callbackUri.toString()%>";
                            <%
                        }
                    }
                } catch (URISyntaxException e) {
                    request.setAttribute("error", true);
                    request.setAttribute("errorMsg", "Invalid callback URL found in the request.");
                    request.getRequestDispatcher("error.jsp").forward(request, response);
                    return;
            }
    %>

        });
    </script>

    <script defer type="text/javascript">
        const loginTitle = document.getElementById("loginTitle");
        const loginDescription = document.getElementById("loginDescription");
        const loginAction = document.getElementById("loginAction");
    </script>
</body>
</html>
