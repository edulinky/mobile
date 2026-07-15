"use client";

import {useEffect, useState} from "react";
import {onAuthStateChanged, User} from "firebase/auth";
import {auth} from "./firebase";

export interface AdminState {
  loading: boolean;
  user: User | null;
  /** True only if the ID token carries `role: "admin"`. */
  isAdmin: boolean;
}

/**
 * The admin gate.
 *
 * Signing in is not enough — a Student could sign in here with their app
 * account. Authorisation comes from the **role claim in the ID token**, which
 * only `setRole`/the bootstrap script can grant. The UI hiding itself is
 * cosmetic anyway: every admin action is a callable that re-checks the claim
 * server-side, and the Firestore rules gate `auditLog` on it too.
 */
export function useAdmin(): AdminState {
  const [state, setState] = useState<AdminState>({
    loading: true,
    user: null,
    isAdmin: false,
  });

  useEffect(() => {
    return onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setState({loading: false, user: null, isAdmin: false});
        return;
      }
      const token = await user.getIdTokenResult();
      setState({
        loading: false,
        user,
        isAdmin: token.claims.role === "admin",
      });
    });
  }, []);

  return state;
}
