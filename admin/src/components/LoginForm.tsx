"use client";

import {useState} from "react";
import {signInWithEmailAndPassword} from "firebase/auth";
import {auth} from "@/lib/firebase";

export function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign-in failed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="login">
      <form className="login-card" onSubmit={submit}>
        <h1>EduLinky Admin</h1>
        <p className="sub" style={{marginTop: 6}}>Sign in to moderate.</p>

        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          autoComplete="username"
          required
        />

        <div style={{height: 14}} />
        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoComplete="current-password"
          required
        />

        <div style={{height: 20}} />
        <button className="btn-primary" style={{width: "100%"}} disabled={busy}>
          {busy ? "Signing in…" : "Sign in"}
        </button>
        {error && <div className="err">{error}</div>}
      </form>
    </div>
  );
}
