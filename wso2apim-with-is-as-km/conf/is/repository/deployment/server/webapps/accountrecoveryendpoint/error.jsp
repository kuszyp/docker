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

<%@ page isErrorPage="true" %>
<%@ page import="org.apache.commons.lang.StringUtils" %>
<%@ page import="org.wso2.carbon.identity.event.IdentityEventException" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointUtil" %>
<%@ page import="org.wso2.carbon.identity.recovery.IdentityRecoveryConstants" %>
<%@ page import="org.wso2.carbon.identity.recovery.util.Utils" %>
<%@ page import="org.owasp.encoder.Encode" %>
<%@ page import="java.io.File" %>
<%@ page import="java.net.URISyntaxException" %>
<%@ taglib prefix="layout" uri="org.wso2.identity.apps.taglibs.layout.controller" %>
<jsp:directive.include file="includes/localize.jsp"/>
<jsp:directive.include file="includes/layout-resolver.jsp"/>

<%
    String errorMsg = IdentityManagementEndpointUtil.getStringValue(request.getAttribute("errorMsg"));
    String errorCode = IdentityManagementEndpointUtil.getStringValue(request.getAttribute("errorCode"));
    String invalidConfirmationErrorCode = IdentityRecoveryConstants.ErrorMessages.ERROR_CODE_INVALID_CODE.getCode();
    String callback = request.getParameter("callback");
    boolean isValidCallback = true;

    if (invalidConfirmationErrorCode.equals(errorCode)) {
        String tenantDomain = StringUtils.EMPTY;
        if (StringUtils.isNotBlank(request.getParameter("tenantdomain"))){
            tenantDomain = request.getParameter("tenantdomain").trim();
        } else if (StringUtils.isNotBlank(request.getParameter("tenantDomain"))){
            tenantDomain = request.getParameter("tenantDomain").trim();
        }
        try {
            if (StringUtils.isNotBlank(callback) && !Utils.validateCallbackURL
                (callback, tenantDomain, IdentityRecoveryConstants.ConnectorConfig.RECOVERY_CALLBACK_REGEX)) {
                    isValidCallback = false;
                }
        } catch (IdentityEventException e) {
            isValidCallback = false;
        }
    }

    try {
        IdentityManagementEndpointUtil.getURLEncodedCallback(callback);
    } catch (URISyntaxException e) {
        isValidCallback = false;
    }
    if (StringUtils.isBlank(errorMsg)) {
        errorMsg = IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "Server.failed.to.respond");
    }
%>

<%-- Data for the layout from the page --%>
<%
    layoutData.put("containerSize", "large");
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
</head>
<body class="login-portal layout recovery-layout not-found__body">
    <layout:main layoutName="<%= layout %>" layoutFileRelativePath="<%= layoutFileRelativePath %>" data="<%= layoutData %>" >
        <layout:component componentName="MainSection" >
            <div class="not-found">
                <div class="not-found__wrapper">

                    <% if (IdentityRecoveryConstants.ErrorMessages.ERROR_CODE_INVALID_CODE.getCode().equals(errorCode)) { %>
                        <h1 class="not-found__title"><%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "Invalid.activation.link")%>!</h1>
                    <% } else { %>
                        <h1 class="not-found__title"><%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "error")%>!</h1>
                    <%  } %>
                    <div class="not-found__description">
                        <%
                            if (IdentityRecoveryConstants.ErrorMessages.ERROR_CODE_INVALID_CODE.getCode().equals(errorCode)) {
                        %>
                        <p><%=IdentityManagementEndpointUtil.i18n(recoveryResourceBundle, "Invalid.activation.link.description")%></p>
                        <%  } else { %>
                        <p><%=IdentityManagementEndpointUtil.i18nBase64(recoveryResourceBundle, errorMsg)%></p>
                        <% } %>
                    </div>

                    <% if (IdentityRecoveryConstants.ErrorMessages.ERROR_CODE_INVALID_CODE.getCode().equals(errorCode)) { %>
                    <div class="bot_found__button">
                        <a href="https://test-portal.pm.bydgoszcz.pl/" class="pu-btn pu-btn--primary">
                            <%=IdentityManagementEndpointUtil.i18nBase64(recoveryResourceBundle, "label.startAgain")%>
                        </a>
                    </div>
                    <% } %>

                </div>
                <div class="not-found__decorative">
                    <img
                        alt=""
                        loading="lazy"
                        width="542"
                        height="233"
                        decoding="async"
                        data-nimg="1"
                        class="not-found__decorative__one"
                        style="color: transparent"
                        src="./images/decorative/illu-bledy-1.svg"
                    />
                    <img
                        alt=""
                        loading="lazy"
                        width="601"
                        height="313"
                        decoding="async"
                        data-nimg="1"
                        class="not-found__decorative__two"
                        style="color: transparent"
                        src="./images/decorative/illu-bledy-2.svg"
                    />
                </div>
            </div>
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
</body>
</html>
