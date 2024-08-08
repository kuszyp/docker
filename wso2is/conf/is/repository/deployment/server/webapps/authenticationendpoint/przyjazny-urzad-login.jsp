<%--
  ~ Copyright (c) 2014, WSO2 LLC. (https://www.wso2.com) All Rights Reserved.
  ~
  ~ WSO2 LLC. licenses this file to you under the Apache License,
  ~ Version 2.0 (the "License"); you may not use this file except
  ~ in compliance with the License.
  ~ You may obtain a copy of the License at
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

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.AuthContextAPIClient" %>
<%@ page import="org.apache.commons.collections.CollectionUtils" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.EndpointConfigManager" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.framework.util.FrameworkUtils" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.framework.config.ConfigurationFacade" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.framework.config.model.ExternalIdPConfig" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.Constants" %>
<%@ page import="org.wso2.carbon.identity.core.util.IdentityCoreConstants" %>
<%@ page import="org.wso2.carbon.identity.core.util.IdentityUtil" %>
<%@ page import="org.wso2.carbon.base.ServerConfiguration" %>
<%@ page import="org.wso2.carbon.identity.captcha.util.CaptchaUtil" %>
<%@ page import="static org.wso2.carbon.identity.application.authentication.endpoint.util.Constants.STATUS" %>
<%@ page import="static org.wso2.carbon.identity.application.authentication.endpoint.util.Constants.STATUS_MSG" %>
<%@ page
        import="static org.wso2.carbon.identity.application.authentication.endpoint.util.Constants.CONFIGURATION_ERROR" %>
<%@ page
        import="static org.wso2.carbon.identity.application.authentication.endpoint.util.Constants.AUTHENTICATION_MECHANISM_NOT_CONFIGURED" %>
<%@ page
        import="static org.wso2.carbon.identity.application.authentication.endpoint.util.Constants.ENABLE_AUTHENTICATION_WITH_REST_API" %>
<%@ page
        import="static org.wso2.carbon.identity.application.authentication.endpoint.util.Constants.ERROR_WHILE_BUILDING_THE_ACCOUNT_RECOVERY_ENDPOINT_URL" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.IdentityProviderDataRetrievalClient" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.IdentityProviderDataRetrievalClientException" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointConstants" %>
<%@ page import="java.io.File" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.Map" %>
<%@ taglib prefix="layout" uri="org.wso2.identity.apps.taglibs.layout.controller" %>

<%@ include file="includes/localize.jsp" %>
<jsp:directive.include file="includes/init-url.jsp"/>
<jsp:directive.include file="includes/layout-resolver.jsp"/>

<%!
    private static final String FIDO_AUTHENTICATOR = "FIDOAuthenticator";
    private static final String MAGIC_LINK_AUTHENTICATOR = "MagicLinkAuthenticator";
    private static final String IWA_AUTHENTICATOR = "IwaNTLMAuthenticator";
    private static final String IS_SAAS_APP = "isSaaSApp";
    private static final String BASIC_AUTHENTICATOR = "BasicAuthenticator";
    private static final String IDENTIFIER_EXECUTOR = "IdentifierExecutor";
    private static final String OPEN_ID_AUTHENTICATOR = "OpenIDAuthenticator";
    private static final String JWT_BASIC_AUTHENTICATOR = "JWTBasicAuthenticator";
    private static final String X509_CERTIFICATE_AUTHENTICATOR = "x509CertificateAuthenticator";
    private static final String GOOGLE_AUTHENTICATOR = "GoogleOIDCAuthenticator";
    private String reCaptchaAPI = null;
    private String reCaptchaKey = null;
%>

<%
    request.getSession().invalidate();
    String queryString = request.getQueryString();
    Map<String, String> idpAuthenticatorMapping = null;
    if (request.getAttribute(Constants.IDP_AUTHENTICATOR_MAP) != null) {
        idpAuthenticatorMapping = (Map<String, String>) request.getAttribute(Constants.IDP_AUTHENTICATOR_MAP);
    }

    String errorMessage = "authentication.failed.please.retry";
    String errorCode = "";
    if (request.getParameter(Constants.ERROR_CODE) != null) {
        errorCode = request.getParameter(Constants.ERROR_CODE);
    }
    String loginFailed = "false";

    if (Boolean.parseBoolean(request.getParameter(Constants.AUTH_FAILURE))) {
        loginFailed = "true";
        String error = request.getParameter(Constants.AUTH_FAILURE_MSG);
        // Check the error is not null and whether there is a corresponding value in the resource bundle.
        if (!(StringUtils.isBlank(error)) &&
                !error.equalsIgnoreCase(AuthenticationEndpointUtil.i18n(resourceBundle, error))) {
            errorMessage = error;
        }
    }
%>
<%
    boolean hasLocalLoginOptions = false;
    boolean isBackChannelBasicAuth = false;
    List<String> localAuthenticatorNames = new ArrayList<String>();

    if (idpAuthenticatorMapping != null && idpAuthenticatorMapping.get(Constants.RESIDENT_IDP_RESERVED_NAME) != null) {
        String authList = idpAuthenticatorMapping.get(Constants.RESIDENT_IDP_RESERVED_NAME);
        if (authList != null) {
            localAuthenticatorNames = Arrays.asList(authList.split(","));
        }
    }

    String multiOptionURIParam = "";
    if (localAuthenticatorNames.size() > 1 || idpAuthenticatorMapping != null && idpAuthenticatorMapping.size() > 1) {
        String baseURL;
        try {
            baseURL = ServiceURLBuilder.create().addPath(request.getRequestURI()).build().getRelativePublicURL();
        } catch (URLBuilderException e) {
            request.setAttribute(STATUS, AuthenticationEndpointUtil.i18n(resourceBundle, "internal.error.occurred"));
            request.setAttribute(STATUS_MSG, AuthenticationEndpointUtil.i18n(resourceBundle, "error.when.processing.authentication.request"));
            request.getRequestDispatcher("error.do").forward(request, response);
            return;
        }

        // Build the query string using the parameter map since the query string can contain fewer parameters
        // due to parameter filtering.
        String queryParamString = AuthenticationEndpointUtil.resolveQueryString(request.getParameterMap());
        multiOptionURIParam = "&multiOptionURI=" + Encode.forUriComponent(baseURL + queryParamString);
    }
%>
<%
    boolean reCaptchaEnabled = false;
    if (request.getParameter("reCaptcha") != null && Boolean.parseBoolean(request.getParameter("reCaptcha"))) {
        reCaptchaEnabled = true;
    }

    boolean reCaptchaResendEnabled = false;
    if (request.getParameter("reCaptchaResend") != null && Boolean.parseBoolean(request.getParameter("reCaptchaResend"))) {
        reCaptchaResendEnabled = true;
    }

    if (reCaptchaEnabled || reCaptchaResendEnabled) {
        reCaptchaKey = CaptchaUtil.reCaptchaSiteKey();
        reCaptchaAPI = CaptchaUtil.reCaptchaAPIURL();
    }
%>
<%
    String inputType = request.getParameter("inputType");
    String username = null;
    String usernameIdentifier = null;

    if (isIdentifierFirstLogin(inputType)) {
        if (request.getParameter(Constants.USERNAME) != null) {
            username = request.getParameter(Constants.USERNAME);
            usernameIdentifier = request.getParameter(Constants.USERNAME);
        } else {
            String redirectURL = "error.do";
            response.sendRedirect(redirectURL);
            return;
        }
    }

    // Login context request url.
    String sessionDataKey = request.getParameter("sessionDataKey");
    String appName = request.getParameter("sp");
    String authenticators = request.getParameter("authenticators");
    String loginContextRequestUrl = logincontextURL + "?sessionDataKey=" + Encode.forUriComponent(sessionDataKey) + "&application="
            + Encode.forUriComponent(appName) + "&authenticators=" + Encode.forUriComponent(authenticators);
    if (!IdentityTenantUtil.isTenantQualifiedUrlsEnabled()) {
        // We need to send the tenant domain as a query param only in non tenant qualified URL mode.
        loginContextRequestUrl += "&tenantDomain=" + Encode.forUriComponent(tenantDomain);
    }

    String t = request.getParameter("t");
    String ut = request.getParameter("ut");
    if (StringUtils.isNotBlank(t)) {
        loginContextRequestUrl += "&t=" + t;
    }
    if (StringUtils.isNotBlank(ut)) {
        loginContextRequestUrl += "&ut=" + ut;
    }

    if (StringUtils.isNotBlank(usernameIdentifier)) {
        if (usernameIdentifier.split("@").length == 2) {
            usernameIdentifier = usernameIdentifier.split("@")[0];
        }

        if (usernameIdentifier.split("@").length > 2
                && !StringUtils.equals(usernameIdentifier.split("@")[1], IdentityManagementEndpointConstants.SUPER_TENANT)) {

            usernameIdentifier = usernameIdentifier.split("@")[0] + "@" + usernameIdentifier.split("@")[1];
        }
    }

    String restrictedBrowsersForGOT = "";
    if (StringUtils.isNotEmpty(EndpointConfigManager.getGoogleOneTapRestrictedBrowsers())) {
        restrictedBrowsersForGOT = EndpointConfigManager.getGoogleOneTapRestrictedBrowsers();
    }
%>

<%-- Data for the layout from the page --%>
<%
    layoutData.put("containerSize", "medium");
%>

<!doctype html>
<html lang="pl-PL">
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

    <%
        if (reCaptchaEnabled || reCaptchaResendEnabled) {
    %>
    <script src="<%=Encode.forHtmlContent(reCaptchaAPI)%>"></script>
    <%
        }
    %>
<script>
    const DOMAINS = ["pm.bydgoszcz.pl", "pm-torun.pl", "pm-grudziadz.pl"];

    function findDomain(){
        const domain = DOMAINS.find((value) => {
            return window.location.hostname.includes(value);
        })
        return domain ? "." + domain : "localhost";
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
<body class="login-portal layout authentication-portal-layout" onload="checkSessionKey()">

<% request.setAttribute("pageName", "sign-in"); %>
<% if (new File(getServletContext().getRealPath("extensions/timeout.jsp")).exists()) { %>
<jsp:include page="extensions/timeout.jsp"/>
<% } else { %>
<jsp:include page="util/timeout.jsp"/>
<% } %>

<layout:main layoutName="<%= layout %>" layoutFileRelativePath="<%= layoutFileRelativePath %>" data="<%= layoutData %>">
    <layout:component componentName="ProductHeader">
        <%-- product-title --%>
        <header class="pu-header">
            <div class="pu-header__wcag">
                <div class="pu-header__wcag__wrapper">
                    <div class="pu-header__wcag__elements">
                        <jsp:include page="extensions/connect-with-translator.jsp"/>

                        <jsp:include page="extensions/high-contrast-toggle.jsp"/>

                        <jsp:include page="extensions/font-size-toggle.jsp"/>

                        <%
                            File productTitleFile = new File(getServletContext().getRealPath("extensions/language-change.jsp"));
                            if (productTitleFile.exists()) {
                        %>
                        <jsp:include page="extensions/language-change.jsp"/>
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

                            <jsp:include page="extensions/language-change.jsp"/>
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
    <layout:component componentName="MainSection">
        <div class="pu-login">
            <div class="pu-login__wrapper">
                <div class="pu-login__hero">
                    <div class="pu-login__hero__logo">
                        <img src="./images/logo-BPL-white.svg" alt="Bydgoska Platforma Miejska"/>
                    </div>
                    <div class="pu-login__hero__image">
                        <img src="./images/ilu.svg" alt=""/>
                    </div>
                </div>
                <div class="pu-login__main">
                    <!-- Zaloguj się -->
                    <h2 class="pu-login__title">
                        <%=AuthenticationEndpointUtil.i18n(resourceBundle, "login")%>
                    </h2>

                    <%
                        if (localAuthenticatorNames.size() > 0) {
                            if (localAuthenticatorNames.contains(OPEN_ID_AUTHENTICATOR)) {
                                hasLocalLoginOptions = true;
                    %>
                    <%@ include file="openid.jsp" %>
                    <%
                    } else if (localAuthenticatorNames.contains(IDENTIFIER_EXECUTOR)) {
                        hasLocalLoginOptions = true;
                    %>
                    <%@ include file="identifierauth.jsp" %>
                    <%
                    } else if (localAuthenticatorNames.contains(JWT_BASIC_AUTHENTICATOR) ||
                            localAuthenticatorNames.contains(BASIC_AUTHENTICATOR)) {
                        hasLocalLoginOptions = true;
                        boolean includeBasicAuth = true;
                        if (localAuthenticatorNames.contains(JWT_BASIC_AUTHENTICATOR)) {
                            if (Boolean.parseBoolean(application.getInitParameter(ENABLE_AUTHENTICATION_WITH_REST_API))) {
                                isBackChannelBasicAuth = true;
                            } else {
                                String redirectURL = "error.do?" + STATUS + "=" + CONFIGURATION_ERROR + "&" +
                                        STATUS_MSG + "=" + AUTHENTICATION_MECHANISM_NOT_CONFIGURED;
                                response.sendRedirect(redirectURL);
                                return;
                            }
                        } else if (localAuthenticatorNames.contains(BASIC_AUTHENTICATOR)) {
                            isBackChannelBasicAuth = false;
                            if (TenantDataManager.isTenantListEnabled() && Boolean.parseBoolean(request.getParameter(IS_SAAS_APP))) {
                                includeBasicAuth = false;
                    %>
                    <%@ include file="tenantauth.jsp" %>
                    <%
                            }
                        }

                        if (includeBasicAuth) {
                    %>
                    <%@ include file="przyjazny-urzad-basicauth.jsp" %>
                    <%
                                }
                            }
                        }
                    %>
                    <%
                        if (idpAuthenticatorMapping != null &&
                                idpAuthenticatorMapping.get(Constants.RESIDENT_IDP_RESERVED_NAME) != null) {
                    %>

                    <%} %>
                    <%
                        if ((hasLocalLoginOptions && localAuthenticatorNames.size() > 1) || (!hasLocalLoginOptions)
                                || (hasLocalLoginOptions && idpAuthenticatorMapping != null && idpAuthenticatorMapping.size() > 1)) {
                    %>
                    <% if (localAuthenticatorNames.contains(BASIC_AUTHENTICATOR) ||
                            localAuthenticatorNames.contains(IDENTIFIER_EXECUTOR) ||
                            (idpAuthenticatorMapping != null & idpAuthenticatorMapping.keySet().stream()
                                    .anyMatch(key -> key.contains("login.gov.pl")))) { %>
                    <%
                        boolean showLoginGovDiv = false;
                        String loginGovName = "";
                        String loginGovValue = "";
                        String loginGovImageUrl = "libs/themes/default/assets/images/identity-providers/enterprise-idp-illustration.svg";
                        int mainActionIconId = 0;

                        if (idpAuthenticatorMapping != null && !(
                                localAuthenticatorNames.contains(BASIC_AUTHENTICATOR) || localAuthenticatorNames.contains(IDENTIFIER_EXECUTOR)
                        )) {
                            for (Map.Entry<String, String> idpEntry : idpAuthenticatorMapping.entrySet()) {
                                mainActionIconId++;
                                if (idpEntry.getKey().contains("login.gov.pl")) {
                                    showLoginGovDiv = true;
                                    loginGovName = idpEntry.getKey();
                                    loginGovValue = idpEntry.getValue();

                                    try {
                                        IdentityProviderDataRetrievalClient identityProviderDataRetrievalClient = new IdentityProviderDataRetrievalClient();
                                        loginGovImageUrl = identityProviderDataRetrievalClient.getIdPImage(tenantDomain, loginGovName);
                                    } catch (IdentityProviderDataRetrievalClientException e) {
                                        // Exception is ignored and the default `loginGovImageUrl` value will be used as a fallback.
                                    }

                                    break; // No need to continue the loop once "LoginGov" is found
                                }
                            }
                        }
                    %>

                    <% if (showLoginGovDiv) { %>
                    <div class="pu-login__gov">
                        <button
                                class="pu-login__gov__button"
                                onclick="handleNoDomain(this,
                                        '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(loginGovName))%>',
                                        '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(loginGovValue))%>')"
                                id="icon-<%=mainActionIconId%>"
                                title="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> <%=Encode.forHtmlAttribute(loginGovName)%>"
                        >
                            <!-- <span><%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> <%=Encode.forHtmlContent(loginGovName)%></span> -->
                            <img role="presentation" class="ui image" src="./images/logo_login.svg">
                        </button>
                        <a class="pu-login__gov__info" href="https://login.gov.pl/"
                        ><%=AuthenticationEndpointUtil.i18n(resourceBundle, "login.gov")%>
                        </a
                        >

                    </div>
                    <% } %>


                    <div class="pu-login__social">
                        <button
                                class="pu-login__social__action"
                                aria-expanded="false"
                                aria-controls="content"
                                id="toggleButton"
                        >
                                <span class="pu-login__social__action__text">
                                <img
                                        class="pu-login__social__action__icon"
                                        src="./images/icon-navigation-chevron-blue-up.svg"
                                        alt=""
                                />
                                <%=AuthenticationEndpointUtil.i18n(resourceBundle, "login.in.another.way")%></span
                                >
                        </button>
                        <div
                                class="pu-login__social__content hidden"
                                role="region"
                                aria-labelledby="toggleButton"
                        >
                            <% } %>
                            <%
                                int iconId = 0;
                                if (idpAuthenticatorMapping != null) {
                                    for (Map.Entry<String, String> idpEntry : idpAuthenticatorMapping.entrySet()) {
                                        iconId++;

                                        if (!idpEntry.getKey().equals(Constants.RESIDENT_IDP_RESERVED_NAME)) {
                                            String idpName = idpEntry.getKey();
                                            boolean isHubIdp = false;
                                            boolean isGoogleIdp = false;
                                            boolean isGovIdp = false;

                                            String GOOGLE_CLIENT_ID = "";
                                            String GOOGLE_CALLBACK_URL = "";
                                            boolean GOOGLE_ONE_TAP_ENABLED = false;

                                            if (idpName.endsWith(".hub")) {
                                                isHubIdp = true;
                                                idpName = idpName.substring(0, idpName.length() - 4);
                                            } else if (idpName.contains("Google")) {
                                                isGoogleIdp = true;
                                            } else if (idpEntry.getKey().contains("login.gov.pl")) {
                                                if (
                                                        localAuthenticatorNames.contains(BASIC_AUTHENTICATOR) || localAuthenticatorNames.contains(IDENTIFIER_EXECUTOR)
                                                ) {
                                                    isGovIdp = true;
                                                }
                                            }

                                            // Uses the `IdentityProviderDataRetrievalClient` to get the IDP image.
                                            String imageURL = "libs/themes/default/assets/images/identity-providers/enterprise-idp-illustration.svg";
                                            String FacebookURL = "libs/themes/custom/assets/images/identity-providers/facebook.svg";
                                            String GoogleURL = "libs/themes/custom/assets/images/identity-providers/google.svg";

                                            try {
                                                IdentityProviderDataRetrievalClient identityProviderDataRetrievalClient = new IdentityProviderDataRetrievalClient();
                                                imageURL = identityProviderDataRetrievalClient.getIdPImage(tenantDomain, idpName);
                                            } catch (IdentityProviderDataRetrievalClientException e) {
                                                // Exception is ignored and the default `imageURL` value will be used as a fallback.
                                            }
                            %>
                            <% if (isGovIdp) { %>
                            <div class="pu-login__gov">
                                <button
                                        class="pu-login__social__button"
                                        onclick="handleNoDomain(this,
                                                '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpEntry.getKey()))%>',
                                                '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpEntry.getValue()))%>')"
                                        id="icon-<%=iconId%>"
                                        title="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> <%=Encode.forHtmlAttribute(idpEntry.getKey())%>"
                                >
                                    <img role="presentation" class="ui image" src="./images/logo_login.svg">
                                </button>
                                <a class="pu-login__gov__info" href="https://login.gov.pl/"
                                ><%=AuthenticationEndpointUtil.i18n(resourceBundle, "login.gov")%>
                                </a
                                >

                            </div>
                            <% } %>
                            <% if (isHubIdp) { %>
                            <div class="field">
                                <button class="ui labeled icon button fluid isHubIdpPopupButton" id="icon-<%=iconId%>">
                                    <%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%>
                                    <strong><%=Encode.forHtmlContent(idpName)%>
                                    </strong>
                                </button>
                                <div class="ui flowing popup transition hidden isHubIdpPopup">
                                    <h5 class="font-large"><%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%>
                                        <%=Encode.forHtmlContent(idpName)%>
                                    </h5>
                                    <div class="content">
                                        <form class="ui form">
                                            <div class="field">
                                                <input id="domainName" class="form-control" type="text"
                                                       placeholder="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "domain.name")%>">
                                            </div>
                                            <input type="button" class="ui button primary"
                                                   onClick="javascript: myFunction('<%=idpName%>','<%=idpEntry.getValue()%>','domainName')"
                                                   value="<%=AuthenticationEndpointUtil.i18n(resourceBundle,"go")%>"/>
                                        </form>
                                    </div>
                                </div>
                            </div>
                            <% } else { %>
                            <% if (StringUtils.equals(idpEntry.getValue(), GOOGLE_AUTHENTICATOR)) {
                                isGoogleIdp = true;
                                IdentityProviderDataRetrievalClient identityProviderDataRetrievalClient = new IdentityProviderDataRetrievalClient();
                                List<String> configKeys = new ArrayList<>();
                                configKeys.add("ClientId");
                                configKeys.add("callbackUrl");
                                configKeys.add("IsGoogleOneTapEnabled");

                                try {
                                    Map<String, String> idpConfigMap = identityProviderDataRetrievalClient.getFederatedIdpConfigs(tenantDomain, GOOGLE_AUTHENTICATOR, idpName, configKeys);
                                    if (idpConfigMap != null && !idpConfigMap.isEmpty()) {
                                        GOOGLE_CLIENT_ID = idpConfigMap.get("ClientId");
                                        GOOGLE_CALLBACK_URL = idpConfigMap.get("callbackUrl");
                                        String oneTapEnabledString = idpConfigMap.get("IsGoogleOneTapEnabled");
                                        if (StringUtils.isNotEmpty(oneTapEnabledString)) {
                                            GOOGLE_ONE_TAP_ENABLED = oneTapEnabledString.equals("true");
                                        }
                                    }
                                } catch (IdentityProviderDataRetrievalClientException e) {
                                    // Exception is ignored
                                }
                            %>

                            <button
                                    class="pu-login__social__button"
                                    onclick="handleNoDomain(this,
                                            '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpName))%>',
                                            '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpEntry.getValue()))%>')"
                                    id="icon-<%=iconId%>"
                                    title="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> <%=Encode.forHtmlAttribute(idpName)%>"
                            >
                                <img role="presentation" class="ui image" src="<%=Encode.forHtmlAttribute(GoogleURL)%>">
                            </button>

                            <% if (GOOGLE_ONE_TAP_ENABLED) { %>

                            <script src="https://accounts.google.com/gsi/client" async defer></script>

                            <div id="google_parent" class="google-one-tap-container"></div>

                            <form action="<%=GOOGLE_CALLBACK_URL%>" method="post" id="googleOneTapForm"
                                  style="display: none;">
                                <input type="hidden" name="state"
                                       value="<%=Encode.forHtmlAttribute(request.getParameter("sessionDataKey"))%>"/>
                                <input type="hidden" name="idp" value="<%=idpName%>"/>
                                <input type="hidden" name="authenticator" value="<%=idpEntry.getValue()%>"/>
                                <input type="hidden" name="one_tap_enabled" value="true"/>
                                <input type="hidden" name="internal_submission" value="true"/>
                                <input type="hidden" name="credential" id="credential"/>
                            </form>

                            <script>
                                if (navigator) {
                                    var userAgent = navigator.userAgent;
                                    var browserName = void 0;
                                    var restrictedBrowsersForGOT = "<%=restrictedBrowsersForGOT%>";

                                    if (userAgent.match(/chrome|chromium|crios/i)) {
                                        browserName = "chrome";
                                    } else if (userAgent.match(/firefox|fxios/i)) {
                                        browserName = "firefox";
                                    } else if (userAgent.match(/safari/i)) {
                                        browserName = "safari";
                                    } else if (userAgent.match(/opr\//i)) {
                                        browserName = "opera";
                                    } else if (userAgent.match(/edg/i)) {
                                        browserName = "edge";
                                    } else {
                                        browserName = "No browser detection";
                                    }

                                    if (restrictedBrowsersForGOT !== null
                                        && restrictedBrowsersForGOT !== ''
                                        && restrictedBrowsersForGOT.toLowerCase().includes(browserName)) {
                                        document.getElementById("googleSignIn").style.display = "block";
                                    } else {
                                        window.onload = function callGoogleOneTap() {
                                            google.accounts.id.initialize({
                                                client_id: "<%=Encode.forJavaScriptAttribute(GOOGLE_CLIENT_ID)%>",
                                                prompt_parent_id: "google_parent",
                                                cancel_on_tap_outside: false,
                                                nonce: "<%=Encode.forJavaScriptAttribute(request.getParameter("sessionDataKey"))%>",
                                                callback: handleCredentialResponse
                                            });
                                            google.accounts.id.prompt((notification) => {
                                                onMoment(notification);
                                            });
                                        }
                                    }
                                }
                            </script>
                            <% } else { %>
                            <script>
                                document.getElementById("googleSignIn").style.display = "block";
                            </script>
                            <% } %>
                            <% } else if (!idpName.contains("login.gov.pl")) { %>
                            <button
                                    class="pu-login__social__button"
                                    onclick="handleNoDomain(this,
                                            '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpName))%>',
                                            '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpEntry.getValue()))%>')"
                                    id="icon-<%=iconId%>"
                                    title="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> <%=Encode.forHtmlAttribute(idpName)%>"
                            >
                                <% if (idpName.contains("Facebook")) {%>
                                <img role="presentation" class="ui image" src="<%=Encode.forHtmlAttribute(FacebookURL)%>">
                                <% } else { %>
                                <img role="presentation" class="ui image" src="<%=Encode.forHtmlAttribute(FacebookURL)%>">
                                <span><%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> <%=Encode.forHtmlContent(idpName)%></span>
                                <% } %>
                            </button>
                            <% } %>
                            <% } %>
                            <% } else if (localAuthenticatorNames.size() > 0) {
                                if (localAuthenticatorNames.contains(IWA_AUTHENTICATOR)) {
                            %>
                            <button class="pu-login__social__button"
                                    onclick="handleNoDomain(this,
                                            '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpEntry.getKey()))%>',
                                            'IWAAuthenticator')"
                                    id="icon-<%=iconId%>"
                                    title="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> IWA">
                                <%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%>
                                <strong>IWA</strong>
                            </button>
                            <%
                                }
                                if (localAuthenticatorNames.contains(X509_CERTIFICATE_AUTHENTICATOR)) {
                            %>
                            <button class="pu-login__social__button"
                                    onclick="handleNoDomain(this,
                                            '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpEntry.getKey()))%>',
                                            'x509CertificateAuthenticator')"
                                    id="icon-<%=iconId%>"
                                    title="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> X509 Certificate">
                                <i class="certificate icon"></i>
                                <%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> <strong>x509
                                Certificate</strong>
                            </button>
                            <%
                                }
                                if (localAuthenticatorNames.contains(FIDO_AUTHENTICATOR)) {
                            %>
                            <button class="pu-login__social__button"
                                    onclick="handleNoDomain(this,
                                            '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpEntry.getKey()))%>',
                                            'FIDOAuthenticator')"
                                    id="icon-<%=iconId%>"
                                    title="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%>
                                            <%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with" )%>">
                                <i class="usb icon"></i>
                                <img role="presentation" src="libs/themes/default/assets/images/icons/fingerprint.svg"
                                     alt="Fido Logo"/>
                                <span>
                                                <%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%>
                                                <%=AuthenticationEndpointUtil.i18n(resourceBundle, "fido.authenticator")%>
                                            </span>
                            </button>
                            <%
                                }
                                if (localAuthenticatorNames.contains(MAGIC_LINK_AUTHENTICATOR)) {
                            %>
                            <button class="pu-login__social__button" onclick="handleNoDomain(this,
                                    '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpEntry.getKey()))%>',
                                    '<%=MAGIC_LINK_AUTHENTICATOR%>')" id="icon-<%=iconId%>"
                                    title="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%>
                                                    <%=AuthenticationEndpointUtil.i18n(resourceBundle, "magic.link")%>"
                                    data-componentid="login-page-sign-in-with-magic-link">
                                <img role="presentation" class="ui image"
                                     src="libs/themes/default/assets/images/icons/magic-link-icon.svg"
                                     alt="Magic Link Logo"/>
                                <span>
                                                    <%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%>
                                                    <%=AuthenticationEndpointUtil.i18n(resourceBundle, "magic.link")%>
                                                </span>
                            </button>
                            <%
                                }
                                if (localAuthenticatorNames.contains("totp")) {
                            %>
                            <button class="pu-login__social__button"
                                    onclick="handleNoDomain(this,
                                            '<%=Encode.forJavaScriptAttribute(Encode.forUriComponent(idpEntry.getKey()))%>',
                                            'totp')"
                                    id="icon-<%=iconId%>"
                                    title="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%> TOTP">
                                <i class="key icon"></i> <%=AuthenticationEndpointUtil.i18n(resourceBundle, "sign.in.with")%>
                                <strong>TOTP</strong>
                            </button>
                            <%
                                            }
                                        }
                                    }
                                } %>
                            </div>
                            </div>
                            <% } %>

                            <div class="pu-login__footer">
                                <p>
                                    <%=AuthenticationEndpointUtil.i18n(resourceBundle, "acceptance.regulations")%>
                                    <a href="https://test-cdn.pm.bydgoszcz.pl/resources/files/consents/tenants/mnp_bydgoszcz/pl/REGULAMINY.REGULAMIN.DOKUMENT.pdf"><%=AuthenticationEndpointUtil.i18n(resourceBundle, "acceptance.regulations.link")%>
                                    </a>.
                                </p>
                                <p>
                                    <%=AuthenticationEndpointUtil.i18n(resourceBundle, "acceptance.info")%>
                                </p>
                            </div>

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
                </div>
            </div>

            <div class="pu-login__decorative" aria-hidden="true">
                <img class="pu-login__decorative__one" src="./images/decorative/ilu-1.svg" alt="">
                <img class="pu-login__decorative__two" src="./images/decorative/ilu-2.svg" alt="">
                <img class="pu-login__decorative__three" src="./images/decorative/repeat-grid-18.svg" alt="">
                <img class="pu-login__decorative__four" src="./images/decorative/repeat-grid-63.svg" alt="">
            </div>
        </div>
    </layout:component>
    <layout:component componentName="ProductFooter">
        <!-- <%-- product-footer --%>
        <%
            File productFooterFile = new File(getServletContext().getRealPath("extensions/product-footer.jsp"));
            if (productFooterFile.exists()) {
        %>
        <jsp:include page="extensions/product-footer.jsp"/>
        <% } else { %>
        <jsp:include page="includes/product-footer.jsp"/>
        <% } %> -->
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

