---
name: copywriting
description: |
  Writing principles and best practices for clear, compelling, and user-centric 
  marketing and UI copy. Use this skill when generating landing pages, 
  writing UI microcopy, crafting CTAs, composing emails, writing product
  descriptions, feature announcements, or changelog entries.
---

# Copywriting Skill

This skill provides a structured framework for writing clear, compelling, and effective copy. When invoked to write or review copy, apply these principles meticulously.

## 1. Before Writing Context Gathering

Before generating any copy, you must establish the operational context. First, check if `.agent/rules/10_project.md` exists and contains real project data (not just HTML comments). This file serves as your primary product marketing context (detailing Vision, Goals, Users, and Constraints).

If `.agent/rules/10_project.md` does not exist or contains only placeholder comments, gather the essential context conversationally (product purpose, target audience, tone/voice, key differentiators). If the answers are generally relevant to the project beyond this one task, document them to `.agent/rules/10_project.md` so future sessions benefit.

If `.agent/rules/10_project.md` exists, **do not ask the user for this information again**. Use it directly. Only ask about the specific task:
*   **Page Purpose:** What type of page or component is this? What is the ONE primary action you want visitors to take?
*   **Traffic Context:** Where is the traffic coming from? What do visitors already know before arriving?

If `.agent/rules/10_project.md` does not exist or is empty, ask the user to run the `/project` workflow to establish the product baseline first.

## 2. Core Copywriting Principles

*   **Clarity Over Cleverness:** If you have to choose between clear and creative, always choose clear.
*   **Benefits Over Features:** Features are what it does. Benefits are what that means for the customer.
*   **Specificity Over Vagueness:** 
    *   *Vague:* "Save time on your workflow."
    *   *Specific:* "Cut your weekly reporting from 4 hours to 15 minutes."
*   **Customer Language:** Mirror voice-of-customer. Use words they actually use.
*   **One Idea Per Section:** Each section should advance one argument to build a logical flow.

## 3. Writing Style Rules

1.  **Simple over complex** — "Use" not "utilize," "help" not "facilitate".
2.  **Specific over vague** — Avoid buzzwords like "streamline," "optimize," "innovative."
3.  **Active over passive** — "We generate reports" not "Reports are generated."
4.  **Confident over qualified** — Remove filler words like "almost," "very," "really."
5.  **Show over tell** — Describe the outcome directly.
6.  **Honest over sensational** — Fabricated statistics or testimonials erode trust.

### Quick Quality Check (Line-by-Line)
When reviewing your own generated copy, ensure:
*   No confusing jargon.
*   No run-on sentences trying to do too much.
*   No passive voice.
*   No exclamation points (remove them).
*   No marketing buzzwords without substance.

## 4. Best Practices

*   **Be Direct:** Get to the point.
    *   *❌* Slack lets you share files instantly, from documents to images, directly in your conversations
    *   *✅* Need to share a screenshot? Send as many documents, images, and audio files as your heart desires.
*   **Use Rhetorical Questions:** Engage readers gently ("Tired of chasing approvals?").
*   **Use Analogies:** Make abstract concepts concrete.
*   **Pepper in Humor (When Appropriate):** Only if it fits the brand and doesn't undermine clarity.

## 5. Page Structure Framework

### Above the Fold (Hero)
*   **Headline:** Your single most important message. Specific > generic.
    *   *Formulas:* "{Achieve outcome} without {pain point}", "The {category} for {audience}".
*   **Subheadline:** Expands on the headline in 1-2 sentences max.
*   **Primary CTA:** Action-oriented button text communicating what they get ("Start Free Trial" > "Sign Up").

### Call-to-Action (CTA) Copy
*   **Weak (avoid):** Submit, Sign Up, Learn More, Click Here, Get Started.
*   **Strong (use):** Start Free Trial, Get [Specific Thing], See [Product] in Action, Create Your First [Thing].

## 6. Page-Specific Guidance

*   **Homepage:** Lead with the broadest value proposition. Provide clear routing paths.
*   **Landing Page:** Single message, single CTA. Match headline to the traffic source.
*   **Pricing Page:** Help visitors choose the right plan. Address "which is right for me?" anxiety.
*   **Feature Page:** Connect feature → benefit → outcome. Clear path to try/buy.
*   **About Page:** Tell the story of why you exist. Connect mission to customer benefit.

## 7. Execution & Output Format

Before outputting copy, establish the voice and tone (casual vs. formal, playful vs. serious). Maintain consistency, noting that headlines can be bolder while body copy must remain clear.

**When writing copy for the user, output in the following format:**
1.  **Page Copy:** Organized by section (Headline, Subhead, body, CTAs).
2.  **Annotations:** Briefly explain *why* you made key choices and which principle it applies.
3.  **Alternatives:** Provide 2-3 options for Headlines and primary CTAs with brief rationales.

## 8. References

See the following internal references for specific frameworks and language patterns:
*   **[Copy Frameworks](references/copy-frameworks.md)**: Headline formulas, logical landing page sections, and structural templates.
*   **[Natural Transitions](references/natural-transitions.md)**: Vocabulary for moving between points smoothly and introducing evidence without sounding robotic.
