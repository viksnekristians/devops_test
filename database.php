<?php
class DatabaseConnection {
    private $writeConnection;
    private $readConnection;

    public function __construct() {
        $this->initializeConnections();
    }

    private function initializeConnections() {
        $dbHost = getenv('DB_HOST') ?: 'db';
        $dbReadHost = getenv('DB_READ_HOST') ?: $dbHost;
        $dbName = getenv('DB_NAME') ?: 'myapp';
        $dbUser = getenv('DB_USER') ?: 'appuser';
        $dbPassword = getenv('DB_PASSWORD') ?: 'apppassword';
        $dbPort = getenv('DB_PORT') ?: '3306';

        try {
            $this->writeConnection = new PDO(
                "mysql:host=$dbHost;port=$dbPort;dbname=$dbName",
                $dbUser,
                $dbPassword,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );

            $this->readConnection = new PDO(
                "mysql:host=$dbReadHost;port=$dbPort;dbname=$dbName",
                $dbUser,
                $dbPassword,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );
        } catch (PDOException $e) {
            error_log("Connection failed: " . $e->getMessage());
            $this->readConnection = $this->writeConnection;
        }
    }

    public function getWriteConnection() {
        return $this->writeConnection;
    }

    public function getReadConnection() {
        return $this->readConnection;
    }

    public function query($sql, $params = [], $useWrite = false) {
        $connection = $useWrite ? $this->writeConnection : $this->readConnection;

        try {
            $stmt = $connection->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch (PDOException $e) {
            error_log("Query failed: " . $e->getMessage());
            throw $e;
        }
    }

    public function fetchAll($sql, $params = []) {
        $stmt = $this->query($sql, $params, false);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function fetchOne($sql, $params = []) {
        $stmt = $this->query($sql, $params, false);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function execute($sql, $params = []) {
        return $this->query($sql, $params, true);
    }

    public function getReplicationStatus() {
        try {
            $stmt = $this->readConnection->query("SHOW SLAVE STATUS");
            $status = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($status) {
                return [
                    'is_replica' => true,
                    'is_running' => $status['Slave_IO_Running'] === 'Yes' && $status['Slave_SQL_Running'] === 'Yes',
                    'lag' => $status['Seconds_Behind_Master'],
                    'master_host' => $status['Master_Host']
                ];
            }

            return [
                'is_replica' => false,
                'is_running' => false,
                'lag' => null,
                'master_host' => null
            ];
        } catch (PDOException $e) {
            return [
                'is_replica' => false,
                'is_running' => false,
                'lag' => null,
                'master_host' => null,
                'error' => $e->getMessage()
            ];
        }
    }
}