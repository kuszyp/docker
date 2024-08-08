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

<%@ page import="org.owasp.encoder.Encode" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointConstants" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointUtil" %>
<%@ page import="org.wso2.carbon.identity.core.util.IdentityTenantUtil" %>
<%@ page import="java.io.File" %>
<%@ taglib prefix="layout" uri="org.wso2.identity.apps.taglibs.layout.controller" %>

<jsp:directive.include file="includes/localize.jsp"/>
<jsp:directive.include file="includes/layout-resolver.jsp"/>

<%
    boolean error = IdentityManagementEndpointUtil.getBooleanValue(request.getAttribute("error"));
    String errorMsg = IdentityManagementEndpointUtil.getStringValue(request.getAttribute("errorMsg"));
    String callback = (String) request.getAttribute(IdentityManagementEndpointConstants.CALLBACK);
    String username = request.getParameter("username");
    String userStoreDomain = request.getParameter("userstoredomain");
    String type = request.getParameter("type");
    String tenantDomain = (String) request.getAttribute(IdentityManagementEndpointConstants.TENANT_DOMAIN);
    if (tenantDomain == null) {
        tenantDomain = (String) session.getAttribute(IdentityManagementEndpointConstants.TENANT_DOMAIN);
    }
    if (username == null) {
        username = (String) request.getAttribute("username");
    }
    if (userStoreDomain == null) {
        userStoreDomain = (String) request.getAttribute("userstoredomain");
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
    <body class="login-portal layout recovery-layout blue">
        <layout:main layoutName="<%= layout %>" layoutFileRelativePath="<%= layoutFileRelativePath %>" data="<%= layoutData %>" >
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
            <layout:component componentName="MainSection" >
                <main>
                    <div class="pu-login">

                        <div class="pu-login__wrapper">

                            <div class="pu-login__hero">
                                <div class="pu-login__hero__logo">
                                    <img src="./images/logo-BPL-white.svg" alt="Bydgoska Platforma Miejska" />
                                </div>
                                <div class="pu-login__hero__image">
                                    <img src="./images/ilu.svg" alt="" />
                                </div>
                            </div>


                            <div class="pu-login__main">
                                <%-- content --%>
                                <h2 class="pu-login__title">
                                    <%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "Reset.Password")%>
                                </h2>

                                <% if (error) { %>
                                <p class="ui visible negative message" id="server-error-msg">
                                    <%=IdentityManagementEndpointUtil.i18nBase64(recoveryResourceBundle, errorMsg)%>
                                </p>
                                <% } %>
                                <p id="ui visible negative message" hidden="hidden"></p>

                                <div class="segment-form">
                                    <form class="pu-form" method="post" action="completepasswordreset.do" id="passwordResetForm">
                                        <div class="ui negative message" hidden="hidden" id="error-msg"></div>
                                        <div class="pu-form__container">
                                            <img class="pu-form__icon" src="./images/icon-login.svg" alt="" aria-hidden="true">
                                            <input
                                                class="pu-form__input"
                                                id="reset-password"
                                                name="reset-password"
                                                type="password"
                                                required=""
                                                placeholder="<%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                                                "Enter.new.password")%>"
                                            />
                                            <i id="passwordShowHide" class="eye link icon slash"
                                            onclick="passwordShowToggle()"></i>
                                        </div>

                                        <%
                                            if (username != null) {
                                        %>
                                        <div>
                                            <input type="hidden" name="username" value="<%=Encode.forHtmlAttribute(username) %>"/>
                                        </div>
                                        <%
                                            }
                                        %>

                                        <%
                                            if (callback != null) {
                                        %>
                                        <div>
                                            <input type="hidden" name="callback" value="<%=Encode.forHtmlAttribute(callback) %>"/>
                                        </div>
                                        <%
                                            }
                                        %>

                                        <%
                                            if (userStoreDomain != null) {
                                        %>
                                        <div>
                                            <input type="hidden" name="userstoredomain"
                                                value="<%=Encode.forHtmlAttribute(userStoreDomain)%>"/>
                                        </div>
                                        <%
                                            }
                                        %>

                                        <%
                                            if (!IdentityTenantUtil.isTenantQualifiedUrlsEnabled() && tenantDomain != null) {
                                        %>
                                        <div>
                                            <input type="hidden" name="tenantdomain" value="<%=Encode.forHtmlAttribute(tenantDomain) %>"/>
                                        </div>
                                        <%
                                            }
                                        %>

                                        <%
                                            if (type != null) {
                                        %>
                                        <div>
                                            <input type="hidden" name="type" value="<%=Encode.forHtmlAttribute(type) %>"/>
                                        </div>
                                        <%
                                            }
                                        %>

                                        <div class="pu-form__container">
                                            <img class="pu-form__icon" src="./images/icon-login.svg" alt="" aria-hidden="true">
                                            <input
                                                class="pu-form__input"
                                                id="confirm-password"
                                                name="confirm-password"
                                                type="password"
                                                data-match="reset-password"
                                                required=""
                                                placeholder="<%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "Confirm.password")%>"
                                            />
                                            <i id="confirmPasswordShowHide" class="eye link icon slash"
                                            onclick="confirmPasswordShowToggle()"></i>
                                        </div>
                                        <div class="ui divider hidden"></div>

                                        <div class="pu-form__actions center">
                                            <button id="submit"
                                                    class="pu-btn pu-btn--primary"
                                                    type="submit"><%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                                                    "Proceed")%>
                                            </button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="pu-login__decorative" aria-hidden="true">
                        <img class="pu-login__decorative__one" src="./images/decorative/ilu-3.svg" alt="">
                        <img class="pu-login__decorative__two" src="./images/decorative/ilu-4.svg" alt="">
                        <img class="pu-login__decorative__three" src="./images/decorative/repeat-grid-19.svg" alt="">
                        <img class="pu-login__decorative__four" src="./images/decorative/repeat-grid-64.svg" alt="">
                    </div>
                </main>
            </layout:component>
            <layout:component componentName="ProductFooter" >
                <%-- product-footer --%>
                <%
                    File productFooterFile = new File(getServletContext().getRealPath("extensions/przyjazny-urzad-product-footer.jsp"));
                    if (productFooterFile.exists()) {
                %>
                <jsp:include page="extensions/przyjazny-urzad-product-footer.jsp"/>
                <% } else { %>
                <jsp:include page="includes/product-footer.jsp"/>
                <% } %>
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

        <script type="text/javascript">
            $(document).ready(function () {

                $("#passwordResetForm").submit(function (e) {

                    $("#server-error-msg").remove();
                    var password = $("#reset-password").val();
                    var password2 = $("#confirm-password").val();
                    var error_msg = $("#error-msg");

                    if (!password || 0 === password.length) {
                        error_msg.text("<%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                        "Password.cannot.be.empty")%>");
                        error_msg.show();
                        $("html, body").animate({scrollTop: error_msg.offset().top}, 'slow');
                        return false;
                    }

                    if (password !== password2) {
                        error_msg.text("<%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle,
                        "Passwords.did.not.match.please.try.again")%>");
                        error_msg.show();
                        $("html, body").animate({scrollTop: error_msg.offset().top}, 'slow');
                        return false;
                    }

                    return true;
                });
            });

            var password1 = true;
            var password2 = true;

            function passwordShowToggle(){
                if(password1) {
                    password1 = false;
                    document.getElementById("passwordShowHide").classList.remove("slash");
                    document.getElementById("reset-password").setAttribute("type","text");
                } else{
                    password1 = true;
                    document.getElementById("passwordShowHide").classList.add("slash");
                    document.getElementById("reset-password").setAttribute("type","password");
                }
            }

            function confirmPasswordShowToggle(){
                if(password2) {
                    password2 = false;
                    document.getElementById("confirmPasswordShowHide").classList.remove("slash");
                    document.getElementById("confirm-password").setAttribute("type","text");
                } else{
                    password2 = true;
                    document.getElementById("confirmPasswordShowHide").classList.add("slash");
                    document.getElementById("confirm-password").setAttribute("type","password");
                }
            }
        </script>
    </body>
</html>
