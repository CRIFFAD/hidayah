-- Hidayah admin portal setup
-- Run in Supabase SQL Editor as the project owner.
-- Reuses the existing quizzes, questions, answer_keys, attempts and profiles tables.

-- 1. Helper used by admin-only RLS policies. SECURITY DEFINER avoids profiles RLS recursion.
CREATE OR REPLACE FUNCTION public.hidayah_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = (SELECT auth.uid())
      AND p.role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.hidayah_is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hidayah_is_admin() TO authenticated;

-- 2. Courses table used by the admin portal.
CREATE TABLE IF NOT EXISTS public.hidayah_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  level text NOT NULL,
  teacher_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  teacher_name text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','archived')),
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.hidayah_courses ENABLE ROW LEVEL SECURITY;

-- 3. Admissions table. Your public admission form can insert applications here.
CREATE TABLE IF NOT EXISTS public.hidayah_admissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_name text NOT NULL,
  email text NOT NULL,
  phone text,
  level text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at timestamptz
);
ALTER TABLE public.hidayah_admissions ENABLE ROW LEVEL SECURITY;

-- 4. Announcements and settings used by the current admin portal.
CREATE TABLE IF NOT EXISTS public.hidayah_announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  audience text NOT NULL DEFAULT 'all' CHECK (audience IN ('all','students','teachers')),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published')),
  published_at timestamptz,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.hidayah_announcements ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.hidayah_settings (
  key text PRIMARY KEY,
  value text,
  updated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.hidayah_settings ENABLE ROW LEVEL SECURITY;

-- 5. Extend the EXISTING quizzes table only with fields the admin UI needs.
ALTER TABLE public.quizzes
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'draft',
  ADD COLUMN IF NOT EXISTS description text;

-- Keep quiz status values predictable.
ALTER TABLE public.quizzes DROP CONSTRAINT IF EXISTS quizzes_status_check;
ALTER TABLE public.quizzes
  ADD CONSTRAINT quizzes_status_check CHECK (status IN ('draft','published','archived'));

-- 6. RLS policies for courses.
DROP POLICY IF EXISTS "hidayah courses public published read" ON public.hidayah_courses;
DROP POLICY IF EXISTS "hidayah courses admin all" ON public.hidayah_courses;
CREATE POLICY "hidayah courses public published read"
  ON public.hidayah_courses FOR SELECT TO anon, authenticated
  USING (status = 'published');
CREATE POLICY "hidayah courses admin all"
  ON public.hidayah_courses FOR ALL TO authenticated
  USING (public.hidayah_is_admin())
  WITH CHECK (public.hidayah_is_admin());

-- 7. RLS policies for admissions. Public users may submit an application;
-- only admins may read, review, update or delete applications.
DROP POLICY IF EXISTS "hidayah admissions public submit" ON public.hidayah_admissions;
DROP POLICY IF EXISTS "hidayah admissions admin all" ON public.hidayah_admissions;
CREATE POLICY "hidayah admissions public submit"
  ON public.hidayah_admissions FOR INSERT TO anon, authenticated
  WITH CHECK (
    length(trim(applicant_name)) > 1 AND
    length(trim(email)) > 3 AND
    length(trim(level)) > 0 AND
    status = 'pending' AND reviewed_by IS NULL AND reviewed_at IS NULL
  );
CREATE POLICY "hidayah admissions admin all"
  ON public.hidayah_admissions FOR ALL TO authenticated
  USING (public.hidayah_is_admin())
  WITH CHECK (public.hidayah_is_admin());

-- 8. RLS policies for announcements and settings.
DROP POLICY IF EXISTS "hidayah announcements published read" ON public.hidayah_announcements;
DROP POLICY IF EXISTS "hidayah announcements admin all" ON public.hidayah_announcements;
CREATE POLICY "hidayah announcements published read"
  ON public.hidayah_announcements FOR SELECT TO anon, authenticated
  USING (status = 'published');
CREATE POLICY "hidayah announcements admin all"
  ON public.hidayah_announcements FOR ALL TO authenticated
  USING (public.hidayah_is_admin())
  WITH CHECK (public.hidayah_is_admin());

DROP POLICY IF EXISTS "hidayah settings admin all" ON public.hidayah_settings;
CREATE POLICY "hidayah settings admin all"
  ON public.hidayah_settings FOR ALL TO authenticated
  USING (public.hidayah_is_admin())
  WITH CHECK (public.hidayah_is_admin());

-- 9. Admin access to the existing quiz tables and quiz attempts.
DROP POLICY IF EXISTS "hidayah quizzes admin all" ON public.quizzes;
CREATE POLICY "hidayah quizzes admin all"
  ON public.quizzes FOR ALL TO authenticated
  USING (public.hidayah_is_admin())
  WITH CHECK (public.hidayah_is_admin());

DROP POLICY IF EXISTS "hidayah questions admin all" ON public.questions;
CREATE POLICY "hidayah questions admin all"
  ON public.questions FOR ALL TO authenticated
  USING (public.hidayah_is_admin())
  WITH CHECK (public.hidayah_is_admin());

DROP POLICY IF EXISTS "hidayah answer keys admin all" ON public.answer_keys;
CREATE POLICY "hidayah answer keys admin all"
  ON public.answer_keys FOR ALL TO authenticated
  USING (public.hidayah_is_admin())
  WITH CHECK (public.hidayah_is_admin());

DROP POLICY IF EXISTS "hidayah attempts admin read" ON public.attempts;
CREATE POLICY "hidayah attempts admin read"
  ON public.attempts FOR SELECT TO authenticated
  USING (public.hidayah_is_admin());

-- 10. Preserve the existing profile SELECT policies so current student/teacher
-- features are not unexpectedly disrupted. Prevent ordinary users from changing
-- their own role through the profiles table. Profile editing remains available
-- for the known editable columns.
REVOKE UPDATE ON TABLE public.profiles FROM anon, authenticated;
GRANT UPDATE (full_name, phone, programme) ON TABLE public.profiles TO authenticated;

-- 11. Secure role-change RPC. Only an existing admin can change another user's role.
CREATE OR REPLACE FUNCTION public.hidayah_set_user_role(
  target_user_id uuid,
  new_role text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'You must be signed in.';
  END IF;
  IF NOT public.hidayah_is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change user roles.';
  END IF;
  IF new_role NOT IN ('student','teacher','admin') THEN
    RAISE EXCEPTION 'Invalid role. Allowed roles: student, teacher, admin.';
  END IF;
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot change your own administrator role.';
  END IF;
  UPDATE public.profiles
  SET role = new_role
  WHERE id = target_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'The selected profile does not exist.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.hidayah_set_user_role(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hidayah_set_user_role(uuid, text) TO authenticated;

-- 12. Table privileges needed by Supabase JS for the admin portal.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.hidayah_courses TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.hidayah_admissions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.hidayah_announcements TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.hidayah_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quizzes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.questions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.answer_keys TO authenticated;
GRANT SELECT ON public.attempts TO authenticated;
GRANT INSERT ON public.hidayah_admissions TO anon;
GRANT SELECT ON public.hidayah_courses, public.hidayah_announcements TO anon;

-- 13. Helpful indexes.
CREATE INDEX IF NOT EXISTS hidayah_courses_status_idx ON public.hidayah_courses(status);
CREATE INDEX IF NOT EXISTS hidayah_admissions_status_idx ON public.hidayah_admissions(status);
CREATE INDEX IF NOT EXISTS questions_quiz_position_idx ON public.questions(quiz_id, position);
CREATE INDEX IF NOT EXISTS answer_keys_question_id_idx ON public.answer_keys(question_id);
CREATE INDEX IF NOT EXISTS attempts_student_created_idx ON public.attempts(student_id, created_at DESC);

-- End. Existing student/teacher quiz read policies are retained.
