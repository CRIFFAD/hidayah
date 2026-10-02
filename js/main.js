const COURSES = [
  {
    id: "tajweed",
    cat: "quran",
    g: "ق",
    t: "Quran Recitation and Tajweed",
    d: "Correct pronunciation, rules of Tajweed and fluent recitation with a qualified teacher.",
    l: "All ages",
  },
  {
    id: "hifz",
    cat: "quran",
    g: "ح",
    t: "Hifz Programme",
    d: "Structured memorisation with daily revision, weekly tests and progress tracking.",
    l: "Ages 6+",
  },
  {
    id: "islamic",
    cat: "quran",
    g: "إ",
    t: "Islamic Studies",
    d: "Aqidah, Fiqh of worship, Seerah, Hadith and good character for young Muslims.",
    l: "All ages",
  },
  {
    id: "qaida",
    cat: "arabic",
    g: "أ",
    t: "Noorani Qaida",
    d: "Arabic letters, sounds and joining, the first step for every beginner reader.",
    l: "Beginners",
  },
  {
    id: "arabic-rw",
    cat: "arabic",
    g: "ع",
    t: "Arabic Reading and Writing",
    d: "Vocabulary, sentence building, handwriting and comprehension from the ground up.",
    l: "Beginner to Intermediate",
  },
  {
    id: "nahw",
    cat: "arabic",
    g: "ن",
    t: "Arabic Grammar (Nahw and Sarf)",
    d: "Understand the structure of the language of the Quran and classical texts.",
    l: "Intermediate",
  },
  {
    id: "speak",
    cat: "arabic",
    g: "ت",
    t: "Spoken Arabic",
    d: "Everyday conversation, listening practice and confident speaking.",
    l: "All levels",
  },
  {
    id: "math",
    cat: "conv",
    g: "1+2",
    t: "Mathematics",
    d: "Number work, algebra, geometry and problem solving, taught step by step.",
    l: "Primary to JSS",
  },
  {
    id: "english",
    cat: "conv",
    g: "Aa",
    t: "English Language",
    d: "Grammar, comprehension, essay writing, spelling and speaking skills.",
    l: "Primary to JSS",
  },
  {
    id: "physics",
    cat: "conv",
    g: "Φ",
    t: "Physics",
    d: "Motion, energy, light, electricity and simple experiments that make ideas clear.",
    l: "JSS and SSS",
  },
  {
    id: "chem",
    cat: "conv",
    g: "Ch",
    t: "Chemistry",
    d: "Matter, atoms, reactions, acids and bases with practical demonstrations.",
    l: "JSS and SSS",
  },
  {
    id: "phonics",
    cat: "primary",
    g: "Ab",
    t: "Phonics and Early Reading",
    d: "Letter sounds, blending and first reading books for young learners.",
    l: "Nursery to Primary 2",
  },
  {
    id: "numeracy",
    cat: "primary",
    g: "123",
    t: "Primary Numeracy",
    d: "Counting, addition, subtraction, multiplication tables and shapes.",
    l: "Primary 1 to 3",
  },
  {
    id: "science",
    cat: "primary",
    g: "Sc",
    t: "Basic Science and Health",
    d: "Plants, animals, the human body, weather and healthy living.",
    l: "Primary 3 to 6",
  },
  {
    id: "social",
    cat: "primary",
    g: "So",
    t: "Social Studies and Civic Education",
    d: "Family, community, citizenship, our country and good values.",
    l: "Primary 3 to 6",
  },
  {
    id: "verbal",
    cat: "primary",
    g: "Q",
    t: "Verbal and Quantitative Reasoning",
    d: "Puzzles and practice for common entrance exams.",
    l: "Primary 4 to 6",
  },
];
const CATS = {
  quran: "Quran and Islamic Studies",
  arabic: "Arabic Language",
  conv: "Conventional Subjects",
  primary: "Primary School",
};

