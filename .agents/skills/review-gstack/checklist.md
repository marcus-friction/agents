# 📝 `review-gstack` Review Heuristics Checklist

This checklist defines the strict rules for **Step 2: The Two-Pass Code Review**.

## 🚨 PASS 1: CRITICAL AND FATAL FLAWS
You must review the diff specifically looking *only* for these catastrophic failure modes. If any are found, they immediately enter the **ASK** batch.

1. **SQL & Data Safety**
   - String interpolation in SQL? Unsafe ORM raw updates?
   - TOCTOU races (check-then-set) instead of atomic `update_all`.
2. **Race Conditions & Concurrency**
   - Read-check-write without uniqueness constraint?
   - Status transitions without atomic `WHERE old_status` clauses?
3. **LLM Trust Boundaries**
   - Are LLM outputs treated as completely untrusted?
   - Are structured outputs validated before database write?
4. **Enum & Value Completeness**
   - If adding a new enum/status, *trace every consumer*. Did we forget to handle the new value in a switch/if block?

---

## 🔍 PASS 2: INFORMATIONAL & ARCHITECTURAL FLAWS
Review for clean code, performance, and maintainability.

1. **Performance & Bundle Impact**
   - Missing eager loading (N+1 loops).
   - Heavy new NPM dependencies, synchronous scripts, or CSS `@import`.
   - Missing `loading="lazy"` or explicit sizing on images.
2. **Conditional Side Effects**
   - Does a branch update a record but forget the associated side effect?
3. **Edge Cases, Network & Failure States**
   - What happens if the third-party API times out or returns 500?
4. **Crypto, Time & Types**
   - Truncation instead of hashing? Non-constant time comparison?
   - Time window mismatches (e.g. daily vs hourly buckets)?
   - Type coercion hazards at API boundaries (`"8"` vs `8`)?
5. **Dead/Magic Code & CI/CD**
   - CI workflow changes pushing broken tags or unmapped secrets?
   - Magic numbers, unused variables, stale comments (AUTO-FIX).
6. **Code Slop & Hallucination Scan**
   - Hallucinated framework methods or non-existent package exports?
   - Overly generic wrapper abstractions that wrap a single call site without added value?
   - Redundant try/catch blocks that swallow errors silently or rethrow generic exceptions?
   - Leftover debugging artifacts, scratch dumps, or `console.log` / `dd()` statements?

---

## 🚫 SUPPRESSIONS (DO NOT FLAG THESE)
- "X is redundant with Y" when harmlessly aiding readability.
- Suggesting comments for tuned thresholds/constants (they rot).
- Minor consistency refactors for the sake of consistency.
- Harmless no-ops (e.g. Rejecting something never in the array).
- devDependencies additions or dynamic `import()` code-splitting.

## ⚖️ See Something, Say Something
- If the file is dirty, and you are touching it, **fix it** (mechanical issues silently -> AUTO-FIX, ambiguity -> ASK).
