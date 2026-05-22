-- ================================================
--   Sales Analysis System
--   Author  : Prabhgun Kaur Bindra
--   Date    : 2026-05-22
--   Tool    : MySQL (CUI)
-- ================================================


-- STEP 1: Create & Select Database
CREATE DATABASE sales_db;
USE sales_db;


-- STEP 2: Create Tables

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    city        VARCHAR(50),
    joined_date DATE DEFAULT (CURDATE())
);

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    category   VARCHAR(50),
    price      DECIMAL(10,2) NOT NULL,
    stock      INT DEFAULT 0
);

CREATE TABLE orders (
    order_id    INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_date  DATE DEFAULT (CURDATE()),
    status      ENUM('pending','completed','cancelled') DEFAULT 'pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    item_id    INT AUTO_INCREMENT PRIMARY KEY,
    order_id   INT,
    product_id INT,
    quantity   INT NOT NULL,
    price      DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id   INT AUTO_INCREMENT PRIMARY KEY,
    order_id     INT,
    amount       DECIMAL(10,2),
    payment_date DATE DEFAULT (CURDATE()),
    method       ENUM('cash','card','upi') DEFAULT 'cash',
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- STEP 3: Insert Sample Data

INSERT INTO customers (name, email, city) VALUES
('Rahul Sharma', 'rahul@email.com', 'Delhi'),
('Priya Singh',  'priya@email.com', 'Mumbai'),
('Amit Kumar',   'amit@email.com',  'Bangalore'),
('Sneha Gupta',  'sneha@email.com', 'Chennai'),
('Rohan Verma',  'rohan@email.com', 'Hyderabad');

INSERT INTO products (name, category, price, stock) VALUES
('Laptop',       'Electronics', 55000.00, 50),
('Mobile Phone', 'Electronics', 20000.00, 100),
('Headphones',   'Electronics',  2000.00, 200),
('Desk Chair',   'Furniture',    8000.00,  30),
('Notebook',     'Stationery',    100.00, 500);

INSERT INTO orders (customer_id, order_date, status) VALUES
(1, '2024-01-15', 'completed'),
(2, '2024-02-20', 'completed'),
(3, '2024-03-10', 'completed'),
(4, '2024-04-05', 'pending'),
(5, '2024-05-18', 'cancelled');

INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
(1, 1, 1, 55000.00),
(1, 3, 2,  2000.00),
(2, 2, 1, 20000.00),
(3, 4, 1,  8000.00),
(4, 5, 5,   100.00),
(5, 3, 1,  2000.00);

INSERT INTO payments (order_id, amount, payment_date, method) VALUES
(1, 59000.00, '2024-01-15', 'card'),
(2, 20000.00, '2024-02-20', 'upi'),
(3,  8000.00, '2024-03-10', 'cash');


-- STEP 4: Analysis Queries

SELECT SUM(amount) AS total_revenue
FROM payments;

SELECT c.name, SUM(p.amount) AS total_spent
FROM payments p
JOIN orders o    ON p.order_id    = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.name
ORDER BY total_spent DESC;

SELECT p.name, SUM(oi.quantity) AS total_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY total_sold DESC;

SELECT p.category, SUM(oi.quantity * oi.price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

SELECT MONTHNAME(payment_date) AS month,
       MONTH(payment_date)     AS month_num,
       SUM(amount)             AS monthly_revenue
FROM payments
GROUP BY MONTHNAME(payment_date), MONTH(payment_date)
ORDER BY month_num;


-- STEP 5: Create View

CREATE VIEW sales_summary AS
SELECT c.name  AS customer,
       o.order_date,
       o.status,
       SUM(oi.quantity * oi.price) AS order_value
FROM orders o
JOIN customers   c  ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
GROUP BY c.name, o.order_date, o.status;

SELECT * FROM sales_summary;


-- STEP 6: Create Trigger

DELIMITER //
CREATE TRIGGER update_stock
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE product_id = NEW.product_id;
END //
DELIMITER ;

SELECT name, stock FROM products WHERE product_id = 1;

INSERT INTO order_items (order_id, product_id, quantity, price)
VALUES (3, 1, 2, 55000.00);

SELECT name, stock FROM products WHERE product_id = 1;


-- STEP 7: Create Stored Procedure

DELIMITER //
CREATE PROCEDURE place_order(
    IN p_customer_id INT,
    IN p_product_id  INT,
    IN p_quantity    INT
)
BEGIN
    DECLARE v_price    DECIMAL(10,2);
    DECLARE v_order_id INT;

    SELECT price INTO v_price
    FROM products
    WHERE product_id = p_product_id;

    INSERT INTO orders (customer_id, status)
    VALUES (p_customer_id, 'pending');

    SET v_order_id = LAST_INSERT_ID();

    INSERT INTO order_items (order_id, product_id, quantity, price)
    VALUES (v_order_id, p_product_id, p_quantity, v_price);

END //
DELIMITER ;

CALL place_order(2, 3, 2);

SELECT * FROM orders;
SELECT * FROM order_items;
SELECT name, stock FROM products WHERE product_id = 3;

-- ================================================
-- END OF PROJECT
-- ================================================