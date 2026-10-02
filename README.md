# Hidayah Islamic and Arabic School website
1. Create a project at supabase.com, then run `setup.sql` in the SQL Editor.
2. Put your Project URL and anon key in `js/supabase.js`.
3. In Supabase > Authentication > URL Configuration, add your site URL (and http://localhost:5500 for testing).
4. Open `index.html` with a local server (VS Code Live Server, or `python -m http.server`). Auth needs http, not file://.
Pages: index, about, courses, signup, login, dashboard, contact.

## PWA
Installable and works offline for visited pages (`manifest.webmanifest`, `sw.js`, `offline.html`, `icons/`). Requires https (or localhost). Bump `V` in `sw.js` when you change files so users get updates.

## Quizzes, scores and chat
- Run the full `setup.sql` again (safe to run on the earlier tables) to add profiles, quizzes, scoring and chat.
- Everyone signs up as a student. To make a teacher, run in the SQL Editor:
  `update public.profiles set role='teacher' where email='teacher@example.com';`
- Teachers: `teacher.html` (create quizzes, see scores). Students: `learn.html` (play, XP, leaderboard). Everyone: `chat.html` (live rooms; only teachers can post in Announcements).
- Correct answers live in a table students cannot read; marking happens on the server (`submit_attempt`), so scores cannot be faked from the browser.
