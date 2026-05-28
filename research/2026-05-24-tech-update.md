# Luxi Research Brief — 2026-05-24

> Compiled for Luxi Oracle (UI/UX · Frontend Specialist) — Forge/Omega system.
> Knowledge base: up to Aug 2025 (covers all listed stable releases).

---

## React / Next.js

**React 19 (stable Dec 2024)**
- **Actions API** — `useActionState`, `useFormStatus`, `useOptimistic` replace manual pending/error state patterns. Native async transitions in forms.
- **Server Components stable** — full RSC support; `use()` hook for reading promises and context inside render.
- **`ref` as prop** — no more `forwardRef` wrapper; pass `ref` directly to function components.
- **Document metadata** — `<title>`, `<meta>`, `<link>` hoisted from anywhere in the tree; no need for `next/head` or Helmet.
- **Asset preloading** — `preload()`, `preinit()` APIs for fonts, scripts, stylesheets.
- **Breaking** — legacy Context API deprecated; `ReactDOM.render` removed; string refs gone.

**Next.js 15 (Oct 2024)**
- **`fetch` caching opt-in by default** — breaking change from v14; `cache: 'force-cache'` no longer assumed; must be explicit.
- **Turbopack stable** for `next dev` — significantly faster HMR (up to 10x on large apps).
- **React 19 RC support** built-in; `after()` API for post-response work without blocking TTFB.
- **`instrumentation.js`** stable — app-level observability hooks.
- **Partial Pre-rendering (PPR)** — incremental; static shell + streaming dynamic holes in a single route.
- **`<Form>` component** — built-in prefetch + progressive enhancement for search/navigation forms.

---

## Tailwind CSS 4

- **CSS-first config** — `tailwind.config.js` replaced by `@import "tailwindcss"` + `@theme {}` block in CSS. Zero JS config file needed.
- **CSS custom properties everywhere** — all design tokens emit as `--color-*`, `--spacing-*`, etc. Easy to consume outside Tailwind.
- **`@utility` directive** — define custom utilities in CSS, not a JS plugin.
- **Lightning CSS engine** — built-in vendor prefixing and modern CSS transforms; PostCSS optional.
- **P3 color palette** — `oklch`-based colors; wider gamut on capable displays.
- **Container queries built-in** — `@container` / `@sm:` etc. without a plugin.
- **Dynamic utility values** — `w-[17]`, `mt-[3.5]` etc. resolved at build time without arbitrary brackets in most cases.
- **Breaking** — `bg-opacity-*`, `text-opacity-*` removed; use `bg-black/50` syntax. `ring` default changed to `1px`.

---

## Core Web Vitals & Performance

- **INP replaces FID** (Mar 2024, now fully enforced in rankings) — target < 200 ms. Profile with Chrome DevTools "Interactions" panel or `web-vitals` library v3+.
- **LCP target ≤ 2.5 s** — biggest wins: `fetchpriority="high"` on hero images, `<link rel="preload">` for LCP resource, avoid lazy-loading above-fold images.
- **CLS target < 0.1** — reserve space for images/ads (`aspect-ratio`), avoid FOUT with `font-display: optional` or `size-adjust`.
- **TTFB** increasingly tracked — use PPR/edge rendering; reduce server-side blocking work.
- **`PerformanceObserver` + `web-vitals` v4** — new `onINP` delta attribution helps identify slow event handlers.
- **React 19 transitions** — `startTransition` + `useOptimistic` reduce INP by keeping UI responsive during async updates.

---

## Accessibility & Thai Typography

**WCAG 2.2 (stable Oct 2023, now enforcement baseline)**
- New SCs relevant to UI: **2.5.7** Dragging Movements alternative, **2.5.8** Target Size minimum 24×24 px, **3.2.6** Consistent Help, **3.3.7** Redundant Entry.
- **Focus appearance (2.4.11/2.4.12)** — visible focus indicator must have 3:1 contrast ratio vs adjacent colors; area ≥ perimeter × 2 px.

**Thai Typography specifics**
- Thai script has no word-spacing; rely on `word-break: keep-all` + `overflow-wrap: anywhere` — never `word-break: break-all` (breaks mid-syllable).
- Use `line-height` ≥ 1.8 for Thai body text (tall ascenders/descenders).
- Font choices: **Sarabun**, **IBM Plex Sans Thai**, **Noto Sans Thai** all support variable weight and have good hinting.
- `lang="th"` on root or section element — required for screen readers (NVDA+JAWS Thai TTS).
- Avoid justified text (`text-align: justify`) in Thai — browser word-boundary detection fails.
- **Axe-core 4.9+** and **Lighthouse 12** now include Thai locale checks in color-contrast auditing.

---

## Component Libraries

**shadcn/ui**
- Now uses **Radix UI Primitives v2** under the hood; all components are copy-paste source (not a package dependency).
- **New components (2024–2025):** `Sidebar`, `Breadcrumb`, `Chart` (Recharts wrapper), `Carousel`, `Resizable`, `Toggle Group`.
- Theme system rebuilt around CSS variables — pairs naturally with Tailwind v4 `@theme`.
- CLI (`npx shadcn@latest add`) supports monorepo paths and custom registries.

**Radix UI Primitives v2**
- Improved `asChild` pattern; better ref forwarding; `VisuallyHidden` utility component added.
- `Dialog` and `AlertDialog` now trap focus with `aria-modal` correctly on iOS Safari.

**Framer Motion → Motion (v11+)**
- Rebranded to **Motion for React** (`motion` package).
- `animate()` DOM API works without React; tree-shakeable.
- **`layout` animations** performance improved via FLIP with GPU compositing.
- **`useAnimate` hook** preferred over `motion.div` for imperative sequences.
- Bundle size reduced ~40% vs v10 when using selective imports.

---

## Top 3 Priorities for Omega UI

1. **Adopt React 19 Actions + PPR in Next.js 15** — migrate forms to `useActionState`; enable PPR on high-traffic routes to hit LCP < 2.5 s without sacrificing dynamic content.

2. **Migrate to Tailwind CSS v4 CSS-first config** — eliminates JS config drift, unlocks P3 colors for richer brand palette, and aligns design tokens with shadcn/ui v2 CSS variable system.

3. **INP hardening + WCAG 2.2 Target Size audit** — profile all interactive components with `web-vitals` INP attribution; sweep UI for touch targets < 24 px (critical for Thai mobile users); add `lang="th"` and verify focus-visible styles meet 2.4.11.

---

*Note: WebSearch was unavailable in this session. Brief compiled from training knowledge (cutoff Aug 2025). Verify against official changelogs before shipping.*
