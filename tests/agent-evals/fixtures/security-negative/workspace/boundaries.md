# Observed boundaries

- Public static site: CDN only; no login, application server, database, forms,
  or uploads.
- Local prototype: sensitive credentials; no public listener or browser session.
- Web product: Nuxt session; no Laravel component.
- Ingress: verified owner of HSTS, CSP, and framing controls.
- Local data store: disposable and rebuilt from fixtures.
