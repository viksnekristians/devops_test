-- Initialize database schema
CREATE TABLE IF NOT EXISTS app_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(50),
    environment VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial data
INSERT INTO app_info (version, environment) VALUES ('1.0.0', 'development');

-- Create health check table
CREATE TABLE IF NOT EXISTS health_check (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(20),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO health_check (status) VALUES ('healthy');