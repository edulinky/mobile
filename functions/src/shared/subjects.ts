/**
 * Subjects are free text on both sides — a teacher types theirs into their
 * profile, an institution types one onto a job card — so they are compared
 * *canonicalized*, never raw. Without this, "Mathematics" and "maths " are
 * different subjects, and a job card is invisible to exactly the teacher it was
 * posted for.
 */

/**
 * The spellings people actually use, mapped to the one we match on.
 *
 * This is a **fixed alias table, not fuzzy string matching**, and that is a
 * deliberate choice. Edit-distance matching cuts both ways and both ways are
 * bad: too loose and a French teacher is shown German jobs ("french"/"german"
 * are not far apart once you allow a few edits, and short subject names are
 * dense with near-neighbours); too tight and it does not catch "maths" →
 * "mathematics" anyway, which is 6 edits apart and the very case we care about.
 * A table is predictable, testable, and when it is wrong it is wrong in a way
 * you can see and fix in one line.
 *
 * Left side must be already-normalized (lower case, single-spaced).
 */
const ALIASES: Record<string, string> = {
  // Maths — the case that started this.
  "math": "mathematics",
  "maths": "mathematics",
  "mathematic": "mathematics",

  // Sciences
  "bio": "biology",
  "chem": "chemistry",
  "phys": "physics",
  "science": "science",

  // Computing
  "comp sci": "computer science",
  "compsci": "computer science",
  "computing": "computer science",
  "ict": "computer science",
  "informatics": "computer science",
  "information technology": "computer science",
  "it": "computer science",

  // Humanities
  "lit": "literature",
  "english literature": "literature",
  "english language": "english",
  "esl": "english",
  "english as a second language": "english",
  "geo": "geography",
  "econ": "economics",
  "economy": "economics",

  // Languages
  "chinese": "mandarin",
  "mandarin chinese": "mandarin",
  "putonghua": "mandarin",
  "espanol": "spanish",
  "español": "spanish",
  "francais": "french",
  "français": "french",
  "deutsch": "german",

  // Arts & PE
  "fine art": "art",
  "art and design": "art",
  "art & design": "art",
  "pe": "physical education",
  "phys ed": "physical education",
  "physical ed": "physical education",
};

/** Case, padding and punctuation are noise; they must not hide a job. */
function normalize(subject: string): string {
  return subject
    .trim()
    .toLowerCase()
    .replace(/[.]/g, "")
    .replace(/\s+/g, " ");
}

/**
 * The string a subject is actually compared as. Use this on BOTH sides of every
 * subject comparison — the teacher's profile and the institution's job card, the
 * student's primary subject and the teacher's list.
 */
export function canonicalSubject(subject: string): string {
  const n = normalize(subject);
  return ALIASES[n] ?? n;
}

/** Do these two free-text subjects mean the same thing? */
export function sameSubject(a: string, b: string): boolean {
  const x = canonicalSubject(a);
  return x.length > 0 && x === canonicalSubject(b);
}
