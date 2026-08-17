CREATE TABLE IF NOT EXISTS depots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    ville VARCHAR(100) NOT NULL,
    capacite INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS produits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reference VARCHAR(50) NOT NULL UNIQUE,
    nom VARCHAR(150) NOT NULL,
    categorie VARCHAR(100),
    seuil_alerte INT NOT NULL DEFAULT 10
);

CREATE TABLE IF NOT EXISTS stocks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    depot_id INT NOT NULL,
    produit_id INT NOT NULL,
    quantite INT NOT NULL DEFAULT 0,
    FOREIGN KEY (depot_id) REFERENCES depots(id) ON DELETE CASCADE,
    FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE,
    UNIQUE KEY uniq_stock (depot_id, produit_id)
);

CREATE TABLE IF NOT EXISTS transferts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    produit_id INT NOT NULL,
    depot_source INT NOT NULL,
    depot_dest INT NOT NULL,
    quantite INT NOT NULL,
    date_transfert DATETIME DEFAULT CURRENT_TIMESTAMP,
    statut ENUM('en_attente','valide','annule') DEFAULT 'en_attente',
    FOREIGN KEY (produit_id) REFERENCES produits(id),
    FOREIGN KEY (depot_source) REFERENCES depots(id),
    FOREIGN KEY (depot_dest) REFERENCES depots(id)
);

-- Seed data
INSERT INTO depots (nom, ville, capacite) VALUES
('Depot Nord', 'Bizerte', 5000),
('Depot Centre', 'Tunis', 8000),
('Depot Sud', 'Sfax', 4000);

INSERT INTO produits (reference, nom, categorie, seuil_alerte) VALUES
('PRD-001', 'Palette bois standard', 'Emballage', 50),
('PRD-002', 'Carton ondule 40x60', 'Emballage', 100),
('PRD-003', 'Film etirable', 'Emballage', 30);

INSERT INTO stocks (depot_id, produit_id, quantite) VALUES
(1, 1, 120), (1, 2, 45), (1, 3, 200),
(2, 1, 300), (2, 2, 500), (2, 3, 80),
(3, 1, 20), (3, 2, 60), (3, 3, 15);
