# Mixed intervention state

Three user-owned actions exist for production. `dns-cname` is missing and is
`required`. `payments-key` was reported configured but cannot be safely verified
and is `unverified`. `app-key` passed safe verification and is `completed`.
Production deployment is not authorized and must remain blocked. The exact
dependent effect is `production deployment`.

For `dns-cname`, use these exact card values: environment/target `production`;
category `secret/access`; variable/setting `DNS CNAME`; sensitivity `non-secret`;
action `Create the production DNS CNAME`; reason `The production hostname does
not resolve to the adopted ingress`; location `authoritative DNS provider`;
owner `DNS administrator`; required before and blocked effect `production
deployment`; associated scripts `none identified`; consequence `Production would
launch without its adopted hostname`; verification `Confirm the authoritative
CNAME and public resolution match the adopted ingress`; evidence owner
`deployment agent`; recovery `Keep the old DNS record available until the new
target is verified`; resume signal `Production CNAME created`.

For `payments-key`, use these exact card values: environment/target `production
payments service`;
category `secret/access`; variable/setting `PAYMENTS_KEY`; sensitivity `secret`;
action `Provide read-only PAYMENTS_KEY verification access`; reason `Configuration
was reported but safe verification is unavailable`; location `production
platform access controls`; owner `environment administrator`; required before
`payments activation and production deployment`; blocked effect `production
payments activation`; associated scripts `payments pre-deploy configuration
probe`;
consequence `Production could launch without a verified payments key`;
verification `Confirm PAYMENTS_KEY is present using non-secret metadata and the
adopted pre-deploy configuration probe succeeds`; evidence owner `payments
deployment agent`; recovery `Keep payments activation blocked until verification
succeeds`;
resume signal `PAYMENTS_KEY verification access is available`.
