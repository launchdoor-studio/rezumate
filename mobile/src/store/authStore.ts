import { create } from "zustand";

import { DEV_AUTH_TOKEN } from "../lib/config";
import { hasSupabaseConfig, supabase } from "../lib/supabase";

type AuthState = {
  token: string | null;
  email: string | null;
  isLoading: boolean;
  error: string | null;
  useDevSession: () => void;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
};

export const useAuthStore = create<AuthState>((set) => ({
  token: null,
  email: null,
  isLoading: false,
  error: null,
  useDevSession: () => set({ token: DEV_AUTH_TOKEN, email: "dev@rezumate.local", error: null }),
  signIn: async (email, password) => {
    if (!hasSupabaseConfig || !supabase) {
      set({ token: DEV_AUTH_TOKEN, email, error: null });
      return;
    }

    set({ isLoading: true, error: null });
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error || !data.session?.access_token) {
      set({ isLoading: false, error: error?.message || "Could not sign in" });
      return;
    }

    set({ token: data.session.access_token, email, isLoading: false });
  },
  signUp: async (email, password) => {
    if (!hasSupabaseConfig || !supabase) {
      set({ token: DEV_AUTH_TOKEN, email, error: null });
      return;
    }

    set({ isLoading: true, error: null });
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) {
      set({ isLoading: false, error: error.message });
      return;
    }

    set({ token: data.session?.access_token || DEV_AUTH_TOKEN, email, isLoading: false });
  },
  signOut: async () => {
    if (supabase) {
      await supabase.auth.signOut();
    }
    set({ token: null, email: null, error: null });
  }
}));
