# Unverified intervention state

The environment administrator reports that `APP_KEY` was added to Laravel
Cloud production. Current credentials cannot inspect even non-secret variable
presence metadata, and no deployment or application probe has verified that
the environment consumes the setting. The project contract does not accept a
self-report as sufficient verification. Production deployment remains
unauthorized.

The exact dependent effect is `production deployment`.

Use these exact card values: environment/target `Laravel Cloud production`;
category `secret/access`; variable/setting `APP_KEY`; sensitivity `secret`;
action `Grant read-only production verification access`; reason `Current
credentials cannot verify APP_KEY presence or consumption`; secure location
`Laravel Cloud production access controls`; owner `environment administrator`;
required before and blocked effect `production deployment`; associated scripts
`none identified`; consequence `Production could deploy without a verified
APP_KEY`; verification `Confirm APP_KEY is present using non-secret production
variable metadata and the adopted pre-deploy configuration probe succeeds`;
evidence owner `deployment agent`; recovery `Keep production blocked until
verification succeeds`; and resume signal `Read-only production verification
access is available`.
