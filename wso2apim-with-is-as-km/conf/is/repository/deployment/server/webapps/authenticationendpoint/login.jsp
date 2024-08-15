<%
    String sp = request.getParameter("sp");
    if (sp.equals("portal-mieszkanca")) {
        RequestDispatcher dispatcher = request.getRequestDispatcher("przyjazny-urzad-login.jsp");
        dispatcher.forward(request, response);
    } else if (sp.equals("portal-administracyjny")) {
        RequestDispatcher dispatcher = request.getRequestDispatcher("przyjazny-urzad-login-2.jsp");
        dispatcher.forward(request, response);
    } else if (sp.equals("biuro")) {
        RequestDispatcher dispatcher = request.getRequestDispatcher("przyjazny-urzad-login-2.jsp");
        dispatcher.forward(request, response);
    } else if (sp.equals("kreator")) {
        RequestDispatcher dispatcher = request.getRequestDispatcher("przyjazny-urzad-login.jsp");
        dispatcher.forward(request, response);
    } else {
        RequestDispatcher dispatcher = request.getRequestDispatcher("default_login.jsp");
        dispatcher.forward(request, response);
    }
%>
