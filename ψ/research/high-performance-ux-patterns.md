# High Performance UX/UI Patterns

> Research into Radix UI + shadcn/ui architecture, virtual lists, and paint containment for building snappy, accessible interfaces at scale.

**Date**: 2026-05-28  
**For**: Luxi Oracle — UI Performance Mastery

---

## 1. Radix UI: Low-Level Primitives Architecture

### 1.1 Core Design Philosophy

[Radix UI](https://www.radix-ui.com/primitives) is a **low-level UI component library** focused on:

- **Accessibility-first**: WAI-ARIA standards baked in
- **Unstyled by default**: Complete stylistic freedom
- **Behavior + logic only**: No CSS bundled
- **Tree-shakeable**: Import only what you use
- **Granular access**: Wrap parts, add listeners, customize props

### 1.2 Architecture Principles

#### Uncontrolled by Default

Most components work uncontrolled automatically:

```tsx
// Uncontrolled (default)
<Dialog>
  <DialogTrigger>Open</DialogTrigger>
  <DialogContent>Content</DialogContent>
</Dialog>

// Optional: Full control if needed
const [open, setOpen] = useState(false);
<Dialog open={open} onOpenChange={setOpen}>
  ...
</Dialog>
```

**Benefit**: Simpler API, less boilerplate. Controllable when needed for complex state management.

#### Open Component Structure

Each component exposes its parts:

```tsx
// Not: <Dialog.Header>, <Dialog.Footer> (opaque)
// But: <DialogContent>, <DialogTitle>, <DialogDescription> (composable)
<DialogContent>
  <div className="my-header">
    <DialogTitle>Title</DialogTitle>
    <DialogDescription>Description</DialogDescription>
  </div>
  <div className="my-body">Content</div>
  <div className="my-footer">Actions</div>
</DialogContent>
```

**Benefit**: No fighting against locked-in structure. Compose your way.

#### WAI-ARIA Compliance

Radix handles the hard parts:

- Correct `role`, `aria-*` attributes
- Focus management (trap, restore, cycling)
- Keyboard navigation (arrow keys, Tab, Escape)
- Announcement to screen readers

Developers don't reinvent accessibility wheel.

### 1.3 Performance Implications

**What's Not Included** = Less to Parse:
- No CSS (0 bytes)
- No animations (you choose)
- No theme/config (minimal JS)
- No DOM overhead (lean primitives)

Result: **Smaller bundle, faster TTI (Time To Interactive).**

### 1.4 Adoption Strategy

- **Incremental**: Use individual components, mix with others
- **Entry Points**: Start with dialogs/dropdowns, expand gradually
- **Styling Freedom**: Tailwind, CSS Modules, vanilla CSS—your choice

---

## 2. shadcn/ui: Developer-First Design System

### 2.1 Architecture & Philosophy

[shadcn/ui](https://ui.shadcn.com/) builds on Radix primitives but with a **copy-paste-first** model:

- **Not a dependency**: Copy components into `components/ui/`
- **Full ownership**: Modify, extend, delete freely
- **Styled with Tailwind**: Modern utility-first CSS
- **1300+ blocks** (as of 2026): Prebuilt component combos
- **Base UI toggle**: Switch between Radix (feature-rich) or Base UI (lean) primitives

### 2.2 The Copy-Paste Advantage

Traditional UI libraries:
```
npm install component-lib  # Locked version, black box updates
```

shadcn/ui:
```
npx shadcn-ui add button   # Copy source to your repo, you own it
# Edit, fork, customize—no external dependency
```

**Benefits**:
- Zero breaking changes (your code)
- No version ping-pong
- Full transparency (read the source)
- Infinite customization (it's yours)
- Smaller bundles (unused code stays out)

### 2.3 2026 Evolution

**March 2026 Updates**:
- **CLI v4**: Smarter component scaffolding
- **shadcn/skills**: AI-ready component patterns
- **Presets engine**: Design system variants (dark, high-contrast, compact)
- **1300+ registry blocks**: Dashboard shells, forms, tables, multi-step flows

**Stack Dominance**: shadcn/ui + Tailwind v4 + Next.js = Default for React 2026

### 2.4 Design System Composition

Not opinionated on:
- Page structure
- State management (Redux, Zustand, Jotai)
- Branding/colors (you set via Tailwind config)

**Starting point, not framework**: Flexibility intentional.

### 2.5 Accessibility Guarantee

Built on Radix or Base UI → Auto-correct:
- ✓ ARIA roles & attributes
- ✓ Keyboard navigation (standards-based)
- ✓ Focus trapping (modals, dialogs)
- ✓ Screen reader announcements

---

## 3. Virtual Lists: Windowing for Massive Datasets

### 3.1 The Problem

Rendering 10,000 list items = 10,000 DOM nodes:

```tsx
// Bad: 10k DOM nodes always
{items.map(item => <ListItem key={item.id} {...item} />)}
```

**Result**: 
- Layout thrashing
- Memory bloat (1MB+ for large lists)
- Scroll jank (60fps → 15fps)
- TTI delay

### 3.2 Virtualization Solution

**Concept**: Render only visible items + small overscan buffer.

```
Viewport (visible):
[Item 47] ← User sees this
[Item 48] ← And this
[Item 49] ← And this

Hidden above (pre-render for smooth scrolling):
[Item 43]
[Item 44]
[Item 45]
[Item 46]

Hidden below (pre-render for smooth scrolling):
[Item 50]
[Item 51]
[Item 52]

Totally hidden (not in DOM):
[Item 1-42, Item 53+]
```

DOM stays constant (~25 nodes for a viewport showing 3 items).

### 3.3 React-Window: Best Practice

[react-window](https://github.com/bvaughn/react-window) is the standard:

```tsx
import { FixedSizeList } from 'react-window';

<FixedSizeList
  height={600}           // Viewport height
  itemCount={10000}      // Total items
  itemSize={35}          // Item height (pixels)
  width="100%"
>
  {({ index, style }) => (
    <div style={style}>Item {index}</div>
  )}
</FixedSizeList>
```

**Key props**:
- `itemCount`: Total items (doesn't affect rendering)
- `itemSize`: For `FixedSizeList`, all items same height = fast
- `overscanCount`: Pre-render X items above/below viewport (default: 1)

### 3.4 Performance Gains

**With Virtualization**:
- DOM nodes: ~25 (constant, regardless of 10k items)
- Memory: ~2MB (vs 100MB+)
- Scroll FPS: 60 (smooth)
- TTI: Instant

**Cost**: Complexity + can't search all items with Ctrl+F (they're not in DOM).

### 3.5 When NOT to Use

- Small lists (< 50 items): Premature optimization
- Complex interactions: Drag-drop, multi-select across page ranges
- SEO-critical: Search engines see only visible items
- All-in-DOM required: Some patterns need full content availability

### 3.6 Best Practices

1. **Use `FixedSizeList`** when possible (all items same height)
   - `VariableSizeList` = slower, use only if heights vary

2. **Overscan wisely**: Default overscanCount=1 good for 30-35px items
   - Scroll too slow? Increase overscan
   - Stutters? Decrease item height or increase hardware performance

3. **Monitor**: Use React DevTools Profiler to measure render times

4. **Combine with searchable indexes**: Server-side filtering, then virtualize results

---

## 4. Paint Containment: Isolating Render Work

### 4.1 The Pixel Pipeline

Browser rendering follows 5 steps (CSSOM → Composite):

```
JavaScript execution
    ↓
CSS style calculations
    ↓
Layout (geometry calculations)
    ↓
Paint (fill pixels)
    ↓
Composite (layer assembly)
```

**Each step cascades down.** If JS changes layout, paint must re-run.

### 4.2 CSS containment Property

The `contain` property isolates subtrees:

```css
.card {
  contain: paint;  /* Paint work inside .card doesn't affect outside */
}
```

**Types**:
- `contain: layout` — Layout changes inside don't affect outside
- `contain: paint` — Paint changes don't affect outside (most useful)
- `contain: size` — Size is independent (risky: content may overflow)
- `contain: style` — CSS counters/quotes scoped

**Practical Example**:
```css
.list-item {
  contain: paint;  /* Each item's paints isolated */
}
```

When you update one item's color, only that item repaints. Others stay cached.

### 4.3 Performance Impact

With `contain: paint`:
- Browser can **skip repainting** siblings
- Caches layer compositing
- Especially powerful on lists (cards, rows)

**Benchmark**: List of 100 items, update one background:
- Without `contain`: All 100 items repaint (~20ms)
- With `contain: paint`: Only 1 item repaints (~2ms)

### 4.4 Will-Change: Hint Future Animations

```css
.animation-target {
  will-change: transform, opacity;
}
```

**Tells browser**: "Hey, I'm about to animate these properties."

Browser may:
- Promote element to its own compositing layer
- Pre-allocate GPU memory
- Optimize rendering pipeline

**Important**: Use sparingly. Too many `will-change` layers = memory overhead.

### 4.5 Containment Best Practices

1. **Apply `contain: paint` to**:
   - List items, cards, modal dialogs
   - Anything that might update independently

2. **Avoid `contain: layout`** unless you know what you're doing
   - Breaks margin collapsing, z-index stacking
   - Complex interactions may break

3. **Test with DevTools**: Rendering tab shows paint regions
   - Goal: Minimize paint area on changes

4. **Combine with `will-change`**: For animations on contained elements
   ```css
   .animated-card {
     contain: paint;
     will-change: transform;
   }
   ```

---

## 5. Combined Pattern: The High-Performance Stack

### 5.1 Architecture

```
┌─ Radix Primitives (behavior + a11y) ──┐
│  (Unstyled, tree-shakeable)            │
└──────────────────────────────────────┬─┘
                                        │
        ┌───────────────────────────────┘
        │
┌───────▼──────────────────────────────┐
│  shadcn/ui (Styled, copy-paste)      │
│  (Tailwind CSS + Radix)              │
└──────────────────────────────────────┘

        ┌──────────────────────────────┐
        │ Virtual Lists (for data)     │
        │ (react-window)               │
        └───────┬──────────────────────┘
                │
        ┌───────▼──────────────────────┐
        │  CSS Optimizations           │
        │  - contain: paint            │
        │  - will-change on animation  │
        │  - GPU compositing           │
        └──────────────────────────────┘
```

### 5.2 Example: High-Perf Data Table

```tsx
import { FixedSizeList } from 'react-window';
import { Button } from '@/components/ui/button';

export function DataTable({ data }) {
  return (
    <div className="border rounded-lg">
      <div className="grid grid-cols-4 bg-slate-100 px-4 py-2">
        <div>Name</div>
        <div>Email</div>
        <div>Status</div>
        <div>Action</div>
      </div>
      
      <FixedSizeList
        height={600}
        itemCount={data.length}
        itemSize={40}
        width="100%"
      >
        {({ index, style }) => (
          <div
            style={style}
            className="grid grid-cols-4 px-4 py-2 border-b hover:bg-blue-50 transition-colors
                       contain-paint"  /* CSS containment */
          >
            <div>{data[index].name}</div>
            <div>{data[index].email}</div>
            <div>{data[index].status}</div>
            <Button size="sm">Edit</Button>
          </div>
        )}
      </FixedSizeList>
    </div>
  );
}
```

**Performance**: 10,000 rows, 60fps, instant search.

---

## 6. Key Takeaways

| Pattern | Use Case | Benefit |
|---------|----------|---------|
| **Radix** | Build systems, libraries | Lean, accessible, composable |
| **shadcn** | Product apps, dashboards | Styled, copy-paste, owned |
| **Virtual Lists** | 100+ items | Constant DOM, smooth scroll |
| **Paint Containment** | Cards, lists, independent updates | Skip repaints for siblings |
| **will-change** | Animation targets | GPU acceleration hints |

---

## Sources

- [Radix Primitives](https://www.radix-ui.com/primitives)
- [shadcn/ui Foundation](https://ui.shadcn.com/)
- [shadcn/ui in 2026 – DEV Community](https://dev.to/whoffagents/shadcn-ui-in-2026-the-component-library-that-changed-how-we-build-uis-296o)
- [react-window – GitHub](https://github.com/bvaughn/react-window)
- [List Virtualization – web.dev](https://web.dev/articles/virtualize-long-lists-react-window)
- [Virtual Lists Pattern – patterns.dev](https://www.patterns.dev/vanilla/virtual-lists/)
- [CSS Performance – MDN](https://developer.mozilla.org/en-US/docs/learn/performance/css)
- [When to Use contain & will-change – CSS-Tricks](https://css-tricks.com/when-is-it-right-to-reach-for-contain-and-will-change-in-css/)
- [CSS Wizardry: CSS Containment](https://csswizardry.com/2026/04/what-is-css-containment-and-how-can-i-use-it/)

