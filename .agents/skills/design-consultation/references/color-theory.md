# Color Theory Reference

Design color knowledge for proposals, sourced from [garrytan/gstack](https://github.com/garrytan/gstack) design-consultation skill.

## Color Approaches
| Approach | Description | When to Use |
|----------|-------------|-------------|
| **Restrained** | 1 accent + neutrals. Color is rare and meaningful. | Enterprise, tools, data-heavy apps |
| **Balanced** | Primary + secondary + semantic colors for hierarchy. | SaaS, consumer apps, dashboards |
| **Expressive** | Color as a primary design tool. Bold palettes. | Creative tools, consumer brands, marketing |

## Aesthetic Directions
| Direction | Character | Pairs With |
|-----------|-----------|------------|
| Brutally Minimal | Type and whitespace only. No decoration. | Restrained color, minimal motion |
| Maximalist Chaos | Dense, layered, pattern-heavy. Y2K meets contemporary. | Expressive color, expressive motion |
| Retro-Futuristic | Vintage tech nostalgia. CRT glow, pixel grids. | Balanced color, intentional motion |
| Luxury/Refined | Serifs, high contrast, generous whitespace. | Restrained color, minimal motion |
| Playful/Toy-like | Rounded, bouncy, bold primaries. Approachable. | Expressive color, expressive motion |
| Editorial/Magazine | Strong typographic hierarchy, asymmetric grids. | Balanced color, intentional motion |
| Brutalist/Raw | Exposed structure, system fonts, visible grid. | Restrained color, minimal motion |
| Art Deco | Geometric precision, metallic accents, symmetry. | Balanced color, intentional motion |
| Organic/Natural | Earth tones, rounded forms, hand-drawn texture. | Balanced color, intentional motion |
| Industrial/Utilitarian | Function-first, data-dense, monospace accents. | Restrained color, minimal motion |

## Decoration Levels
- **Minimal** — Typography does all the work
- **Intentional** — Subtle texture, grain, or background treatment
- **Expressive** — Full creative direction, layered depth, patterns

## Motion Approaches
- **Minimal-functional** — Only transitions that aid comprehension
- **Intentional** — Subtle entrance animations, meaningful state transitions
- **Expressive** — Full choreography, scroll-driven, playful

## AI Slop Anti-Patterns (never include)
- Purple/violet gradients as default accent
- 3-column feature grid with icons in colored circles
- Centered everything with uniform spacing
- Uniform bubbly border-radius on all elements
- Gradient buttons as the primary CTA pattern
- Generic stock-photo-style hero sections
- "Built for X" / "Designed for Y" marketing copy patterns

## Coherence Rules
When a user overrides one design dimension, check if the rest still coheres:
- Brutalist aesthetic + expressive motion → unusual — flag gently
- Expressive color + restrained decoration → bold palette carries all weight — validate intent
- Creative-editorial layout + data-heavy product → can fight density — suggest hybrid
- Always accept the user's final choice. Never refuse to proceed.
