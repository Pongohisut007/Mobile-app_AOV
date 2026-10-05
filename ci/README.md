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

Image tags use the full checked-out commit SHA. Changes to CI/build configuration
therefore get a new tag even if the backend source is unchanged. Rerunning the
same commit may reuse its existing image, which is still scanned and tested.
The first build after this change will use a new tag instead of the old 7-character
backend commit tag. Helm values continue receiving `IMAGE_TAG` as before.

Builds of the same job/branch queue with `disableConcurrentBuilds()` so an older
build cannot wait for approval and then deploy after a newer build. Builds already
running before this change should be finished or cancelled before relying on it.
Branch deploy rules remain: `develop` to staging, `main` to production with approval;
feature branches and PR jobs do not deploy. Approval still uses the pipeline's
existing 60-minute timeout.

## Local checks

```sh
groovy ci/tests/check-pipelines.groovy
bash ci/tests/check-secrets.sh
git diff --check
```

These checks cover Groovy syntax, component selection, unconditional secret stages,
build queue declarations, and execution of the actual image-tag resolution code.
Jenkins plugin validation and registry/deployment integration still require a CI run.
