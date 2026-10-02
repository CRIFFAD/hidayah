const $ = (s) => document.querySelector(s);
function note(t, ok) {
  const m = $("#msg");
  m.className = "msg " + (ok ? "ok" : "err");
  m.textContent = t;
}
function busy(b, on, txt) {
  b.disabled = on;
  b.textContent = on ? "Please wait..." : txt;
}

const su = $("#signupForm");
if (su)
  su.addEventListener("submit", async (e) => {
    e.preventDefault();
    const b = su.querySelector("button"),
      f = new FormData(su);
    if (f.get("password").length < 8)
      return note("Password must be at least 8 characters.");
    if (f.get("password") !== f.get("confirm"))
      return note("Passwords do not match.");
    busy(b, true);
    const { data, error } = await Auth.signUp(
      f.get("email").trim(),
      f.get("password"),
      {
        full_name: f.get("name").trim(),
        phone: f.get("phone"),
        role: f.get("role"),
        programme: f.get("programme"),
      },
    );
    busy(b, false, "Create account");
    if (error) return note(error.message);
    if (data.session) location.href = "dashboard.html";
    else {
      note(
        "Account created. Check your email to confirm it, then log in.",
        true,
      );
      su.reset();
    }
  });

const li = $("#loginForm");
if (li) {
  li.addEventListener("submit", async (e) => {
    e.preventDefault();
    const b = li.querySelector("button");
    busy(b, true);
    const { error } = await Auth.signIn(
      li.email.value.trim(),
      li.password.value,
    );
    busy(b, false, "Log in");
    if (error)
      return note(
        error.message === "Invalid login credentials"
          ? "Email or password is incorrect."
          : error.message,
      );
    location.href = /^[a-z]+\.html$/.test(
      new URLSearchParams(location.search).get("next") || "",
    )
      ? new URLSearchParams(location.search).get("next")
      : "dashboard.html";
  });
  $("#forgot").addEventListener("click", async (e) => {
    e.preventDefault();
    const em = li.email.value.trim();
    if (!em)
      return note("Enter your email above first, then select Forgot password.");
    const { error } = await Auth.reset(em);
    note(
      error ? error.message : "Password reset link sent. Check your email.",
      !error,
    );
  });
}
Auth.user().then((u) => {
  if (u && (su || li)) location.href = "dashboard.html";
});
