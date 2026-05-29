// Authentication service. Wraps Supabase Auth.
import { supabase } from './client';
import type { UserRole } from '$lib/types/database';

export interface SignUpInput {
  email: string;
  password: string;
  display_name: string;
  role: Exclude<UserRole, 'admin'>;
  /** Optional org name; required when role === 'organization'. */
  organization_name?: string;
}

export async function signUp(input: SignUpInput) {
  const { email, password, display_name, role, organization_name } = input;
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        display_name: role === 'organization' ? organization_name || display_name : display_name,
        role
      }
    }
  });
  if (error) throw error;
  return data;
}

export async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

export async function getSession() {
  const { data, error } = await supabase.auth.getSession();
  if (error) throw error;
  return data.session;
}

export async function getUser() {
  const { data, error } = await supabase.auth.getUser();
  if (error) throw error;
  return data.user;
}

export async function resetPassword(email: string, redirectTo?: string) {
  const { data, error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo });
  if (error) throw error;
  return data;
}
