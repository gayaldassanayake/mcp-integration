CREATE TABLE IF NOT EXISTS customers (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    tier TEXT NOT NULL
);

INSERT INTO customers (id, name, tier) VALUES
    (1, 'Ada Lovelace', 'gold'),
    (2, 'Grace Hopper', 'silver'),
    (3, 'Linus Torvalds', 'bronze'),
    (4, 'Katherine Johnson', 'gold'),
    (5, 'Alan Turing', 'platinum'),
    (6, 'Margaret Hamilton', 'gold'),
    (7, 'Barbara Liskov', 'silver')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    tier = EXCLUDED.tier;
