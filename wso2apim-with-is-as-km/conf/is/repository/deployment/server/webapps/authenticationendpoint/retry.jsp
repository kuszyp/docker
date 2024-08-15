<%--
  ~ Copyright (c) 2014, WSO2 LLC. (https://www.wso2.com) All Rights Reserved.
  ~
  ~ WSO2 LLC. licenses this file to you under the Apache License,
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

<%@ page import="org.owasp.encoder.Encode" %>
<%@ page import="java.io.File" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.AuthContextAPIClient" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.client.model.AuthenticationRequestWrapper" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.Constants" %>
<%@ page import="org.wso2.carbon.identity.core.util.IdentityUtil" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.ApplicationDataRetrievalClient" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.client.ApplicationDataRetrievalClientException" %>
<%@ page import="java.util.regex.Pattern" %>
<%@ page import="java.util.Map" %>
<%@ page import="org.wso2.carbon.identity.mgt.endpoint.util.IdentityManagementEndpointUtil" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="layout" uri="org.wso2.identity.apps.taglibs.layout.controller" %>

<%@ include file="includes/localize.jsp" %>
<%@include file="includes/init-url.jsp" %>
<jsp:directive.include file="includes/layout-resolver.jsp"/>

<%!
    private static final String SERVER_AUTH_URL = "/api/identity/auth/v1.1/";
    private static final String DATA_AUTH_ERROR_URL = "data/AuthenticationError/";
    private static final String REQUEST_PARAM_ERROR_KEY = "errorKey";
%>
<%
    String stat = request.getParameter(Constants.STATUS);
    String statusMessage = request.getParameter(Constants.STATUS_MSG);
    String sp = request.getParameter("sp");
    String applicationAccessURLWithoutEncoding = null;

    String errorKey = request.getParameter(REQUEST_PARAM_ERROR_KEY);
    String statAuthParam = null;
    String statusMsgAuthParam = null;

    if (StringUtils.isNotEmpty(errorKey)) {
        AuthenticationRequestWrapper authRequest = (AuthenticationRequestWrapper) request;
        statAuthParam = authRequest.getAuthParameter(Constants.STATUS);
        statusMsgAuthParam = authRequest.getAuthParameter(Constants.STATUS_MSG);
    }

    // If auth params are available, can skip i18n mapping validations. This is to allow displaying
    // custom error messages.
    if (StringUtils.isNotEmpty(statAuthParam) || StringUtils.isNotEmpty(statusMsgAuthParam)) {
        stat = statAuthParam;
        statusMessage = statusMsgAuthParam;
        if (StringUtils.isNotEmpty(stat)) {
            stat = AuthenticationEndpointUtil.customi18n(resourceBundle, stat);
        }
        if (StringUtils.isNotEmpty(statusMessage)) {
            statusMessage = AuthenticationEndpointUtil.customi18n(resourceBundle, statusMessage);
        }
    } else if (StringUtils.isNotEmpty(stat) || StringUtils.isNotEmpty(statusMessage)) {
        String i18nErrorMapping = AuthenticationEndpointUtil.getErrorCodeToi18nMapping(stat, statusMessage);
        if (Constants.ErrorToi18nMappingConstants.INCORRECT_ERROR_MAPPING_KEY.equals(i18nErrorMapping)) {
            stat = AuthenticationEndpointUtil.i18n(resourceBundle, "authentication.error");
            statusMessage = AuthenticationEndpointUtil.i18n(resourceBundle, 
                    "something.went.wrong.during.authentication");
        } else {
            if (StringUtils.isNotEmpty(stat)) {
                stat = AuthenticationEndpointUtil.customi18n(resourceBundle, stat);
            }
            if (StringUtils.isNotEmpty(statusMessage)) {
                statusMessage = AuthenticationEndpointUtil.customi18n(resourceBundle, statusMessage);
            }
        }
    }

    if (StringUtils.isEmpty(stat)) {
        stat = AuthenticationEndpointUtil.i18n(resourceBundle, "authentication.error");
    }
    if (StringUtils.isEmpty(statusMessage)) {
        statusMessage = AuthenticationEndpointUtil.i18n(resourceBundle,
                "something.went.wrong.during.authentication");
    }
    session.invalidate();

    try {
        ApplicationDataRetrievalClient applicationDataRetrievalClient = new ApplicationDataRetrievalClient();
        applicationAccessURLWithoutEncoding = applicationDataRetrievalClient.getApplicationAccessURL(tenantDomain,
                sp);
        applicationAccessURLWithoutEncoding = IdentityManagementEndpointUtil.replaceUserTenantHintPlaceholder(
                                                                applicationAccessURLWithoutEncoding, userTenantDomain);
    } catch (ApplicationDataRetrievalClientException e) {
        // Ignored and fallback to login page url.
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
</head>
<body class="login-portal layout authentication-portal-layout not-found__body">
    <layout:main layoutName="<%= layout %>" layoutFileRelativePath="<%= layoutFileRelativePath %>" data="<%= layoutData %>" >
        <layout:component componentName="ProductHeader" >
            <!-- <%-- product-title --%>
            <%
                File productTitleFile = new File(getServletContext().getRealPath("extensions/product-title.jsp"));
                if (productTitleFile.exists()) {
            %>
                <jsp:include page="extensions/product-title.jsp"/>
            <% } else { %>
                <jsp:include page="includes/product-title.jsp"/>
            <% } %> -->
        </layout:component>
        <layout:component componentName="MainSection" >
            <div class="not-found">
                <div class="not-found__wrapper">
                    <h1 class="not-found__title"><%=Encode.forHtmlContent(stat)%></h1>
                    <div class="not-found__description">
                        <%
                        String[] sentences = statusMessage.split("\\.\\s");
                        int numOfSentences = sentences.length;
                        if (numOfSentences > 0 && !sentences[numOfSentences - 1].endsWith(".")) {
                            numOfSentences--;
                        }
                        for (int i = 0; i < numOfSentences; i++) {
                            String sentence = sentences[i];
                            %>
                            <p><%= Encode.forHtmlContent(sentence.trim() + (i < numOfSentences - 1 ? "." : "")) %></p>
                            <%
                        }
                        %>
                    </div>
                    <% if (StringUtils.isNotBlank(applicationAccessURLWithoutEncoding)) { %>
                        <a href="<%= IdentityManagementEndpointUtil.getURLEncodedCallback(applicationAccessURLWithoutEncoding)%>" class="pu-btn pu-btn--primary pu-btn--big">Spróbuj od nowa</a>
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
        <layout:component componentName="ProductFooter" >
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
</body>
</html>
