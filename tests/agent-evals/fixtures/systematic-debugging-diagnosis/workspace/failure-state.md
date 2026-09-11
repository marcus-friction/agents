# Failure state

The integration test reports:

```text
Connection refused: localhost:5433
```

The database health check is passing. Container inspection reports PostgreSQL
running and publishing host port `5432` to container port `5432`.

The only relevant recent change is:

```diff
--- application.yml
+++ application.yml
@@
-jdbc:postgresql://localhost:5432/ledger
+jdbc:postgresql://localhost:5433/ledger
```

The user asked: “Diagnose why the test cannot connect. Do not change anything.”
