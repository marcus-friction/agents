# 🎨 `review-gstack` Design Heuristics Checklist

This checklist defines the strict rules for **Step 3: Conditional Design Review**. It is only invoked if frontend files (Vue/Nuxt, Blade, Tailwind, CSS) are modified.

You are enforcing the `23_design_system.md` standards and basic usability. 

## ⚖️ 1. Classifier: Marketing vs App UI
Before evaluating, determine what type of UI you are looking at:
- **MARKETING/LANDING PAGE:** First viewport composition, brand-forward, big typography, full-bleed hero, conversion-focused.
- **APP UI:** Workspace-driven, dense but readable, utility language, calm surface hierarchy, task-focused.
- **HYBRID:** Marketing shell with app-like sections.

## 🛑 2. Hard Rejections
If ANY of these apply to the diff, immediately add to the **ASK** batch. Do not auto-fix.
1. Generic SaaS card grid as the first impression.
2. Beautiful image with a weak brand.
3. Strong headline with no clear action.
4. Busy imagery behind text.
5. Sections repeating the same mood statement.
6. Carousels with no narrative purpose.
7. APP UI made of stacked cards instead of a unified layout.

## 🧪 3. The 7 Litmus Checks
Answer YES or NO (if NO, flag it):
1. Is the Brand/Product unmistakable in the first screen?
2. Is there ONE strong visual anchor present?
3. Is the page understandable by scanning headlines only?
4. Does each section have ONE job?
5. Are cards actually necessary (or just decorative formatting)?
6. Does motion improve hierarchy or atmosphere?
7. Would the design feel premium with ALL decorative shadows removed?

## 🤖 4. The 10-Item AI Slop Blacklist
If you see any of these patterns, they are **AUTO-FIX** deletions or rewrites.
1. Purple/violet/indigo gradient backgrounds.
2. **The 3-column feature grid:** icon-in-colored-circle + bold title + 2-line description repeated 3x symmetrically.
3. Icons in colored circles as general section decoration.
4. Centered everything (`text-center` on all headings, descriptions, and cards).
5. Uniform bubbly `border-radius` on every element.
6. Decorative blobs, floating circles, or wavy SVG dividers.
7. Emoji as core design elements (e.g., rockets in headings).
8. Colored left-borders on cards.
9. Generic hero copy ("Welcome to X", "Unlock the power of", "Your all-in-one solution").
10. Cookie-cutter section rhythm (hero -> 3 features -> testimonials -> pricing -> CTA) all exactly the same height.

## ⚙️ 5. Mechanical State Matrix & Empty States
- **The 4 States:** Every interactive element must have Default, Hover, Active/Focus, and Disabled/Loading states. (AUTO-FIX).
- **Empty State Rule:** "No items found" is NOT a design. Every empty state needs warmth, a primary action, and context. (ASK).

## 📱 6. Responsive & Accessibility Check
- Is there an explicit mobile fallback (e.g. `flex-col md:flex-row`)?
- Image `alt` tags and Button `aria-label`s present? (AUTO-FIX).
- Subtraction Default: Can lines/borders be replaced by whitespace? (ASK).
