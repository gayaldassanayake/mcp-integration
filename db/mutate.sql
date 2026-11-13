INSERT INTO customers (name, email, company, tier)
VALUES ('Sophie Wilson', 'sophie-' || floor(extract(epoch FROM now()))::bigint || '@arm.example', 'Acorn RISC', 'gold')
RETURNING id, name, updated_at;

INSERT INTO support_tickets (customer_id, subject, body, status, priority)
VALUES
    ((SELECT max(id) FROM customers), 'Onboarding call request',
     'We just signed up and would like a 30 minute onboarding call this week.', 'open', 'medium'),
    (1, 'Login issue again after SSO rollout',
     'Since SSO was enabled yesterday some users are redirected back to the login page in a loop.', 'open', 'high')
RETURNING id, customer_id, subject, updated_at;

UPDATE support_tickets SET status = 'resolved'
WHERE id = (SELECT min(id) FROM support_tickets WHERE status IN ('open', 'in_progress'))
RETURNING id, subject, status, updated_at;

UPDATE support_tickets SET priority = 'urgent', body = body || ' Update: this is now blocking our month-end close.'
WHERE id = 2
RETURNING id, subject, priority, updated_at;

UPDATE customers SET tier = 'platinum' WHERE id = 2
RETURNING id, name, tier, updated_at;
