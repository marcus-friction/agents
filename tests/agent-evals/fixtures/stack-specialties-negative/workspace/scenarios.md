# Stack decisions

- A one-field Laravel endpoint has a tiny, route-local input check.
- A Nuxt/Nitro service owns a protected resource; Laravel is not in that path.
- A Vue 3 component already uses typed `<script setup>`.
- The installed project uses stable Vite 8.
- A Redis cache is disposable and has a tested rebuild path.
