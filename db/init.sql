DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS customers;

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    company TEXT NOT NULL,
    tier TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE support_tickets (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX support_tickets_updated_at_idx ON support_tickets (updated_at);
CREATE INDEX customers_updated_at_idx ON customers (updated_at);

CREATE TRIGGER customers_set_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER support_tickets_set_updated_at BEFORE UPDATE ON support_tickets
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO customers (name, email, company, tier, created_at, updated_at) VALUES
    ('Ada Lovelace', 'ada@analytical.io', 'Analytical Engines Ltd', 'gold', now() - interval '60 days', now() - interval '60 days'),
    ('Grace Hopper', 'grace@cobol.dev', 'Compiler Works', 'silver', now() - interval '57 days', now() - interval '57 days'),
    ('Linus Torvalds', 'linus@kernel.example', 'Kernel Co', 'bronze', now() - interval '54 days', now() - interval '54 days'),
    ('Katherine Johnson', 'katherine@orbit.example', 'Orbit Dynamics', 'gold', now() - interval '51 days', now() - interval '51 days'),
    ('Alan Turing', 'alan@bletchley.example', 'Bletchley Systems', 'platinum', now() - interval '48 days', now() - interval '48 days'),
    ('Margaret Hamilton', 'margaret@apollo.example', 'Apollo Software', 'gold', now() - interval '45 days', now() - interval '45 days'),
    ('Barbara Liskov', 'barbara@clu.example', 'Abstraction Labs', 'silver', now() - interval '42 days', now() - interval '42 days'),
    ('Donald Knuth', 'don@taocp.example', 'Literate Press', 'platinum', now() - interval '39 days', now() - interval '39 days'),
    ('Edsger Dijkstra', 'edsger@paths.example', 'Shortest Path BV', 'bronze', now() - interval '36 days', now() - interval '36 days'),
    ('Frances Allen', 'frances@opt.example', 'Optimizing Compilers Inc', 'gold', now() - interval '33 days', now() - interval '33 days'),
    ('John Backus', 'john@fortran.example', 'Formula Translation', 'silver', now() - interval '30 days', now() - interval '30 days'),
    ('Radia Perlman', 'radia@stp.example', 'Spanning Tree Networks', 'gold', now() - interval '27 days', now() - interval '27 days'),
    ('Ken Thompson', 'ken@unix.example', 'Bell Systems', 'silver', now() - interval '24 days', now() - interval '24 days'),
    ('Hedy Lamarr', 'hedy@spread.example', 'Frequency Hopping Co', 'platinum', now() - interval '21 days', now() - interval '21 days'),
    ('Tim Berners-Lee', 'tim@web.example', 'Hypertext Partners', 'bronze', now() - interval '18 days', now() - interval '18 days');

INSERT INTO support_tickets (customer_id, subject, body, status, priority, created_at, updated_at) VALUES
    (6, 'Cannot log in after password reset', 'After resetting my password yesterday, the login page says my credentials are invalid. I have tried three times and cleared my browser cache.', 'resolved', 'low', now() - interval '30 days 4 hours', now() - interval '30 days'),
    (2, 'Invoice shows wrong currency', 'Our October invoice was issued in USD but our contract is in EUR. Please reissue the invoice in the correct currency.', 'open', 'high', now() - interval '29 days 17 hours', now() - interval '29 days'),
    (10, 'API rate limit too low', 'We are hitting 429 responses at around 50 requests per second. Our plan should allow 200 rps. Can you check the configured limit?', 'closed', 'medium', now() - interval '28 days 1 hours', now() - interval '28 days'),
    (1, 'Export to CSV truncates rows', 'Exporting the orders report to CSV stops at 10,000 rows even though the report has 14,322 rows.', 'resolved', 'urgent', now() - interval '27 days 2 hours', now() - interval '27 days'),
    (2, 'Webhook deliveries delayed', 'Webhook events for order.created are arriving 10 to 15 minutes late since Monday.', 'open', 'urgent', now() - interval '26 days 7 hours', now() - interval '26 days'),
    (1, 'Request to add SSO via Okta', 'We would like to enable SAML single sign-on with Okta for our 120 users. What are the steps?', 'open', 'medium', now() - interval '25 days 18 hours', now() - interval '25 days'),
    (11, 'Dashboard loads slowly', 'The analytics dashboard takes more than 30 seconds to load for the last-90-days view.', 'closed', 'low', now() - interval '24 days 20 hours', now() - interval '24 days'),
    (10, 'Duplicate charges on card', 'We were charged twice for the November subscription. Please refund the duplicate charge.', 'resolved', 'low', now() - interval '23 days 18 hours', now() - interval '23 days'),
    (4, 'Mobile app crashes on startup', 'The iOS app crashes immediately after the splash screen on iOS 19.1.', 'closed', 'medium', now() - interval '22 days 1 hours', now() - interval '22 days'),
    (5, 'Need audit log retention extended', 'Compliance requires us to retain audit logs for 2 years. Current retention is 90 days.', 'open', 'low', now() - interval '21 days 13 hours', now() - interval '21 days'),
    (10, 'Search returns stale results', 'Products updated an hour ago still show old prices in search results.', 'closed', 'medium', now() - interval '20 days 9 hours', now() - interval '20 days'),
    (2, 'Cannot add new team member', 'Inviting a new user fails with ''seat limit reached'' but we have 5 unused seats.', 'closed', 'medium', now() - interval '19 days 18 hours', now() - interval '19 days'),
    (6, 'Data residency question', 'Is our data stored in the EU region? Our legal team needs confirmation for GDPR.', 'closed', 'low', now() - interval '18 days 3 hours', now() - interval '18 days'),
    (10, 'Scheduled report not sent', 'The weekly sales report scheduled for Monday 9am was not emailed to the distribution list.', 'closed', 'medium', now() - interval '17 days 1 hours', now() - interval '17 days'),
    (8, 'Integration with Salesforce failing', 'The Salesforce sync job fails with ''INVALID_SESSION_ID'' every night.', 'closed', 'urgent', now() - interval '16 days 21 hours', now() - interval '16 days'),
    (13, 'Feature request: dark mode', 'Several of our agents work night shifts and would like a dark theme in the console.', 'resolved', 'urgent', now() - interval '15 days 10 hours', now() - interval '15 days'),
    (6, 'Two-factor codes not arriving', 'SMS two-factor codes are not being delivered to numbers in Sri Lanka.', 'open', 'medium', now() - interval '14 days 9 hours', now() - interval '14 days'),
    (12, 'Upgrade plan pricing', 'We want to move from the Pro plan to Enterprise. Please send a quote for 300 seats.', 'open', 'high', now() - interval '13 days 7 hours', now() - interval '13 days'),
    (9, 'Bulk import timing out', 'Importing a 50MB customer CSV times out after 60 seconds with a 504 error.', 'in_progress', 'urgent', now() - interval '12 days 15 hours', now() - interval '12 days'),
    (5, 'Timezone wrong on reports', 'All report timestamps are shown in UTC even though the account timezone is set to Asia/Colombo.', 'open', 'low', now() - interval '11 days 19 hours', now() - interval '11 days'),
    (9, 'Password policy too strict', 'Users complain the 20-character minimum is too strict. Can we lower it to 14?', 'open', 'high', now() - interval '10 days 13 hours', now() - interval '10 days'),
    (3, 'Unable to delete archived project', 'Deleting an archived project returns ''resource locked'' even though nobody is using it.', 'resolved', 'low', now() - interval '9 days 15 hours', now() - interval '9 days'),
    (11, 'Email notifications going to spam', 'Notification emails from your domain are landing in spam for Gmail users. Is DKIM configured?', 'closed', 'high', now() - interval '8 days 2 hours', now() - interval '8 days'),
    (6, 'API returns 500 on pagination', 'GET /v2/orders?page=40 returns HTTP 500. Earlier pages work fine.', 'in_progress', 'urgent', now() - interval '7 days 22 hours', now() - interval '7 days'),
    (10, 'Request for sandbox environment', 'We need a sandbox tenant to test the new billing integration before going live.', 'open', 'low', now() - interval '6 days 14 hours', now() - interval '6 days'),
    (5, 'Contract renewal reminder', 'Our contract renews next month. We want to discuss adding the analytics add-on.', 'open', 'low', now() - interval '5 days 15 hours', now() - interval '5 days'),
    (12, 'Chart colors not accessible', 'Red and green status colors in charts are hard to distinguish for colour-blind users.', 'in_progress', 'urgent', now() - interval '4 days 22 hours', now() - interval '4 days'),
    (5, 'Slow response from support chat', 'Live chat wait times have been over 40 minutes this week.', 'resolved', 'high', now() - interval '3 days 22 hours', now() - interval '3 days'),
    (1, 'Missing data after migration', 'After the database migration on Saturday, orders between 02:00 and 02:30 UTC are missing.', 'in_progress', 'medium', now() - interval '2 days 14 hours', now() - interval '2 days'),
    (10, 'Token expiry too short', 'OAuth access tokens expire after 5 minutes, causing frequent re-authentication in our batch jobs.', 'resolved', 'low', now() - interval '1 days 3 hours', now() - interval '1 days');
