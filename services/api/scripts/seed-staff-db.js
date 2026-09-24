#!/usr/bin/env node
// Made by Dr Ali — seed per-branch temp desk staff via DB (bypasses HTTP rate limits).
// Privilege = Employee role only. Desk title / branch are display placeholders.
// Passwords documented on Desktop ACCOUNT-DEV-STAFF.txt — not committed.

const bcrypt = require('bcrypt');
const { Client } = require('pg');

const DATABASE_URL =
  process.env.DATABASE_URL ||
  'postgresql://obic:obic_local_dev_only@localhost:5432/obic';

// Form2 order — Yiwu primary, Shanghai added.
const BRANCHES = ['Yiwu', 'Guangzhou', 'Foshan', 'Hangzhou', 'Hainan', 'Yemen', 'Shanghai'];
const DESKS = [
  { key: 'marketing', title: 'Marketing Manager', suf: 'Mkt' },
  { key: 'marketer', title: 'Marketer', suf: 'Mkr' },
  { key: 'dataentry', title: 'Data Entry', suf: 'Data' },
  { key: 'branchmgr', title: 'Branch Manager', suf: 'BrMgr' },
  { key: 'finance', title: 'Finance', suf: 'Fin' },
  { key: 'secretary', title: 'Secretary', suf: 'Sec' },
  { key: 'cashier', title: 'Cashier', suf: 'Cash' },
  { key: 'scholarships', title: 'Scholarships Desk', suf: 'Schol' },
];

const BCRYPT_ROUNDS = 12;

async function upsert(client, { email, password, name, role, staffTitle, branchLabel }) {
  const hash = await bcrypt.hash(password, BCRYPT_ROUNDS);
  const r = await client.query(
    `INSERT INTO users (email, phone, password_hash, role, name, staff_title, branch_label, avatar_url, created_at, updated_at)
     VALUES ($1, NULL, $2, $3::users_role_enum, $4, $5, $6, NULL, NOW(), NOW())
     ON CONFLICT (email) DO UPDATE SET
       password_hash = EXCLUDED.password_hash,
       role = EXCLUDED.role,
       name = EXCLUDED.name,
       staff_title = EXCLUDED.staff_title,
       branch_label = EXCLUDED.branch_label,
       updated_at = NOW()
     RETURNING email, role, staff_title, branch_label`,
    [email, hash, role, name, staffTitle, branchLabel],
  );
  return r.rows[0];
}

async function main() {
  const client = new Client({ connectionString: DATABASE_URL });
  await client.connect();

  console.log('Seeding core…');
  await upsert(client, {
    email: 'admin@obic.local',
    password: 'AdminObic2026!',
    name: 'OBIC Super Admin',
    role: 'SuperAdmin',
    staffTitle: 'Head of Administration',
    branchLabel: 'All branches',
  });
  await upsert(client, {
    email: 'staff@obic.local',
    password: 'StaffObic2026!',
    name: 'OBIC Employee',
    role: 'Employee',
    staffTitle: 'General Employee',
    branchLabel: 'HQ (temp)',
  });
  await client.query(
    `UPDATE users SET offers_access = true, ops_access = true WHERE email = 'staff@obic.local'`,
  );
  await client.query(
    `UPDATE users SET offers_access = true WHERE email IN (
      'temp.guangzhou.marketing@obic.local',
      'temp.yiwu.marketing@obic.local'
    )`,
  );
  await upsert(client, {
    email: 'ali@obic.local',
    password: 'AliObic2026!',
    name: 'Dr Ali',
    role: 'Customer',
    staffTitle: null,
    branchLabel: null,
  });

  console.log('Seeding per-branch desks…');
  let n = 0;
  for (const branch of BRANCHES) {
    const slug = branch.toLowerCase();
    for (const desk of DESKS) {
      const email = `temp.${slug}.${desk.key}@obic.local`;
      const password = `TempObic2026!${branch}-${desk.suf}`;
      const name = `Temp ${desk.title} — ${branch}`;
      await upsert(client, {
        email,
        password,
        name,
        role: 'Employee',
        staffTitle: desk.title,
        branchLabel: branch,
      });
      n += 1;
    }
  }

  const count = await client.query(
    `SELECT COUNT(*)::int AS c FROM users WHERE email LIKE 'temp.%.%@obic.local'`,
  );
  console.log(`Upserted ${n} desk accounts. DB temp desks: ${count.rows[0].c}`);
  const sample = await client.query(
    `SELECT branch_label, COUNT(*)::int AS desks
     FROM users WHERE email LIKE 'temp.%.%@obic.local'
     GROUP BY branch_label ORDER BY branch_label`,
  );
  console.table(sample.rows);
  await client.end();
  console.log('Done. Credentials: ~/Desktop/obic/deliverables/ACCOUNT-DEV-STAFF.txt');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
