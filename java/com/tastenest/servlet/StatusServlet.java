package com.tastenest.servlet;
import jakarta.servlet.*; import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.*;import java.sql.*;import com.tastenest.util.DB;
@WebServlet("/status")
public class StatusServlet extends HttpServlet{protected void doPost(HttpServletRequest q,HttpServletResponse r)throws IOException{try{DB.init();int id=Integer.parseInt(q.getParameter("id"));String st=q.getParameter("status");try(Connection c=DB.get();PreparedStatement p=c.prepareStatement("UPDATE orders SET status=? WHERE id=?")){p.setString(1,st);p.setInt(2,id);p.executeUpdate();}r.setContentType("application/json");r.getWriter().print("{\"ok\":true}");}catch(Exception e){r.setStatus(500);r.getWriter().print("{\"ok\":false}");}}}
