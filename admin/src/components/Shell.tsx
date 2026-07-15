"use client";

import Link from "next/link";
import {usePathname} from "next/navigation";
import {signOut} from "firebase/auth";
import {auth} from "@/lib/firebase";
import {useAdmin} from "@/lib/useAdmin";
import {LoginForm} from "./LoginForm";

const NAV = [
  {href: "/", label: "Verifications"},
  {href: "/reports", label: "Reports"},
  {href: "/reviews", label: "Reviews"},
  {href: "/users", label: "Users"},
  {href: "/email", label: "Email"},
  {href: "/quotas", label: "Quotas"},
  {href: "/audit", label: "Audit log"},
];

/**
 * Wraps every page in the admin gate.
 *
 * Note this is a *convenience*, not a security boundary: hiding the UI stops an
 * accident, not an attacker. The real gate is server-side — every admin action
 * is a callable that re-checks `role === "admin"` on the ID token, and the
 * Firestore rules do the same for the audit log.
 */
export function Shell({children}: {children: React.ReactNode}) {
  const {loading, user, isAdmin} = useAdmin();
  const pathname = usePathname();

  if (loading) return <div className="empty">Loading…</div>;
  if (!user) return <LoginForm />;

  if (!isAdmin) {
    return (
      <div className="login">
        <div className="login-card">
          <h1>Not an admin</h1>
          <p className="sub" style={{marginTop: 8}}>
            {user.email} does not have the admin role.
          </p>
          <button className="btn-ghost" onClick={() => signOut(auth)}>
            Sign out
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">EduLinky</div>
        {NAV.map((n) => (
          <Link
            key={n.href}
            href={n.href}
            className={`nav-link ${pathname === n.href ? "active" : ""}`}
          >
            {n.label}
          </Link>
        ))}
        <div className="sidebar-foot">
          <div style={{marginBottom: 10}}>{user.email}</div>
          <button className="btn-ghost" onClick={() => signOut(auth)}>
            Sign out
          </button>
        </div>
      </aside>
      <main className="main">{children}</main>
    </div>
  );
}
