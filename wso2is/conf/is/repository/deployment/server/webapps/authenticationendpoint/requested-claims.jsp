<%--
  ~ Copyright (c) 2014, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~ WSO2 Inc. licenses this file to you under the Apache License,
  ~ Version 2.0 (the "License"); you may not use this file except
  ~ in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied.  See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
  --%>

<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.Constants" %>
<%@ page import="org.owasp.encoder.Encode" %>
<%@ page import="java.io.File" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="layout" uri="org.wso2.identity.apps.taglibs.layout.controller" %>

<%@ include file="includes/localize.jsp" %>
<%@ include file="includes/init-url.jsp" %>
<jsp:directive.include file="includes/layout-resolver.jsp"/>

<%
    String[] missingClaimList = null;
    String appName = null;
    Boolean isFederated = false;
    if (request.getParameter(Constants.MISSING_CLAIMS) != null) {
        missingClaimList = request.getParameter(Constants.MISSING_CLAIMS).split(",");
    }
    if (request.getParameter(Constants.REQUEST_PARAM_SP) != null) {
        appName = request.getParameter(Constants.REQUEST_PARAM_SP);
    }
%>

<%-- Data for the layout from the page --%>
<%
    layoutData.put("containerSize", "medium");
%>

<!doctype html>
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

    <script src="libs/addons/calendar.min.js"></script>
    <link rel="stylesheet" href="libs/addons/calendar.min.css"/>
</head>

<body class="login-portal layout authentication-portal-layout">

<% if (new File(getServletContext().getRealPath("extensions/timeout.jsp")).exists()) { %>
<jsp:include page="extensions/timeout.jsp"/>
<% } else { %>
<jsp:include page="util/timeout.jsp"/>
<% } %>

<layout:main layoutName="<%= layout %>" layoutFileRelativePath="<%= layoutFileRelativePath %>" data="<%= layoutData %>">
    <layout:component componentName="ProductHeader">
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
                    <h2 class="pu-login__title" data-testid="request-claims-page-mandatory-header-text">
                        <%=AuthenticationEndpointUtil.i18n(resourceBundle, "mobile.page.title")%>
                    </h2>

                    <% if (request.getParameter("errorMessage") != null) { %>
                    <div class="ui visible negative message" id="error-msg"
                         data-testid="request-claims-page-error-message">
                        <%= AuthenticationEndpointUtil.i18n(resourceBundle, request.getParameter("errorMessage")) %>
                    </div>
                    <% }%>

                    <form class="ui large form" action="<%=commonauthURL%>" method="post" id="claimForm">
                        <div class="ui divider hidden"></div>
                        <p data-testid="request-claims-page-recommendation">
                            <%=AuthenticationEndpointUtil.i18n(resourceBundle, "mobile.page.description")%>
                        </p>

                        <div class="pu-login__segment-form">
                            <div class="pu-form">
                                <% for (String claim : missingClaimList) {
                                    String claimDisplayName = claim;
                                    claimDisplayName = claimDisplayName.replaceAll(".*/", "");
                                    claimDisplayName = claimDisplayName.substring(0, 1).toUpperCase() + claimDisplayName.substring(1);
                                    if (claim.contains("claims/dob")) {
                                        claimDisplayName = "Date of Birth (YYYY-MM-DD)";
                                    }
                                %>
<%--                                Usunac label ponizej jezeli nie chcemy miec napisu mobile ale tez usuniemy do innych claimow--%>
                                <!-- <label class="pu-form__label"        
                                       for="claim_mand_<%=Encode.forHtmlAttribute(claim)%>"
                                       data-testid="request-claims-page-form-field-<%=Encode.forHtmlAttribute(claim)%>-label">
                                    <% if (StringUtils.isNotBlank(claimDisplayName)) { %>
                                    <%=Encode.forHtmlAttribute(claimDisplayName)%>
                                    <% } else { %>
                                    <%=Encode.forHtmlAttribute(claim)%>
                                    <% } %>
                                </label> -->
                                <% if (claim.contains("claims/dob")) { %>
                                    <div class="ui calendar" id="date_picker">
                                        <div class="ui input left icon" style="width: 100%;">
                                            <i class="calendar icon"></i>
                                            <input type="text"
                                                   autocomplete="off"
                                                   data-testid="request-claims-page-form-field-claim-<%=Encode.forHtmlAttribute(claim)%>-input"
                                                   id="claim_mand_<%=Encode.forHtmlAttribute(claim)%>"
                                                   name="claim_mand_<%=Encode.forHtmlAttribute(claim)%>"
                                                   placeholder="Wpisz <%=Encode.forHtmlContent(claimDisplayName)%>"
                                                   required="required">
                                        </div>
                                    </div>
                                <% } else if (claim.contains("claims/country")) { %>
                                    <jsp:include page="includes/country-dropdown.jsp">
                                        <jsp:param name="required" value="required"/>
                                        <jsp:param name="claim" value="<%=Encode.forHtmlAttribute(claim)%>"/>
                                    </jsp:include>
                                <% } else if (claim.contains("claims/mobile")) { %>
                                <input class="pu-form__input pu-form__input--margin"
                                       type="text"
                                       autocomplete="off"
                                       data-testid="request-claims-page-form-field-claim-<%=Encode.forHtmlAttribute(claim)%>-input"
                                       name="claim_mand_<%=Encode.forHtmlAttribute(claim)%>"
                                       id="claim_mand_<%=Encode.forHtmlAttribute(claim)%>"
                                       placeholder="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "claim.mobile")%>"
                                       required="required"/>
                                <% } else if (claim.contains("claims/emailaddress")) { %>
                                <input class="pu-form__input"
                                       type="text"
                                       autocomplete="off"
                                       data-testid="request-claims-page-form-field-claim-<%=Encode.forHtmlAttribute(claim)%>-input"
                                       name="claim_mand_<%=Encode.forHtmlAttribute(claim)%>"
                                       id="claim_mand_<%=Encode.forHtmlAttribute(claim)%>"
                                       placeholder="<%=AuthenticationEndpointUtil.i18n(resourceBundle, "claim.emailaddress")%>"
                                       required="required"/>
                                <% } else { %>
                                    <input class="pu-form__input"
                                           type="text"
                                           autocomplete="off"
                                           data-testid="request-claims-page-form-field-claim-<%=Encode.forHtmlAttribute(claim)%>-input"
                                           name="claim_mand_<%=Encode.forHtmlAttribute(claim)%>"
                                           id="claim_mand_<%=Encode.forHtmlAttribute(claim)%>"
                                           placeholder="Wpisz <%=Encode.forHtmlContent(claimDisplayName)%>"
                                           required="required"/>
                                <% } %>
                                <% } %>
                                <input type="hidden"
                                       name="sessionDataKey"
                                       data-testid="request-claims-page-session-data-key"
                                       value='<%=Encode.forHtmlAttribute(request.getParameter("sessionDataKey"))%>'/>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
            <div class="pu-login__action">
                <button class="pu-btn pu-btn--primary"
                        type="submit"
                        form="claimForm"
                        data-testid="request-claims-page-continue-button">
                    <%=AuthenticationEndpointUtil.i18n(resourceBundle, "mobile.page.continue")%>
                </button>
            </div>

            <div class="pu-login__decorative" aria-hidden="true">
                <img class="pu-login__decorative__one" src="./images/decorative/ilu-1.svg" alt="">
                <img class="pu-login__decorative__two" src="./images/decorative/ilu-2.svg" alt="">
                <img class="pu-login__decorative__three" src="./images/decorative/repeat-grid-18.svg" alt="">
                <img class="pu-login__decorative__four" src="./images/decorative/repeat-grid-63.svg" alt="">
            </div>
        </div>
    </layout:component>