<%
    String contextPath =
            ServerConfiguration.getInstance().getFirstProperty(IdentityCoreConstants.PROXY_CONTEXT_PATH);
    if (contextPath != null && contextPath != "") {
        if (contextPath.trim().charAt(0) != '/') {
            contextPath = "/" + contextPath;
        }
        if (contextPath.trim().charAt(contextPath.length() - 1) == '/') {
            contextPath = contextPath.substring(0, contextPath.length() - 1);
        }
        contextPath = contextPath.trim();
    } else {
        contextPath = "";
    }
%>
<script>
    function onMoment(notification) {
        displayGoogleSignIn(notification.isNotDisplayed() || notification.isSkippedMoment());
    }

    function displayGoogleSignIn(display) {
        var element = document.getElementById("googleSignIn");
        if (element != null) {
            if (display) {
                element.style.display = "block";
            } else {
                element.style.display = "none";
            }
        }
    }

    function handleCredentialResponse(response) {
        $('#credential').val(response.credential);
        $('#googleOneTapForm').submit();
    }

    function checkSessionKey() {
        var proxyPath = "<%=contextPath%>"
        $.ajax({
            type: "GET",
            url: proxyPath + "<%=loginContextRequestUrl%>",
            xhrFields: {withCredentials: true},
            success: function (data) {
                if (data && data.status == 'redirect' && data.redirectUrl && data.redirectUrl.length > 0) {
                    window.location.href = data.redirectUrl;
                }
            },
            cache: false
        });
    }

    function getParameterByName(name, url) {
        if (!url) {
            url = window.location.href;
        }
        name = name.replace(/[\[\]]/g, '\\$&');
        var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
            results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return "";
        return decodeURIComponent(results[2].replace(/\+/g, ' '));
    }

    $(document).ready(function () {
        $('#user-name-label').popup({
            lastResort: 'top left'
        });
        $('.main-link').click(function () {
            $('.main-link').next().hide();
            $(this).next().toggle('fast');
            var w = $(document).width();
            var h = $(document).height();
            $('.overlay').css("width", w + "px").css("height", h + "px").show();
        });

        $('.overlay').click(function () {
            $(this).hide();
            $('.main-link').next().hide();
        });
    });

    function myFunction(key, value, name) {
        var object = document.getElementById(name);
        var domain = object.value;


        if (domain != "") {
            document.location = "<%=commonauthURL%>?idp=" + key + "&authenticator=" + value +
                "&sessionDataKey=<%=Encode.forUriComponent(request.getParameter("sessionDataKey"))%>&domain=" +
                domain;
        } else {
            document.location = "<%=commonauthURL%>?idp=" + key + "&authenticator=" + value +
                "&sessionDataKey=<%=Encode.forUriComponent(request.getParameter("sessionDataKey"))%>";
        }
    }

    function handleNoDomain(elem, key, value) {
        var linkClicked = "link-clicked";
        if ($(elem).hasClass(linkClicked)) {
            console.warn("Preventing multi click.")
        } else {
            $(elem).addClass(linkClicked);
            document.location = "<%=commonauthURL%>?idp=" + key + "&authenticator=" + value +
                "&sessionDataKey=<%=Encode.forUriComponent(request.getParameter("sessionDataKey"))%>" +
                "<%=multiOptionURIParam%>";
        }
    }

    window.onunload = function () {
    };

    function changeUsername(e) {
        document.getElementById("changeUserForm").submit();
    }

    $('.isHubIdpPopupButton').popup({
        popup: '.isHubIdpPopup',
        on: 'click',
        position: 'top left',
        delay: {
            show: 300,
            hide: 800
        }
    });
</script>

<%!
    private boolean isIdentifierFirstLogin(String inputType) {
        return "idf".equalsIgnoreCase(inputType);
    }
%>
</body>
</html>
