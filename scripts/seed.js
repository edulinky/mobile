/**
 * Seeds 5 teachers + 5 students for testing.
 *
 *   cd scripts && npm install && npm run seed
 *
 * All accounts sit in the Linz / Upper Austria area, deliberately: discovery has
 * a 50 km default radius, so seeding people in Vienna and Innsbruck would give
 * you empty decks and look like a bug. Everyone here is within ~40 km of
 * everyone else, so every student sees every teacher and vice versa.
 *
 * Teachers are created **approved** (`verified_status: "approved"`), because an
 * unapproved teacher is not discoverable and cannot swipe — you would have to
 * hand-approve all five in the console before testing anything.
 *
 * Re-running is safe: existing accounts are updated in place, not duplicated.
 */
const {geohashForLocation} = require("geofire-common");
const {admin, db, auth} = require("./_admin");

const PASSWORD = "Test1234!";

// Real coordinates — the geohash is derived from them, so discovery distances
// come out right.
const CITIES = {
  linz: {city: "Linz, Austria", lat: 48.3069, lng: 14.2858},
  ansfelden: {city: "Ansfelden, Austria", lat: 48.2094, lng: 14.2894},
  wels: {city: "Wels, Austria", lat: 48.1575, lng: 14.0289},
  steyr: {city: "Steyr, Austria", lat: 48.0388, lng: 14.4192},
  traun: {city: "Traun, Austria", lat: 48.2203, lng: 14.2372},
  leonding: {city: "Leonding, Austria", lat: 48.2833, lng: 14.2500},
  enns: {city: "Enns, Austria", lat: 48.2167, lng: 14.4667},
  perg: {city: "Perg, Austria", lat: 48.2500, lng: 14.6333},
};

const TEACHERS = [
  {
    email: "teacher1@edulinky.test",
    displayName: "Anna Gruber",
    city: CITIES.linz,
    primarySubject: "Mathematics",
    subjects: ["Mathematics", "Physics"],
    about: "Maths and physics teacher with 8 years in secondary education. I make hard ideas feel simple.",
    hourlyRate: 35,
    qualifications: ["MSc Mathematics — JKU Linz", "Teaching Diploma"],
    experience: [
      {title: "Mathematics Teacher", institution: "BRG Linz", from: "2018", to: "Present"},
    ],
    availability: {Mon: ["Morning", "Afternoon"], Wed: ["Afternoon"], Fri: ["Evening"]},
    featured: true,
  },
  {
    email: "teacher2@edulinky.test",
    displayName: "Markus Huber",
    city: CITIES.wels,
    primarySubject: "English",
    subjects: ["English", "Literature"],
    about: "English teacher and translator. Exam prep, conversation, and writing.",
    hourlyRate: 30,
    qualifications: ["BA English — University of Vienna"],
    experience: [
      {title: "English Teacher", institution: "HAK Wels", from: "2016", to: "Present"},
    ],
    availability: {Tue: ["Morning"], Thu: ["Afternoon", "Evening"]},
  },
  {
    email: "teacher3@edulinky.test",
    displayName: "Lena Bauer",
    city: CITIES.steyr,
    primarySubject: "Chemistry",
    subjects: ["Chemistry", "Biology"],
    about: "Science tutor. Lab-first teaching — we build the intuition before the formulas.",
    hourlyRate: 32,
    qualifications: ["MSc Chemistry — TU Graz"],
    experience: [
      {title: "Science Teacher", institution: "Gymnasium Steyr", from: "2019", to: "Present"},
    ],
    availability: {Mon: ["Evening"], Wed: ["Morning", "Afternoon"], Sat: ["Morning"]},
  },
  {
    email: "teacher4@edulinky.test",
    displayName: "Thomas Wagner",
    city: CITIES.traun,
    primarySubject: "Computer Science",
    subjects: ["Computer Science", "Mathematics"],
    about: "Software engineer turned teacher. Programming, algorithms, and exam prep.",
    hourlyRate: 45,
    qualifications: ["MSc Computer Science — JKU Linz"],
    experience: [
      {title: "Senior Engineer", institution: "Dynatrace", from: "2015", to: "2021"},
      {title: "CS Teacher", institution: "HTL Leonding", from: "2021", to: "Present"},
    ],
    availability: {Tue: ["Evening"], Thu: ["Evening"], Sat: ["Morning", "Afternoon"]},
  },
  {
    email: "teacher5@edulinky.test",
    displayName: "Sophie Mayr",
    city: CITIES.leonding,
    primarySubject: "German",
    subjects: ["German", "History"],
    about: "German and history teacher. Patient with beginners, rigorous with exam candidates.",
    hourlyRate: 28,
    qualifications: ["MA German Studies — University of Salzburg"],
    experience: [
      {title: "German Teacher", institution: "NMS Leonding", from: "2017", to: "Present"},
    ],
    availability: {Mon: ["Morning"], Tue: ["Afternoon"], Fri: ["Morning", "Afternoon"]},
  },
];

