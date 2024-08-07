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
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointConstants" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointUtil" %>
<%@ page import="java.net.MalformedURLException" %>
<%@ page import="java.io.File" %>
<%@ page import="org.wso2.carbon.identity.recovery.util.Utils" %>
<%@ page import="org.owasp.encoder.Encode" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<%@ taglib prefix="layout" uri="org.wso2.identity.apps.taglibs.layout.controller" %>

<jsp:directive.include file="includes/localize.jsp"/>
<jsp:directive.include file="tenant-resolve.jsp"/>
<jsp:directive.include file="includes/layout-resolver.jsp"/>

<%
    boolean isEmailNotificationEnabled = false;
    String callback = (String) request.getParameter("callback");
    String username = request.getParameter("username");
    String userStoreDomain = request.getParameter("userstoredomain");
    String sessionDataKey = StringUtils.EMPTY;
    String fullyQualifiedUsername = username;
    boolean hasAutoLoginCookie = IdentityManagementEndpointUtil.getBooleanValue(request.getAttribute("isAutoLoginEnabled"));

    if (StringUtils.isBlank(callback)) {
        callback = IdentityManagementEndpointUtil.getUserPortalUrl(
                application.getInitParameter(IdentityManagementEndpointConstants.ConfigConstants.USER_PORTAL_URL), tenantDomain);
    }
    String confirm = (String) request.getAttribute("confirm");
    String confirmLiteReg = (String) request.getAttribute("confirmLiteReg");

    isEmailNotificationEnabled = Boolean.parseBoolean(application.getInitParameter(
            IdentityManagementEndpointConstants.ConfigConstants.ENABLE_EMAIL_NOTIFICATION));
    boolean isSessionDataKeyPresent = false;
    if (StringUtils.isNotBlank(userStoreDomain)) {
        fullyQualifiedUsername = userStoreDomain + "/" + username + "@" + tenantDomain;
    }

    // Check for query params in callback URL.
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
        if (StringUtils.isNotBlank(sessionDataKey)) {
            isSessionDataKeyPresent = true;
        }
    }
%>

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
<body class="overflow-hidden">
    <% if (StringUtils.isNotBlank(confirmLiteReg) && confirmLiteReg.equals("true")) {
        response.sendRedirect(callback);
    } else { %>
        <layout:main layoutName="<%= layout %>" layoutFileRelativePath="<%= layoutFileRelativePath %>" data="<%= layoutData %>" >
            <layout:component componentName="ProductHeader">
              <jsp:include page="extensions/przyjazny-urzad-header.jsp" />
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
            </layout:component>
            <layout:component componentName="MainSection" >
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
        
                        <div class="pu-login__main min-height">
                          <h3
                            id="loginTitle"
                            class="pu-login__title"
                            data-testid="password-reset-complete-page-header"
                          >
                            <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                            "self.registration.complete.title")%>
                          </h3>
                          <div class="content">
                            <% if (StringUtils.isNotBlank(confirm) &&
                            confirm.equals("true")) {%>
                            <p>
                              <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                              "Successfully.confirmed")%>
                            </p>
                            <% } else { if (isEmailNotificationEnabled) { %>
                            <p>
                                <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                                "self.registration.complete.description.one")%>
                            </p>
                            <p>
                                <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                                "self.registration.complete.description.two")%>
                            </p>
                            <% } else {%>
                            <p>
                              <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                              "User.registration.completed.successfully")%>
                            </p>
                            <% } } %>
                          </div>
                          <div class="pu-login__dropdown">
                            <button
                                class="pu-login__dropdown__action"
                                aria-expanded="false"
                                aria-controls="content"
                                id="toggleButton"
                            > 
                                <img
                                    src="./images/icon-navigation-chevron-large-down.svg"
                                    alt=""
                                />
                                <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                                "self.registration.complete.dropdown.action")%>
                            </button>
                            <div
                                class="pu-login__dropdown__content hidden"
                                role="region"
                                aria-labelledby="toggleButton"
                            >
                                <ul class="pu-custom-list">
                                    <li>
                                        <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                                        "self.registration.complete.dropdown.one")%>
                                    </li>
                                    <li>
                                        <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                                        "self.registration.complete.dropdown.two")%>
                                    </li>
                                </ul>
                            </div>
                              
                              <script>
                                document
                                  .getElementById("toggleButton")
                                  .addEventListener("click", function () {
                                    const content = document.querySelector(".pu-login__dropdown__content");
                                    const isExpanded = this.getAttribute("aria-expanded") === "true";
                              
                                    this.setAttribute("aria-expanded", !isExpanded);
                                    content.style.display = isExpanded ? "none" : "grid";
                                  });
                              </script>
                          </div>
                          <form
                            id="callbackForm"
                            name="callbackForm"
                            method="post"
                            action="/commonauth"
                          >
                            <div>
                              <input
                                type="hidden"
                                name="username"
                                value="<%=Encode.forHtmlAttribute(fullyQualifiedUsername)%>"
                              />
                            </div>
                            <div>
                              <input
                                type="hidden"
                                name="sessionDataKey"
                                value="<%=Encode.forHtmlAttribute(sessionDataKey)%>"
                              />
                            </div>
                          </form>
                        </div>
                      </div>
                      <div class="pu-login__back">
                        <a href="https://test-portal.pm.bydgoszcz.pl/" class="pu-login__back__button">
                            <img
                                src="./images/icon-action-remove.svg"
                                alt=""
                            />
                            <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                            "self.registration.complete.back")%>
                        </a>
                      </div>
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
            </layout:component>
            <layout:component componentName="ProductFooter" >

            </layout:component>
        </layout:main>
    <% }%>

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
            $('.notify').modal({
                onHide: function () {
                    <%
                        try {
                            if (hasAutoLoginCookie && isSessionDataKeyPresent &&
                            StringUtils.isNotBlank(fullyQualifiedUsername)) {
                    %>
                    document.callbackForm.submit();
                    <%
                        } else {
                    %>
                    location.href = "<%= IdentityManagementEndpointUtil.encodeURL(callback)%>";
                    <%
                            }
                    } catch (MalformedURLException e) {
                        request.setAttribute("error", true);
                        request.setAttribute("errorMsg", "Invalid callback URL found in the request.");
                        request.getRequestDispatcher("error.jsp").forward(request, response);
                        return;
                    }
                    %>
                },
                blurring: true,
                detachable: true,
                closable: false,
                centered: true,
            }).modal("show");
        });
    </script>
</body>
</html>
