/**
 * Grants the `admin` role to a user.
 *
 *   cd scripts && node make-admin.js someone@example.com
 *
 * There is a deliberate chicken-and-egg here: `setRole` is admin-only, and
 * "admin" is not in APP_ROLES so it can never be chosen at registration. The
 * FIRST admin therefore has to be created out-of-band, with the service-account
 * key — which is exactly the property you want. An admin can approve teachers,
 * ban users, and read identity documents; it must not be self-service.
 */
const {auth, db, projectId} = require("./_admin");

async function main() {
  const email = process.argv[2];
  const password = process.argv[3];
  if (!email) {
    console.error("Usage: node make-admin.js <email> [password]");
    console.error("  password is required only if the account does not exist yet");
    process.exit(1);
  }

  let user;
  let created = false;
  try {
    user = await auth.getUserByEmail(email);
  } catch {
    if (!password) {
      console.error(
        `\n✗ No account exists for ${email}.\n` +
          `  To create one, pass a password:\n` +
          `      node make-admin.js ${email} '<password>'\n`
      );
      process.exit(1);
    }
    user = await auth.createUser({email, password, emailVerified: true});
    created = true;
  }

  await auth.setCustomUserClaims(user.uid, {role: "admin"});
  await db.collection("users").doc(user.uid).set(
    {uid: user.uid, email, role: "admin", is_banned: false},
    {merge: true}
  );

  console.log(`
✓ ${email} is now an admin in "${projectId}".${created ? " (new account created)" : ""}
  uid: ${user.uid}

  They must sign OUT and back IN — the role lives in the ID token, which is
  only refreshed on a new sign-in (or after an hour).
`);
}

main().catch((e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
