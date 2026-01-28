<?php
require_once 'database.php';

function getGreeting() {
    return "Hello World!";
}

function getDatabaseInfo() {
    try {
        $db = new DatabaseConnection();

        $writeHost = getenv('DB_HOST') ?: 'db';
        $readHost = getenv('DB_READ_HOST') ?: $writeHost;

        $appInfo = $db->fetchOne("SELECT * FROM app_info ORDER BY created_at DESC LIMIT 1");

        $replicationStatus = $db->getReplicationStatus();

        $healthCheck = $db->fetchOne("SELECT * FROM health_check ORDER BY checked_at DESC LIMIT 1");

        return [
            'write_host' => $writeHost,
            'read_host' => $readHost,
            'app_version' => $appInfo['version'] ?? 'Unknown',
            'environment' => $appInfo['environment'] ?? 'Unknown',
            'health_status' => $healthCheck['status'] ?? 'Unknown',
            'replication' => $replicationStatus,
            'using_replica' => $writeHost !== $readHost
        ];
    } catch (Exception $e) {
        return [
            'error' => $e->getMessage(),
            'write_host' => $writeHost ?? 'unknown',
            'read_host' => $readHost ?? 'unknown',
            'using_replica' => false
        ];
    }
}

if (!defined('PHPUNIT_COMPOSER_INSTALL') && !defined('__PHPUNIT_PHAR__')) {
    $greeting = getGreeting();
    $dbInfo = getDatabaseInfo();
} else {
    $greeting = '';
    $dbInfo = [];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Hello World with Read Replica</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
        }
        .container {
            text-align: center;
            padding: 2rem;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            max-width: 600px;
        }
        h1 {
            color: #333;
            margin: 0 0 20px 0;
        }
        .info-grid {
            display: grid;
            grid-template-columns: auto auto;
            gap: 10px;
            text-align: left;
            margin: 20px 0;
            padding: 20px;
            background: #f5f5f5;
            border-radius: 5px;
        }
        .info-label {
            font-weight: bold;
            color: #555;
        }
        .info-value {
            color: #333;
        }
        .status-indicator {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            margin-right: 5px;
        }
        .status-ok {
            background-color: #4CAF50;
        }
        .status-warning {
            background-color: #FF9800;
        }
        .status-error {
            background-color: #f44336;
        }
        .replica-status {
            margin-top: 20px;
            padding: 15px;
            border-radius: 5px;
        }
        .replica-active {
            background-color: #e8f5e9;
            border: 1px solid #4CAF50;
        }
        .replica-inactive {
            background-color: #fff3e0;
            border: 1px solid #FF9800;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1><?php echo htmlspecialchars($greeting); ?></h1>
        <p>This is a dockerized PHP application with MySQL read replica support</p>

        <?php if (isset($dbInfo['error'])): ?>
            <div class="info-grid">
                <div class="info-label">Status:</div>
                <div class="info-value">
                    <span class="status-indicator status-error"></span>
                    Database connection error
                </div>
                <div class="info-label">Error:</div>
                <div class="info-value"><?php echo htmlspecialchars($dbInfo['error']); ?></div>
            </div>
        <?php else: ?>
            <div class="info-grid">
                <div class="info-label">Environment:</div>
                <div class="info-value"><?php echo htmlspecialchars($dbInfo['environment']); ?></div>

                <div class="info-label">App Version:</div>
                <div class="info-value"><?php echo htmlspecialchars($dbInfo['app_version']); ?></div>

                <div class="info-label">Write Host:</div>
                <div class="info-value"><?php echo htmlspecialchars($dbInfo['write_host']); ?></div>

                <div class="info-label">Read Host:</div>
                <div class="info-value"><?php echo htmlspecialchars($dbInfo['read_host']); ?></div>

                <div class="info-label">Health Status:</div>
                <div class="info-value">
                    <span class="status-indicator <?php echo $dbInfo['health_status'] === 'healthy' ? 'status-ok' : 'status-warning'; ?>"></span>
                    <?php echo htmlspecialchars($dbInfo['health_status']); ?>
                </div>
            </div>

            <div class="replica-status <?php echo $dbInfo['using_replica'] ? 'replica-active' : 'replica-inactive'; ?>">
                <h3>Replication Status</h3>
                <?php if ($dbInfo['using_replica']): ?>
                    <p><strong>Read Replica: ENABLED</strong></p>
                    <?php if ($dbInfo['replication']['is_running']): ?>
                        <p>
                            <span class="status-indicator status-ok"></span>
                            Replication is running
                        </p>
                        <?php if ($dbInfo['replication']['lag'] !== null): ?>
                            <p>Replication lag: <?php echo htmlspecialchars($dbInfo['replication']['lag']); ?> seconds</p>
                        <?php endif; ?>
                    <?php else: ?>
                        <p>
                            <span class="status-indicator status-warning"></span>
                            Checking replication status...
                        </p>
                    <?php endif; ?>
                <?php else: ?>
                    <p><strong>Read Replica: NOT CONFIGURED</strong></p>
                    <p>All queries are using the primary database</p>
                <?php endif; ?>
            </div>
        <?php endif; ?>
    </div>
</body>
</html>