---
description: Run the comprehensive design consultation skill to establish the project's visual identity.
---

1. Evaluate the product context by reading `.agent/rules/10_project.md`, `README.md`, any existing `.agent/rules/11_design.md`, and **specifically reviewing `.agent/rules/23_design_system.md`** so you understand the structural constraints before proposing aesthetics. If `10_project.md` is empty or missing, suggest running the `/project` workflow first to gather context, as this workflow is designed to follow project setup.
2. Apply the `design-consultation` skill to research and propose typography, color palettes, spacing, and overall aesthetics. Have a conversation with the user to finalize the system. **Ensure you ask all clarification questions strictly one by one.**
3. Create a standalone `design_preview.html` file using `write_to_file` in the `artifacts` folder, demonstrating the chosen fonts, colors, and components in realistic layouts. Ask the user to open it.
4. Once the preview is approved, output `.agent/rules/11_design.md` with the necessary frontmatter.
5. Validate the resulting `11_design.md` against the architectural constraints in `.agent/rules/23_design_system.md` (ensure Tailwind @theme bindings are clear and CSS variable mapping is logically sound).
