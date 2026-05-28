# Low-Latency Interface Techniques

> Research into CSS containment, will-change, GPU compositing, and frame budgets for achieving 60fps responsiveness on every interaction.

**Date**: 2026-05-28  
**For**: Luxi Oracle — Latency Elimination

---

## 1. Frame Budget Fundamentals

### 1.1 The 16.6ms Target

At **60 frames per second**, the browser has **16.66 milliseconds** per frame to:
1. Execute JavaScript
2. Calculate styles
3. Layout (geometry)
4. Paint (pixels)
5. Composite (layers)

**But**: Browser overhead means **practical budget ≈ 10ms** for developer code.

```
┌─ 16.66ms Frame ──────────────────────┐
│                                       │
│  Browser Overhead: ~6.66ms           │
│  Your Code Budget: ~10ms             │
│  (JS + Style + Layout + Paint)       │
│                                       │
│  Composite: Browser handles (fast)   │
│                                       │
└───────────────────────────────────────┘
```

### 1.2 Why Frame Budget Matters

Miss the budget = frame drops:

- **60fps**: Smooth, natural (users don't notice)
- **30fps**: Every other frame drops, noticeable jank
- **15fps**: Feels like slideshow, interaction delays

**User perception**:
- Scroll stutter: Impossible to read
- Button click delay: Feels broken
- Animation stutter: Unprofessional

### 1.3 Measuring Your Frame Time

**Chrome DevTools** → Performance tab:

1. Open DevTools (F12)
2. Click "Performance" tab
3. Hit the record button (red circle)
4. Interact with your UI (scroll, click, type)
5. Stop recording
6. Look at **flame chart** → Each bar = a frame
   - Green bar (< 16.6ms): Good ✓
   - Red bar (> 16.6ms): Jank ✗

---

## 2. The Pixel Pipeline: What Triggers What

### 2.1 Complete Pipeline (Most Expensive)

```
JavaScript ──→ Recalculate Style ──→ Layout ──→ Paint ──→ Composite
```

**Triggered by**: Changing layout properties
```javascript
element.style.width = '100px';   // Triggers FULL pipeline
```

**Time**: ~15-20ms for complex DOM

### 2.2 Skip Layout (Faster)

```
JavaScript ──→ Recalculate Style ──→ Paint ──→ Composite
                (Layout skipped)
```

**Triggered by**: Paint properties (colors, shadows, filters)
```javascript
element.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)';  // No layout
```

**Time**: ~5-10ms

### 2.3 Compositor Only (Fastest)

```
JavaScript ──→ Recalculate Style ──→ Composite
              (Layout & Paint skipped)
```

**Triggered by**: `transform` and `opacity` ONLY
```javascript
element.style.transform = 'translateX(100px)';  // GPU handles
element.style.opacity = 0.5;                     // GPU handles
```

**Time**: < 1ms (GPU-accelerated)

### 2.4 Pipeline Strategy

**Optimization Hierarchy**:

1. **Best**: Use `transform` or `opacity`
   - Cost: < 1ms
   - GPU accelerated
   - Use for: Animations, hover effects, transitions

2. **Good**: Use paint properties (background, shadow, color)
   - Cost: 5-10ms
   - Still acceptable for 60fps
   - Use for: Hover states, theme changes

3. **Avoid**: Trigger layout changes
   - Cost: 15-20ms
   - Often breaks frame budget
   - Use only when necessary

**Example: Bad vs Good Animation**

```css
/* ❌ BAD: Triggers layout on every frame */
.box {
  animation: slide-bad 2s infinite;
}

@keyframes slide-bad {
  0% { left: 0; }              /* Layout property */
  100% { left: 100px; }        /* Each frame: JS → Style → Layout → Paint → Composite */
}

/* ✓ GOOD: GPU accelerated */
.box {
  animation: slide-good 2s infinite;
}

@keyframes slide-good {
  0% { transform: translateX(0); }      /* Compositor property */
  100% { transform: translateX(100px); } /* Each frame: Composite only (~1ms) */
}
```

**Performance difference**: 15ms → 1ms (15x faster!)

---

## 3. CSS Containment: Isolating Render Work

### 3.1 The Containment Principle

When you change one element, browser must check if siblings/parents affected:

```
┌─ Parent ──────────────────────┐
│  ┌─ Child A ─────────────┐    │
│  │ [Repaint entire tree] │    │ ← Change Child A's color
│  └───────────────────────┘    │    Browser recalculates:
│  ┌─ Child B ─────────────┐    │    - Parent layout affected?
│  │ (Why rerender me?)    │    │    - Siblings affected?
│  └───────────────────────┘    │    - Cascades everywhere
│  ┌─ Child C ─────────────┐    │
│  │ (And me?)             │    │
│  └───────────────────────┘    │
└───────────────────────────────┘
```

**Solution**: Tell browser "changes inside stay inside":

```css
.child {
  contain: paint;  /* "I'm isolated. Don't check outside." */
}
```

```
┌─ Parent ──────────────────────┐
│  ┌─ Child A ─────────────┐    │
│  │ contain: paint ✓      │    │ ← Change Child A's color
│  │ [Repaint ONLY this]   │    │    Browser: "OK, just A"
│  └───────────────────────┘    │    Siblings untouched ✓
│  ┌─ Child B ─────────────┐    │
│  │ (Unchanged, cache ok) │    │
│  └───────────────────────┘    │
│  ┌─ Child C ─────────────┐    │
│  │ (Unchanged, cache ok) │    │
│  └───────────────────────┘    │
└───────────────────────────────┘
```

### 3.2 Types of Containment

#### Paint Containment (Most Useful)

```css
.card {
  contain: paint;
}
```

**Promise**: "Changes inside (colors, shadows, backgrounds) won't affect outside."

**Benefit**: Browser skips repainting siblings.

**Impact**: 
- Updating one card in a 100-card list
- Without contain: All cards repaint (~20ms)
- With contain: One card repaints (~2ms)

#### Layout Containment

```css
.sidebar {
  contain: layout;
}
```

**Promise**: "Layout changes inside won't cascade outside."

**Warning**: Can break margin collapsing, z-index stacking. Use carefully.

#### Size Containment

```css
.widget {
  contain: size;
}
```

**Promise**: "Size is independent, no relayout needed."

**Risk**: Content might overflow. Not commonly used.

#### Combined

```css
.list-item {
  contain: layout paint;  /* Layout + Paint both isolated */
}
```

### 3.3 Containment Limitations

**Doesn't Help**:
- Content overflow (still paints if it overflows)
- Reflow outside the container
- Size changes to sibling elements

**Works Best For**:
- Repeated patterns (lists, grids, cards)
- Independent updates (one item changes, others don't)

### 3.4 Practical Example: Card List

```html
<div class="card-list">
  <div class="card">
    <h2>Title 1</h2>
    <p>Description</p>
    <button>Action</button>
  </div>
  <!-- 100 more cards -->
</div>
```

```css
.card {
  contain: paint;  /* Each card isolated */
}

.card:hover {
  background-color: #f0f0f0;  /* Only this card repaints */
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}
```

**Result**: Smooth hover effects on 100+ cards without jank.

---

## 4. Will-Change: Hint Future Animations

### 4.1 What is will-change?

```css
.element {
  will-change: transform, opacity;
}
```

**Tells the browser**: "Hey, I'm about to animate these properties. Optimize ahead of time."

Browser may:
- Pre-allocate GPU memory
- Create a new compositing layer
- Skip some rendering optimizations that would be wasted

### 4.2 Why It Helps

Without `will-change`:
```css
.box {
  transition: transform 0.3s;
}

/* First time animating... browser realizes, "Oh! This triggers compositor layer!" */
/* Allocates GPU memory, sets up layer (laggy first frame) */
```

With `will-change`:
```css
.box {
  will-change: transform;
  transition: transform 0.3s;
}

/* Browser knows ahead: "I need a compositor layer ready." */
/* Allocated before animation starts (smooth first frame) */
```

### 4.3 Proper Usage (Important!)

**Correct**:
```css
.button {
  will-change: transform;
}

.button:hover {
  transform: scale(1.05);
}
```

**Wrong** (Performance anti-pattern):
```css
.button {
  will-change: transform;
  animation: rotating 2s infinite;  /* Don't animate the will-change property itself */
}
```

**Best Practice**: Remove after animation ends
```javascript
const element = document.querySelector('.animated');

// Before animation
element.style.willChange = 'transform';

// Start animation
element.classList.add('animating');

// Animation ends (listen to transitionend)
element.addEventListener('transitionend', () => {
  element.style.willChange = 'auto';  // Release GPU memory
});
```

### 4.4 Caveats

- **Too many `will-change` elements**: GPU memory bloats (< 5-10 max)
- **Not a magic fix**: Fundamentally expensive ops stay expensive
- **Mobile consideration**: GPU resources more limited, use sparingly
- **Long animations**: Remove `will-change` after setup, re-add if needed

---

## 5. GPU Compositing: Moving Work to the GPU

### 5.1 Main Thread vs GPU Thread

**Main Thread** (JavaScript, Layout, Paint):
- Single-threaded
- Handles DOM, styling, calculations
- **Limited budget: 10ms per frame**

**GPU Thread** (Compositing):
- Offloads rendering to graphics card
- Handles layer assembly, transforms, blending
- **Unlimited budget (parallel hardware)**

### 5.2 What Promotes to GPU Layer

The browser automatically creates a compositing layer for:

1. **3D transforms**
   ```css
   transform: rotateX(45deg) translateZ(10px);
   ```

2. **Opacity changes with animation**
   ```css
   animation: fade 1s;
   @keyframes fade {
     0% { opacity: 1; }
     100% { opacity: 0; }
   }
   ```

3. **Elements with `will-change: transform` or `will-change: opacity`**
   ```css
   will-change: transform;
   ```

4. **Fixed positioning**
   ```css
   position: fixed;
   ```

5. **Elements with certain filters**
   ```css
   filter: blur(10px);
   ```

### 5.3 Explicit Layer Promotion

Force a layer with transform hack (legacy, mostly unnecessary now):

```css
.element {
  transform: translateZ(0);  /* Creates a layer without visible transform */
  will-change: auto;         /* Cleaner modern approach */
}
```

Better: Use `will-change` explicitly.

### 5.4 Layer Proliferation Danger

**Too many compositing layers = Memory overhead**:

```css
/* ❌ BAD: 1000 divs with individual layers */
.item {
  will-change: transform;
}

/* ✓ GOOD: Single parent layer */
.list {
  will-change: transform;
}

.list .item {
  /* No will-change, uses parent's layer */
}
```

**Benchmark**:
- 100 elements with `will-change` each: ~200MB GPU memory (overkill)
- 1 parent with `will-change`: ~2MB (efficient)

### 5.5 GPU Compositing Checklist

```
[ ] Use transform/opacity for animations (not layout properties)
[ ] Apply will-change only to elements you're animating
[ ] Remove will-change after animation ends
[ ] Monitor GPU memory usage (DevTools → More tools → Rendering)
[ ] Keep layer count < 20 per viewport
[ ] Test on mobile (limited GPU resources)
```

---

## 6. Bringing It Together: Low-Latency Architecture

### 6.1 Interaction → Display Latency

**Goal**: Milliseconds from user input to visual feedback.

```
User presses button
    ↓
Browser fires mousedown event
    ↓
JavaScript runs (onClick handler) [< 5ms budget]
    ↓
Styles recalculated [< 2ms]
    ↓
No layout needed (only transform) [✓ Skipped]
    ↓
Paint skipped (compositor layer exists) [✓ Skipped]
    ↓
GPU composites transform [< 1ms, parallel]
    ↓
✓ Visual feedback in < 10ms (one frame!)
```

### 6.2 Example: Responsive Button

```tsx
import React from 'react';

export function LowLatencyButton() {
  const handleMouseDown = (e) => {
    // Minimal JS work
    e.currentTarget.classList.add('pressed');
  };

  const handleMouseUp = (e) => {
    e.currentTarget.classList.remove('pressed');
  };

  return (
    <button
      onMouseDown={handleMouseDown}
      onMouseUp={handleMouseUp}
      className="button"
    >
      Click Me
    </button>
  );
}
```

```css
.button {
  will-change: transform;
  transition: transform 0.1s cubic-bezier(0.1, 0.9, 0.2, 1);
}

.button.pressed {
  transform: scale(0.95);  /* GPU accelerated, ~1ms */
}

.button:hover {
  transform: scale(1.05);  /* GPU accelerated, ~1ms */
}
```

**Result**: Button press feels instant, no lag.

### 6.3 Example: Smooth Scroll List

```css
.list-container {
  contain: paint layout;  /* Isolate from outside */
  overflow-y: auto;
}

.list-item {
  contain: paint;  /* Each item independent */
  transition: background-color 0.2s;  /* Paint property (safe) */
}

.list-item:hover {
  background-color: #f0f0f0;  /* Only this item repaints */
}

.list-item.active {
  background-color: #e0e0e0;
}
```

**Performance**: 1000 items, smooth scroll + hover, no jank.

---

## 7. Debugging & Measurement

### 7.1 Chrome DevTools: Rendering Tab

**Location**: DevTools → More tools → Rendering

**Useful features**:
- **Paint flashing**: Shows what's being painted (green overlay)
- **Rendering stats**: FPS meter, frame time
- **Layer borders**: Visualize compositing layers
- **Frame rate**: Real-time FPS counter

### 7.2 Performance Tab (Detailed)

**Steps**:
1. Open DevTools → Performance
2. Click record (red circle)
3. Interact with UI (scroll, click, hover)
4. Stop recording
5. Analyze flame chart:
   - **Purple (Rendering)**: JS + Style + Layout + Paint
   - **Green (Composite)**: Fast (GPU)

Goal: Keep purple blocks < 10ms, maximize green.

### 7.3 Lighthouse (Automated Metrics)

**Run**: DevTools → Lighthouse

Generates report with:
- **Interaction to Next Paint (INP)**: Latency metric (target < 200ms)
- **First Contentful Paint (FCP)**: Time to first content
- **Cumulative Layout Shift (CLS)**: Unexpected movement

---

## 8. Key Takeaways

| Technique | Budget | Benefit | Use For |
|-----------|--------|---------|---------|
| **Frame Budget (10ms)** | Constraint | Ensures 60fps | All interactions |
| **Transform/Opacity** | < 1ms | GPU accelerated | Animations, transitions |
| **Paint Properties** | 5-10ms | Skip layout | Hover, color changes |
| **contain: paint** | Scales | Isolates repaints | Lists, cards, repeated elements |
| **will-change** | Prep | Pre-allocate GPU | Before animations |
| **GPU Compositing** | Parallel | Offload to GPU | Animations, transforms |

---

## Sources

- [Web.dev: Rendering Performance](https://web.dev/articles/rendering-performance/)
- [WebKit: Rendering Frames Timeline](https://webkit.org/blog/3996/introducing-the-rendering-frames-timeline/)
- [MDN: CSS Performance](https://developer.mozilla.org/en-US/docs/learn/performance/css)
- [CSS-Tricks: When to Use contain & will-change](https://css-tricks.com/when-is-it-right-to-reach-for-contain-and-will-change-in-css/)
- [SitePoint: Hardware Acceleration with CSS](https://www.sitepoint.com/introduction-to-hardware-acceleration-css-animations/)
- [Medium: 120fps and no jank – surma.dev](https://surma.dev/things/120fps/)
- [Smashing Magazine: GPU Animation](https://www.smashingmagazine.com/2016/12/gpu-animation-doing-it-right/)

