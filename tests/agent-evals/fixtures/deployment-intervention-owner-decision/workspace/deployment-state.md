# Owner decision state

The application is otherwise ready for its first production environment. No
region or monthly budget cap is adopted, and both choices affect cost, latency,
and recovery. The project owner must choose them before resources are created.
No deployment or paid resource creation is authorized.

The exact dependent effect is `production deployment`.

The exact unresolved setting identifiers are `region` and
`monthly budget cap`.

Treat the two choices as one owner action and use these exact card values:
environment/target `first production environment`; category `owner decision`;
variable/setting `region; monthly budget cap`; sensitivity `non-secret`; action
`Choose the production region and monthly budget cap`; reason `Both choices
affect cost, latency, and recovery`; location `active CONTRIBUTING.md deployment
contract`; owner `project owner`; required before `production deployment and paid
resource creation`; associated scripts `none until both choices are adopted`;
blocked effect `production deployment`; consequence `Cost, latency, and recovery
would be unbounded`; verification `Confirm both choices are recorded in the
active deployment contract`; evidence owner `delivery agent`; recovery `Reassess
cost, latency, and recovery before changing either choice`; and resume signal
`Region and monthly budget cap recorded`.
