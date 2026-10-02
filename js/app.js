const esc = (s) =>
  String(s ?? "").replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ],
  );
async function requireUser(role) {
  const user = await Auth.user();
  if (!user) {
    location.href = "login.html?next=" + location.pathname.split("/").pop();
    return null;
  }
  const { data } = await sb
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .maybeSingle();
  const profile = data || {
    id: user.id,
    full_name: (user.user_metadata || {}).full_name || "Student",
    role: "student",
  };
  if (role && profile.role !== role) {
    location.href = "dashboard.html";
    return null;
  }
  return { user, profile };
}
