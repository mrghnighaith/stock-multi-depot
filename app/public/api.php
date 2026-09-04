<?php
session_start();
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');

function getPDO(): PDO {
    $host = getenv('DB_HOST') ?: 'db';
    $db   = getenv('DB_NAME') ?: 'stock_multi_depot';
    $user = getenv('DB_USER') ?: 'stock_user';
    $pass = getenv('DB_PASSWORD') ?: 'stock_pass';
    $dsn  = "mysql:host=$host;dbname=$db;charset=utf8mb4";
    return new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
}

function getRedis(): ?Redis {
    // Redis extension not installed - temporarily disabled
    return null;
    
    /* try {
        $redis = new Redis();
        $redis->connect(getenv('REDIS_HOST') ?: 'redis', (int)(getenv('REDIS_PORT') ?: 6379));
        return $redis;
    } catch (Exception $e) {
        return null;
    } */
}

function isLoggedIn(): bool {
    return !empty($_SESSION['user_id']);
}

function requireAuth(): void {
    if (!isLoggedIn()) {
        http_response_code(401);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Authentification requise']);
        exit;
    }
}

$module = $_GET['module'] ?? '';
$action = $_GET['action'] ?? '';

// CSV export needs different headers than the JSON default — handle it before
// the generic JSON header is sent, and before entering the try block.
if ($module === 'export' && $action === 'csv') {
    requireAuth();

    try {
        $pdo = getPDO();
        $sql = "SELECT d.nom AS depot, p.reference, p.nom AS produit, p.categorie,
                       s.quantite, p.seuil_alerte
                FROM stocks s
                JOIN depots d ON d.id = s.depot_id
                JOIN produits p ON p.id = s.produit_id
                ORDER BY d.nom, p.nom";
        $stmt = $pdo->query($sql);
        $rows = $stmt->fetchAll();

        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="inventaire_' . date('Y-m-d') . '.csv"');

        $out = fopen('php://output', 'w');
        fputcsv($out, ['Depot', 'Reference', 'Produit', 'Categorie', 'Quantite', 'Seuil alerte', 'Statut']);
        foreach ($rows as $r) {
            $statut = $r['quantite'] <= $r['seuil_alerte'] ? 'STOCK BAS' : 'OK';
            fputcsv($out, [$r['depot'], $r['reference'], $r['produit'], $r['categorie'], $r['quantite'], $r['seuil_alerte'], $statut]);
        }
        fclose($out);
        exit;
    } catch (Exception $e) {
        http_response_code(500);
        header('Content-Type: application/json');
        echo json_encode(['error' => $e->getMessage()]);
        exit;
    }
}

header('Content-Type: application/json');

