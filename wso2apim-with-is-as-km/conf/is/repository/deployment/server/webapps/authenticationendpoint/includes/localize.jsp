<%--
  ~ Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~ WSO2 Inc. licenses this file to you under the Apache License,
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

<%@ page import="java.util.ResourceBundle" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.AuthenticationEndpointUtil" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.EncodedControl" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.util.Locale" %>
<%@page contentType="text/html; charset=UTF-8"%>
<%
    String BUNDLE = "org.wso2.carbon.identity.application.authentication.endpoint.i18n.Resources";

    String languageCode = "pl";
    String countryCode = "PL";

    Cookie[] cookies = request.getCookies();

    if (cookies != null) {
        for (Cookie cookie : cookies) {
            String cookieName = cookie.getName();
            if (cookieName.equals("lang")){
                String cookieValue = cookie.getValue();
                if (cookieValue != null && !cookieValue.isEmpty()) {
                    languageCode = cookieValue.equals("pl") ? "pl" : "en";
                    countryCode = cookieValue.equals("pl") ? "PL" : "GB";
                }
            }
        }
    }

    Locale locale = new Locale(languageCode, countryCode);
    ResourceBundle resourceBundle = ResourceBundle.getBundle(BUNDLE, locale, new
            EncodedControl(StandardCharsets.UTF_8.toString()));
%>
