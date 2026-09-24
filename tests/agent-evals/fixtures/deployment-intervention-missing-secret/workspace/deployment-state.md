# Production deployment state

Laravel Cloud production is the adopted target. The application requires
`APP_KEY`; non-secret Cloud metadata confirms that its name is absent from the
production variable inventory. A local `.env` contains a value, but it must not
be read, copied wholesale, printed, or requested in chat. Only the environment
administrator can enter the value in the Cloud dashboard. The production
deployment is not authorized and must not run.

Use these exact card values: environment/target `Laravel Cloud production`;
category `secret/access`; variable/setting `APP_KEY`; sensitivity `secret`;
action `Enter APP_KEY without sharing its value`; reason `APP_KEY is required
and absent from production metadata`; secure location `Laravel Cloud production
dashboard`; owner `environment administrator`; required before and blocked
effect `production deployment`; associated scripts `none identified`;
consequence `Production would deploy without the required APP_KEY`; verification
`Confirm APP_KEY is present using non-secret production variable metadata and
the adopted pre-deploy configuration probe succeeds`; evidence owner `deployment
agent`; recovery `Keep production undeployed until verification succeeds`; and
resume signal `APP_KEY configured in Laravel Cloud production`.
