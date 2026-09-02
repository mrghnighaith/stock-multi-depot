CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users (username, password_hash) VALUES
('admin', '$2b$10$y.x1ZECSPA/qfPhQmcLSyOwBLsMja5BdOof/Vj51kbTUqHq6X1IBS');