<%--    <layout:component componentName="ProductFooter">--%>
<%--        &lt;%&ndash; product-footer &ndash;%&gt;--%>
<%--        <%--%>
<%--            File productFooterFile = new File(getServletContext().getRealPath("extensions/product-footer.jsp"));--%>
<%--            if (productFooterFile.exists()) {--%>
<%--        %>--%>
<%--        <jsp:include page="extensions/product-footer.jsp"/>--%>
<%--        <% } else { %>--%>
<%--        <jsp:include page="includes/product-footer.jsp"/>--%>
<%--        <% } %>--%>
<%--    </layout:component>--%>
</layout:main>

<%--&lt;%&ndash; footer &ndash;%&gt;--%>
<%--<%--%>
<%--    File footerFile = new File(getServletContext().getRealPath("extensions/footer.jsp"));--%>
<%--    if (footerFile.exists()) {--%>
<%--%>--%>
<%--<jsp:include page="extensions/footer.jsp"/>--%>
<%--<% } else { %>--%>
<%--<jsp:include page="includes/footer.jsp"/>--%>
<%--<% } %>--%>

<script defer>
    /**
     * Event handler and trigger for #date_picker element.
     * This is a extension we've added to facilitate a ui
     * calendar for Semantic-UI. The extension files are
     * added manually to lib/ directory of authentication
     * portal. calendar.min.js and calendar.min.css.
     *
     * If you do want to change these settings in the future
     * refer [1] since this API is not officially merged to
     * Semantic-UI.
     *
     * [1] https://github.com/mdehoog/Semantic-UI-Calendar#settings
     */
    $("#date_picker").calendar({
        type: 'date',
        formatter: {
            date: function (date, settings) {
                var EMPTY_STRING = "";
                var DATE_SEPARATOR = "-";
                var STRING_ZERO = "0";
                if (!date) return EMPTY_STRING;
                var day = date.getDate() + EMPTY_STRING;
                if (day.length < 2) {
                    day = STRING_ZERO + day;
                }
                var month = (date.getMonth() + 1) + EMPTY_STRING;
                if (month.length < 2) {
                    month = STRING_ZERO + month;
                }
                var year = date.getFullYear();
                return year + DATE_SEPARATOR + month + DATE_SEPARATOR + day;
            }
        }
    });
</script>

</body>
</html>
