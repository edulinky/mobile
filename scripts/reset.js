/**
 * Resets the app's *activity* data, keeping accounts.
 *
 *   cd scripts && npm run reset
 *
 * DELETES:
 *   matches/            (and every messages/ sub-collection)
 *   swipes/             (and every sent/ sub-collection)
 *   swipeQuotas/
 *   notifications/      (and every items/ sub-collection)
 *
 * KEEPS:
 *   Firebase Authentication users  — untouched
 *   users/                         — untouched (profiles, photos, verification)
 *   config/                        — untouched (admin quota overrides)
 *   Storage                        — untouched (avatars, galleries, certificates)
 *
 * The point is to get back to "these people exist but nothing has happened yet",
 * so you can re-run a swipe → match → chat flow without re-registering.
 *
 * Requires an explicit --yes to run: this is irreversible.
 */
const {db, projectId} = require("./_admin");

const COLLECTIONS = [
  // Sub-collections must be named: deleting a document does NOT delete its
  // sub-collections in Firestore — they become orphaned and invisible, but they
  // still exist and still cost money.
  {name: "matches", subcollections: ["messages"]},
  {name: "swipes", subcollections: ["sent"]},
  {name: "swipeQuotas", subcollections: []},
  {name: "notifications", subcollections: ["items"]},
];

const BATCH_SIZE = 400;

async function deleteQueryBatch(query) {
  let deleted = 0;
  for (;;) {
    const snap = await query.limit(BATCH_SIZE).get();
    if (snap.empty) return deleted;

    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    deleted += snap.size;

    if (snap.size < BATCH_SIZE) return deleted;
  }
}

async function deleteCollection({name, subcollections}) {
  let docs = 0;
  let subDocs = 0;

  const snap = await db.collection(name).get();
  for (const doc of snap.docs) {
    for (const sub of subcollections) {
      subDocs += await deleteQueryBatch(doc.ref.collection(sub));
    }
  }
  docs = await deleteQueryBatch(db.collection(name));

  return {docs, subDocs};
}

async function main() {
  if (!process.argv.includes("--yes")) {
    console.error(`
⚠  This deletes ALL matches, messages, swipes, quotas and notifications
   in project "${projectId}". It cannot be undone.

   Accounts, profiles and Storage are NOT touched.

   Re-run with --yes to confirm:

       npm run reset -- --yes
`);
    process.exit(1);
  }

  console.log(`Resetting activity data in "${projectId}"…\n`);

  for (const c of COLLECTIONS) {
    const {docs, subDocs} = await deleteCollection(c);
    const sub = c.subcollections.length > 0 ?
      ` (+ ${subDocs} in ${c.subcollections.join("/")})` :
      "";
    console.log(`  ${c.name.padEnd(16)} ${docs} deleted${sub}`);
  }

  console.log(`
✓ Done. Accounts, profiles, verification status and Storage are intact.
  Every user is back to zero swipes, zero matches, zero notifications.
`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
