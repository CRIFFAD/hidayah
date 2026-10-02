/* Supabase client. Replace the two values below with your project's values
   (Supabase Dashboard > Project Settings > API). The anon key is safe in the browser. */
const SUPABASE_URL = "https://jnzftobctyftvcfzwrke.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_PSdhM9T2m_wRXNeJbRKFqA_0yPZ9-aA";

const sb =
  window.supabase &&
  window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const Auth = {
  signUp: (email, password, meta) =>
    sb.auth.signUp({
      email,
      password,
      options: { data: meta, emailRedirectTo: location.origin + "/login.html" },
    }),
  signIn: (email, password) => sb.auth.signInWithPassword({ email, password }),
  signOut: () => sb.auth.signOut(),
  reset: (email) =>
    sb.auth.resetPasswordForEmail(email, {
      redirectTo: location.origin + "/login.html",
    }),
  async user() {
    const { data } = await sb.auth.getSession();
    return data.session ? data.session.user : null;
  },
};

const DB = {
  enroll: (user_id, course_id, course_title) =>
    sb.from("enrollments").insert({ user_id, course_id, course_title }),
  myEnrollments: (user_id) =>
    sb
      .from("enrollments")
      .select("*")
      .eq("user_id", user_id)
      .order("created_at", { ascending: false }),
  sendMessage: (row) => sb.from("messages").insert(row),
};
