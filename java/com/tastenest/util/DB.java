package com.tastenest.util;
import java.sql.*;
public class DB {
 private static final String URL="jdbc:mysql://localhost:3306/tastenest?createDatabaseIfNotExist=true&serverTimezone=Asia/Kolkata&allowPublicKeyRetrieval=true&useSSL=false";
 private static final String USER="root", PASS="";
 static { try { Class.forName("com.mysql.cj.jdbc.Driver"); init(); } catch(Exception e){ e.printStackTrace(); } }
 public static Connection get() throws SQLException { return DriverManager.getConnection(URL,USER,PASS); }
 public static void init() throws SQLException {
  try(Connection c=DriverManager.getConnection("jdbc:mysql://localhost:3306/?serverTimezone=Asia/Kolkata&allowPublicKeyRetrieval=true&useSSL=false",USER,PASS); Statement s=c.createStatement()) { s.executeUpdate("CREATE DATABASE IF NOT EXISTS tastenest"); }
  try(Connection c=get(); Statement s=c.createStatement()) {
   s.executeUpdate("CREATE TABLE IF NOT EXISTS users(id INT AUTO_INCREMENT PRIMARY KEY,name VARCHAR(100),mobile VARCHAR(20),email VARCHAR(120) UNIQUE,password VARCHAR(255),role VARCHAR(20) DEFAULT 'CUSTOMER')");
   s.executeUpdate("CREATE TABLE IF NOT EXISTS menu_items(id INT AUTO_INCREMENT PRIMARY KEY,name VARCHAR(100),description VARCHAR(255),price DECIMAL(10,2),category VARCHAR(50),available BOOLEAN DEFAULT TRUE)");
   s.executeUpdate("CREATE TABLE IF NOT EXISTS orders(id INT AUTO_INCREMENT PRIMARY KEY,user_id INT,total_amount DECIMAL(10,2),address VARCHAR(255),payment_method VARCHAR(30),status VARCHAR(30) DEFAULT 'ORDER PLACED',created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
   s.executeUpdate("CREATE TABLE IF NOT EXISTS order_items(id INT AUTO_INCREMENT PRIMARY KEY,order_id INT,menu_item_id INT,quantity INT,price DECIMAL(10,2))");
   s.executeUpdate("CREATE TABLE IF NOT EXISTS feedback(id INT AUTO_INCREMENT PRIMARY KEY,order_id INT,user_id INT,rating INT,comment VARCHAR(500),created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
   ResultSet r=s.executeQuery("SELECT COUNT(*) FROM menu_items"); r.next(); if(r.getInt(1)==0){
    s.executeUpdate("INSERT INTO menu_items(name,description,price,category) VALUES ('Veg Thali','Dal, seasonal sabzi, roti, rice and salad',100,'Thali'),('Paneer Rice Bowl','Paneer curry with jeera rice and salad',130,'Rice Bowls'),('Meal Combo','Main course, rice, roti and a side',150,'Combos')"); }
  }
 }
}
