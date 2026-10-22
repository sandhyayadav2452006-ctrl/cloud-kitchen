package com.tastenest.servlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import com.tastenest.util.DB;

@WebServlet("/orders")
public class OrdersServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        try {
            DB.init();
            Object role = req.getSession().getAttribute("role");
            Object userId = req.getSession().getAttribute("userId");
            boolean admin = "ADMIN".equals(role) || "true".equals(req.getParameter("all"));
            String sql = admin
                ? "SELECT o.id,o.total_amount,o.address,o.payment_method,o.status,o.created_at,u.name FROM orders o LEFT JOIN users u ON u.id=o.user_id ORDER BY o.id DESC LIMIT 50"
                : "SELECT o.id,o.total_amount,o.address,o.payment_method,o.status,o.created_at,u.name FROM orders o LEFT JOIN users u ON u.id=o.user_id WHERE o.user_id=? ORDER BY o.id DESC LIMIT 30";
            Connection c = DB.get();
            try {
                PreparedStatement ps = c.prepareStatement(sql);
                try {
                    if (!admin) ps.setObject(1, userId);
                    ResultSet rs = ps.executeQuery();
                    try {
                        StringBuilder b = new StringBuilder("[");
                        boolean first = true;
                        while (rs.next()) {
                            if (!first) b.append(','); first=false;
                            b.append("{\"id\":"+rs.getInt(1)+",\"name\":\""+esc(rs.getString(7))+"\",\"total\":"+rs.getBigDecimal(2)+",\"address\":\""+esc(rs.getString(3))+"\",\"payment\":\""+esc(rs.getString(4))+"\",\"status\":\""+esc(rs.getString(5))+"\"}");
                        }
                        b.append(']');
                        resp.getWriter().print(b);
                    } finally { rs.close(); }
                } finally { ps.close(); }
            } finally { c.close(); }
        } catch (Exception e) {
            resp.setStatus(500);
            resp.getWriter().print("[]");
        }
    }
    private String esc(String s) { return s==null ? "" : s.replace("\\","\\\\").replace("\"","\\\""); }
}
