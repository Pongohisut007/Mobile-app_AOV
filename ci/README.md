# CI behavior

## Pipeline paths

The component Multibranch jobs use `ci/Jenkinsfile.backend` and
`ci/Jenkinsfile.frontend`. Both files must exist on each branch that should build.
The root `Jenkinsfile` is not used. Disable any old combined job to avoid duplicate
builds and deployments. Build queueing applies per job/branch, not across jobs.

## Secret detection

Both component pipelines run Gitleaks on every branch/PR build, including FAST mode,
documentation changes, and changes unrelated to the job's component. Each job
checks the repository, rather than only its frontend/backend directory. Detection
failures stop the build, and reports redact secret values.

The `generic-api-key` rule's README allowlist requires BOTH the exact `backend/README.md` path and the
exact extracted example token `abc123def456`. Other secrets in that file are
still scanned. Git scanning retains its existing history scan behavior.

## Images and deployment

Backend images are pushed to Docker Hub (`docker.io/pongphisut/taskflow-api`,
public). The pipeline logs in with the Jenkins `dockerhub` credential
(Username with password: Docker Hub username + an access token with Read & Write
scope). The pipeline can read the existing `buildcache` tag; it no longer
updates that tag. The GitOps update changes `image.tag` and enables migrations;
the repository comes from the chart's `values.yaml`.

Image tags use the full checked-out commit SHA. Changes to CI/build configuration
therefore get a new tag even if the backend source is unchanged. Rerunning the
same commit is rebuilt locally, scanned, and tested before any registry push.
The first build after this change will use a new tag instead of the old 7-character
backend commit tag. Helm values continue receiving `IMAGE_TAG` as before.

Builds of the same job/branch queue with `disableConcurrentBuilds()` so an older
build cannot wait for approval and then deploy after a newer build. Builds already
running before this change should be finished or cancelled before relying on it.
Branch deploy rules remain: `develop` to staging, `main` to production with approval;
feature branches and PR jobs do not deploy. Approval still uses the pipeline's
existing 60-minute timeout.

## Verification

```sh
git diff --check
```

Run both Multibranch jobs to validate the pipelines with the installed Jenkins
plugins. Verify feature/PR builds scan secrets and do not deploy, and confirm
backend image scanning and E2E complete before approving production deployment.

## Migration and image promotion

`NODE_ENV=production` is used in both deployed environments. `APP_ENV` selects
staging or production application behavior. The migration job runs the migration
runner from the same image tag before the API Deployment is updated. Jenkins turns
on `migration.enabled` when it first updates a GitOps image tag containing the
runner. Existing tags must not run this job.

The current migrations are incremental and require an existing `users` and
`recipes` schema. A new empty cluster needs a reviewed baseline migration before
the first deployment. The runner fails explicitly if that baseline is absent.
The CI E2E stack creates the legacy schema with development synchronization,
runs the incremental migrations, then runs the HTTP tests with
`NODE_ENV=production` under both `APP_ENV=staging` and `APP_ENV=production`.
This exercises the upgrade path but does not replace a clean-database baseline
test.

Full PR builds build and scan a local Docker image; they do not receive Docker
Hub or GitOps write credentials. On `develop` and `main`, the verified local
image is pushed after Trivy, E2E, and (on `main`) SBOM verification pass. The
remote build cache is read but no longer updated by the pipeline.

## Android release gate

The `main` frontend build requires the Jenkins environment variable
`MOBILE_API_BASE_URL` to be an HTTPS API URL. It also requires these Jenkins
credentials: `android-upload-keystore` (file), `android-keystore-password`,
`android-key-alias`, and `android-key-password` (secret text). The gate builds
and archives a signed release App Bundle using `config/prod.json` with the API
URL injected for that build and mock purchases disabled. Until the URL and
credentials are configured, the `main` build fails deliberately. Debug builds
continue to use the shared debug key.

## Draft: remove DB_SYNCHRONIZE

`DB_SYNCHRONIZE` in the chart ConfigMap is currently unused by the backend.
Keep it during this change. After the migration job has been exercised against
an existing staging database and a baseline migration has been added and tested
for a fresh database, remove `config.dbSynchronize` from `values.yaml` and
`DB_SYNCHRONIZE` from `templates/configmap.yaml`. Keep schema behavior keyed to
the validated `APP_ENV`; never turn synchronization on in staging/production.