document.addEventListener("DOMContentLoaded", () => {
  const page = document.body.dataset.page;
  const h = document.getElementById("site-header");
  if (h)
    h.outerHTML = `<header class="top"><div class="wrap nav"><a class="brand" href="index.html"><img src="assets/logo.png" alt="Hidayah logo"><span>Hidayah</span></a>
  <button class="burger" aria-label="Menu" aria-expanded="false"><i></i><i></i><i></i></button>
  <ul class="links">${[
    ["index", "Home"],
    ["about", "About"],
    ["courses", "Courses"],
    ["learn", "Quizzes"],
    ["chat", "Chat"],
    ["contact", "Contact"],
  ]
    .map(
      ([p, n]) =>
        `<li><a href="${p}.html" class="${page === p ? "on" : ""}">${n}</a></li>`,
    )
    .join("")}
  <li><a href="login.html" class="${page === "login" ? "on" : ""}">Log in</a></li><li><a class="btn b1" href="signup.html">Enrol now</a></li></ul></div></header>`;
  const f = document.getElementById("site-footer");
  if (f)
    f.outerHTML = `<footer><div class="wrap"><div class="fg"><div><h4>Hidayah Islamic and Arabic School</h4><p>Guiding children and adults to the Quran, the Arabic language and sound academic knowledge.</p></div>
  <div><h4>Explore</h4><ul><li><a href="about.html">About us</a></li><li><a href="courses.html">Courses</a></li><li><a href="contact.html">Contact</a></li></ul></div>
  <div><h4>Students</h4><ul><li><a href="signup.html">Create account</a></li><li><a href="login.html">Log in</a></li><li><a href="dashboard.html">My dashboard</a></li></ul></div>
  <div><h4>Contact</h4><ul><li>hidaayatulislamiyyah@gmail.com</li><li>+234 814 252 6798</li><li>Lagos, Nigeria</li></ul></div></div>
  <p class="copy">&copy; ${new Date().getFullYear()} Hidayah Islamic and Arabic School. All rights reserved.</p></div></footer>`;
  const b = document.querySelector(".burger"),
    l = document.querySelector(".links");
  if (b) {
    b.onclick = () => {
      const o = l.classList.toggle("open");
      b.classList.toggle("x", o);
      b.setAttribute("aria-expanded", o);
    };
    l.addEventListener("click", (e) => {
      if (e.target.tagName === "A") {
        l.classList.remove("open");
        b.classList.remove("x");
      }
    });
  }
  window.courseCard = (c) =>
    `<article class="card rv"><div class="glyph">${c.g}</div><h3>${c.t}</h3><p>${c.d}</p><span class="tag">${c.l}</span><br><button class="btn b3" data-enrol="${c.id}">Enrol</button></article>`;
  if (window.renderPage) window.renderPage();
  const io = new IntersectionObserver(
    (es) =>
      es.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add("show");
          io.unobserve(e.target);
        }
      }),
    { threshold: 0.12 },
  );
  window.observeRv = () =>
    document.querySelectorAll(".rv:not(.show)").forEach((el) => io.observe(el));
  observeRv();
  const co = new IntersectionObserver(
    (es) =>
      es.forEach((e) => {
        if (!e.isIntersecting) return;
        co.unobserve(e.target);
        const n = +e.target.dataset.n,
          s = performance.now(),
          sfx = e.target.dataset.s || "";
        (function step(t) {
          const p = Math.min((t - s) / 1600, 1);
          e.target.textContent =
            Math.floor(n * p).toLocaleString() + (p === 1 ? sfx : "");
          if (p < 1) requestAnimationFrame(step);
        })(s);
      }),
    { threshold: 0.6 },
  );
  document.querySelectorAll("[data-n]").forEach((el) => co.observe(el));
  const st = document.querySelector(".stars");
  if (st)
    for (let i = 0; i < 26; i++) {
      const s = document.createElement("i");
      s.style.cssText = `left:${Math.random() * 100}%;top:${Math.random() * 100}%;animation-delay:${Math.random() * 4}s`;
      st.appendChild(s);
    }
  document.addEventListener("click", async (e) => {
    const id = e.target.dataset && e.target.dataset.enrol;
    if (!id) return;
    const c = COURSES.find((x) => x.id === id),
      u = await Auth.user();
    if (!u) {
      location.href = "login.html?next=courses.html";
      return;
    }
    const { error } = await DB.enroll(u.id, c.id, c.t),
      dup = error && error.code === "23505";
    e.target.textContent = error
      ? dup
        ? "Already enrolled"
        : "Try again"
      : "Enrolled";
    e.target.disabled = !error || dup;
  });
});