const STUDENTS = [
  {
    email: "student1@edulinky.test",
    displayName: "Felix Berger",
    city: CITIES.ansfelden,
    primarySubject: "Mathematics",
    subjects: ["Mathematics", "Physics"],
    about: "Preparing for my Matura. Struggling with calculus and hoping to fix that.",
  },
  {
    email: "student2@edulinky.test",
    displayName: "Marie Hofer",
    city: CITIES.linz,
    primarySubject: "English",
    subjects: ["English", "Literature"],
    about: "Want to get my English up to C1 before university.",
  },
  {
    email: "student3@edulinky.test",
    displayName: "Jonas Pichler",
    city: CITIES.enns,
    primarySubject: "Chemistry",
    subjects: ["Chemistry", "Biology"],
    about: "Applying to study medicine. Need help with organic chemistry.",
  },
  {
    email: "student4@edulinky.test",
    displayName: "Elena Fischer",
    city: CITIES.wels,
    primarySubject: "Computer Science",
    subjects: ["Computer Science", "Mathematics"],
    about: "Learning to code. Currently stuck on data structures.",
  },
  {
    email: "student5@edulinky.test",
    displayName: "David Steiner",
    city: CITIES.perg,
    primarySubject: "German",
    subjects: ["German", "History"],
    about: "Essay writing is my weak point. Looking for someone patient.",
  },
];

async function upsertUser(spec, role) {
  // Auth account
  let user;
  try {
    user = await auth.getUserByEmail(spec.email);
  } catch {
    user = await auth.createUser({
      email: spec.email,
      password: PASSWORD,
      displayName: spec.displayName,
      emailVerified: true,
    });
  }

  // The role claim is the root of the RBAC system — the app reads it from the
  // ID token, not the doc.
  await auth.setCustomUserClaims(user.uid, {role});

  const {city, lat, lng} = spec.city;

  await db.collection("users").doc(user.uid).set(
    {
      uid: user.uid,
      role,
      email: spec.email,
      display_name: spec.displayName,
      about: spec.about ?? "",
      primary_subject: spec.primarySubject ?? "",
      subjects: spec.subjects ?? [],
      geo_location: {
        lat,
        lng,
        geohash: geohashForLocation([lat, lng]),
        city,
        place_id: "",
      },
      sub_status: "free",
      currency: "USD",
      // Teachers are seeded APPROVED: an unapproved teacher is invisible in
      // discovery and cannot swipe, so seeding them "pending" would leave you
      // hand-approving five accounts before you could test anything.
      verified_status: role === "teacher" ? "approved" : "not_required",
      is_banned: false,
      avg_rating: 0,
      total_reviews: 0,
      featured: spec.featured === true,
      hourly_rate: spec.hourlyRate ?? null,
      qualifications: spec.qualifications ?? [],
      experience: spec.experience ?? [],
      availability: spec.availability ?? {},
      gallery: [],
      video_links: [],
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  return user.uid;
}

async function main() {
  console.log("Seeding test accounts (password for all: %s)\n", PASSWORD);

  for (const t of TEACHERS) {
    const uid = await upsertUser(t, "teacher");
    console.log(`  teacher  ${t.email.padEnd(26)} ${t.displayName.padEnd(16)} ${t.city.city.padEnd(22)} ${uid}`);
  }
  console.log();
  for (const s of STUDENTS) {
    const uid = await upsertUser(s, "student");
    console.log(`  student  ${s.email.padEnd(26)} ${s.displayName.padEnd(16)} ${s.city.city.padEnd(22)} ${uid}`);
  }

  console.log(`
✓ 5 teachers + 5 students seeded, all within ~40 km of Linz.

  Sign in with any of the emails above, password: ${PASSWORD}
  Teachers are already approved, so they are discoverable and can swipe.

  Note: no profile photos — the decks will show the placeholder avatar.
`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