try {
    $pdo = getPDO();

    if ($module === 'auth' && $action === 'login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);
        $username = trim($data['username'] ?? '');
        $password = $data['password'] ?? '';

        if ($username === '' || $password === '') {
            http_response_code(400);
            echo json_encode(['error' => 'Identifiants requis']);
            exit;
        }

        $stmt = $pdo->prepare("SELECT id, username, password_hash FROM users WHERE username = ?");
        $stmt->execute([$username]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            http_response_code(401);
            echo json_encode(['error' => 'Identifiants incorrects']);
            exit;
        }

        session_regenerate_id(true);
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];

        echo json_encode(['success' => true, 'username' => $user['username']]);
        exit;
    }

    if ($module === 'auth' && $action === 'logout') {
        $_SESSION = [];
        session_destroy();
        echo json_encode(['success' => true]);
        exit;
    }

    if ($module === 'auth' && $action === 'check') {
        echo json_encode([
            'logged_in' => isLoggedIn(),
            'username' => $_SESSION['username'] ?? null,
        ]);
        exit;
    }

    if ($module === 'depots' && $action === 'list') {
        $stmt = $pdo->query("SELECT * FROM depots ORDER BY nom");
        echo json_encode($stmt->fetchAll());
        exit;
    }

    if ($module === 'stocks' && $action === 'overview') {
        $redis = getRedis();
        $cacheKey = 'stocks:overview';

        if ($redis) {
            $cached = $redis->get($cacheKey);
            if ($cached !== false) {
                echo $cached;
                exit;
            }
        }

        $sql = "SELECT d.id AS depot_id, d.nom AS depot_nom, d.ville,
                       p.id AS produit_id, p.reference, p.nom AS produit_nom,
                       p.categorie, p.seuil_alerte, s.quantite
                FROM stocks s
                JOIN depots d ON d.id = s.depot_id
                JOIN produits p ON p.id = s.produit_id
                ORDER BY d.nom, p.nom";
        $stmt = $pdo->query($sql);
        $result = json_encode($stmt->fetchAll());

        if ($redis) {
            $redis->setex($cacheKey, 10, $result);
        }

        echo $result;
        exit;
    }

    if ($module === 'stocks' && $action === 'alerts') {
        $sql = "SELECT d.id AS depot_id, d.nom AS depot_nom,
                       p.id AS produit_id, p.reference, p.nom AS produit_nom,
                       s.quantite, p.seuil_alerte
                FROM stocks s
                JOIN depots d ON d.id = s.depot_id
                JOIN produits p ON p.id = s.produit_id
                WHERE s.quantite <= p.seuil_alerte
                ORDER BY (p.seuil_alerte - s.quantite) DESC";
        $stmt = $pdo->query($sql);
        echo json_encode($stmt->fetchAll());
        exit;
    }

    if ($module === 'transferts' && $action === 'create' && $_SERVER['REQUEST_METHOD'] === 'POST') {
        requireAuth();

        $data = json_decode(file_get_contents('php://input'), true);
        $produit_id = (int)($data['produit_id'] ?? 0);
        $source     = (int)($data['depot_source'] ?? 0);
        $dest       = (int)($data['depot_dest'] ?? 0);
        $qte        = (int)($data['quantite'] ?? 0);

        if (!$produit_id || !$source || !$dest || $qte <= 0 || $source === $dest) {
            http_response_code(400);
            echo json_encode(['error' => 'Parametres invalides']);
            exit;
        }

        $pdo->beginTransaction();

        $check = $pdo->prepare("SELECT quantite FROM stocks WHERE depot_id = ? AND produit_id = ?");
        $check->execute([$source, $produit_id]);
        $row = $check->fetch();

        if (!$row || $row['quantite'] < $qte) {
            $pdo->rollBack();
            http_response_code(400);
            echo json_encode(['error' => 'Stock insuffisant au depot source']);
            exit;
        }

        $pdo->prepare("UPDATE stocks SET quantite = quantite - ? WHERE depot_id = ? AND produit_id = ?")
            ->execute([$qte, $source, $produit_id]);

        $pdo->prepare("INSERT INTO stocks (depot_id, produit_id, quantite) VALUES (?, ?, ?)
                        ON DUPLICATE KEY UPDATE quantite = quantite + VALUES(quantite)")
            ->execute([$dest, $produit_id, $qte]);

        $pdo->prepare("INSERT INTO transferts (produit_id, depot_source, depot_dest, quantite, statut) VALUES (?, ?, ?, ?, 'valide')")
            ->execute([$produit_id, $source, $dest, $qte]);

        $pdo->commit();

        $redis = getRedis();
        if ($redis) {
            $redis->del('stocks:overview');
        }

        echo json_encode(['success' => true]);
        exit;
    }

    if ($module === 'transferts' && $action === 'list') {
        $sql = "SELECT t.id, p.nom AS produit, ds.nom AS source, dd.nom AS destination,
                       t.quantite, t.date_transfert, t.statut
                FROM transferts t
                JOIN produits p ON p.id = t.produit_id
                JOIN depots ds ON ds.id = t.depot_source
                JOIN depots dd ON dd.id = t.depot_dest
                ORDER BY t.date_transfert DESC LIMIT 50";
        $stmt = $pdo->query($sql);
        echo json_encode($stmt->fetchAll());
        exit;
    }

    http_response_code(404);
    echo json_encode(['error' => 'Route inconnue']);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
