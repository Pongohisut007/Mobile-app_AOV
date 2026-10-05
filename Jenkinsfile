pipeline {
    // agent any

    agent {
        kubernetes {
            yamlFile 'ci/pods/backend.yaml'
            defaultContainer 'ci'
        }
    }
    // tools {
    //     nodejs 'node26'
    // }

    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'

        GITOPS_REPO   = 'https://github.com/Alivefordie/Mobile-app_AOV-Gitops.git'
        GITOPS_BRANCH = 'main'
        GITOPS_DIR    = 'gitops'

        TASKFLOW_CHART = 'taskflow-chart'
    }

    options {
        timeout(time: 60, unit: 'MINUTES')

        parallelsAlwaysFailFast()
    }

    stages {
        stage('Environment') {
            steps {
                script {
                    def isFeatureBranch =
                        env.BRANCH_NAME ==~ /^feature\/.+/

                    def isPullRequest =
                        env.CHANGE_ID?.trim()

                    if (isFeatureBranch && !isPullRequest) {
                        env.CI_MODE = 'FAST'
                    } else {
                        env.CI_MODE = 'FULL'
                    }

                    env.COMMIT_SHA = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()

                    env.COMMIT_MESSAGE = sh(
                        script: 'git log -1 --pretty=%s',
                        returnStdout: true
                    ).trim()

                    // Include all changes since the last successful build. A
                    // first build or a missing baseline must run both suites.
                    def baseCommit = env.GIT_PREVIOUS_SUCCESSFUL_COMMIT ?: ''
                    def changedPaths = []
                    def runAll = !(baseCommit ==~ /[0-9a-fA-F]{40,64}/)
                    if (!runAll) {
                        withEnv(["CI_BASE_COMMIT=${baseCommit}"]) {
                            runAll = sh(
                                script: 'git cat-file -e "$CI_BASE_COMMIT^{commit}"',
                                returnStatus: true
                            ) != 0
                            if (!runAll) {
                                changedPaths = sh(
                                    script: 'git diff --no-renames --name-only "$CI_BASE_COMMIT" HEAD',
                                    returnStdout: true
                                ).readLines()
                            }
                        }
                    }
                    def pipelineChanged = changedPaths.any {
                        it == 'Jenkinsfile' || it == 'Makefile' ||
                        it == '.gitleaks.toml' || it.startsWith('ci/') ||
                        it.startsWith('policy/')
                    }
                    env.BACKEND_CHANGED = (runAll || pipelineChanged ||
                        changedPaths.any { it.startsWith('backend/') }).toString()
                    env.FRONTEND_CHANGED = (runAll || pipelineChanged ||
                        changedPaths.any { it.startsWith('frontend/') }).toString()
                    if (pipelineChanged) {
                        env.CI_MODE = 'FULL'
                    }
                    env.COMPOSE_PROJECT_NAME = "taskflow-ci-${env.BUILD_NUMBER}"

                    echo """
                    ========================================
                    Pipeline Environment
                    ========================================
                    APP_NAME         : ${env.APP_NAME}
                    NODE_ENV         : ${env.NODE_ENV}
                    BRANCH_NAME      : ${env.BRANCH_NAME}
                    CHANGE_ID        : ${env.CHANGE_ID ?: '-'}
                    CHANGE_BRANCH    : ${env.CHANGE_BRANCH ?: '-'}
                    CHANGE_TARGET    : ${env.CHANGE_TARGET ?: '-'}
                    CI_MODE          : ${env.CI_MODE}
                    BACKEND_CHANGED  : ${env.BACKEND_CHANGED}
                    FRONTEND_CHANGED : ${env.FRONTEND_CHANGED}
                    COMMIT_SHA       : ${env.COMMIT_SHA}
                    ========================================
                    """.stripIndent()
                }

                sh '''
                    node --version
                    npm --version
                '''
            }
        }

        stage('Secrets Detection') {
            // Scan every branch/PR build, including FAST and documentation-only changes.
            steps {
                sh '''
                    mkdir -p reports

                    echo "Recent commits:"
                    git log --oneline -5

                    gitleaks git . \
                        --config=.gitleaks.toml \
                        --report-format json \
                        --report-path reports/gitleaks.json \
                        --redact \
                        --verbose
                '''
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: 'reports/gitleaks.json',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('Install Dependencies') {
            failFast true

            parallel {
                stage('Backend Install') {
                    when {
                        expression { env.BACKEND_CHANGED == 'true' }
                    }

                    steps {
                        dir('backend') {
                            sh '''
                                npm ci \
                                    --prefer-offline \
                                    --no-audit \
                                    --fund=false
                            '''
                        }
                    }
                }

                stage('Mobile Install') {
                    when {
                        expression { env.FRONTEND_CHANGED == 'true' }
                    }

                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh '''
                                    flutter --version
                                    dart --version
                                    flutter pub get
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Quality & Security Gates - Light') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            failFast true

            parallel {
                stage('Lint') {
                    steps {
                        dir('backend') {
                            sh 'npm run lint'
                        }
                    }
                }

                stage('SCA - npm audit') {
                    steps {
                        dir('backend') {
                            script {
                                def auditStatus = sh(
                                    returnStatus: true,
                                    script: '''
                                    mkdir -p reports

                                    npm audit \
                                        --audit-level=high \
                                        --json \
                                        > reports/npm-audit.json
                                ''')

                                def audit = readJSON file: 'reports/npm-audit.json'

                                if (auditStatus > 1 || audit.error ||
                                    !audit.metadata?.vulnerabilities) {
                                    error 'npm audit failed or returned an invalid report.'
                                }
                                for (severity in ['critical', 'high', 'moderate', 'low']) {
                                    def count = audit.metadata.vulnerabilities[severity]
                                    if (!(count instanceof Number) || count < 0 ||
                                        count != count.intValue()) {
                                        error "Invalid npm audit count for ${severity}."
                                    }
                                }

                                def vulnerabilities =
                                    audit.metadata?.vulnerabilities ?: [:]

                                int critical =
                                    (vulnerabilities.critical ?: 0) as int

                                int high =
                                    (vulnerabilities.high ?: 0) as int

                                int moderate =
                                    (vulnerabilities.moderate ?: 0) as int

                                int low =
                                    (vulnerabilities.low ?: 0) as int

                                echo """
                                npm audit summary:

                                Critical: ${critical}
                                High:     ${high}
                                Moderate: ${moderate}
                                Low:      ${low}
                                """.stripIndent()

                                if (critical > 0) {
                                    echo """
                                    SCA detected ${critical} critical vulnerabilities.
                                    Final enforcement will be handled by OPA.
                                    """.stripIndent()
                                } else if (
                                    high > 0 ||
                                    moderate > 0 ||
                                    low > 0
                                ) {
                                    unstable(
                                        'SCA warning: vulnerabilities found, but no critical vulnerabilities.'
                                    )
                                } else {
                                    echo 'SCA passed: no vulnerabilities found.'
                                }
                            }
                        }
                    }

                    post {
                        always {
                            archiveArtifacts(
                                artifacts: 'backend/reports/npm-audit.json',
                                allowEmptyArchive: true
                            )
                        }
                    }
                }
            }
        }

        stage('Quality & Security Gates - Heavy') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            failFast true

            parallel {
                stage('Unit Test + Coverage') {
                    steps {
                        dir('backend') {
                            sh '''
                                npm test -- \
                                --coverage \
                                --ci \
                                --maxWorkers=2
                            '''
                        }
                    }

                    post {
                        always {
                            dir('backend') {
                                junit(
                                    allowEmptyResults: true,
                                    testResults: 'reports/junit.xml'
                                )

                                recordCoverage(
                                    tools: [[
                                        parser: 'COBERTURA',
                                        pattern: 'coverage/cobertura-coverage.xml'
                                    ]]
                                )
                            }
                        }
                    }
                }

                stage('Semgrep') {
                    steps {
                        dir('backend') {
                            sh '''
                                mkdir -p reports

                                semgrep scan \
                                    --config=p/owasp-top-ten \
                                    --config=p/nodejs \
                                    --error \
                                    --sarif \
                                    --output=reports/semgrep.sarif \
                                    .
                            '''
                        }
                    }

                    post {
                        always {
                            archiveArtifacts(
                                artifacts: 'backend/reports/semgrep.sarif',
                                allowEmptyArchive: true
                            )
                        }
                    }
                }
            }
        }

        stage('Policy Gate') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                sh '''
                    opa test policy/ --verbose
                    echo "Policy violations:"

                    opa eval \
                        --data policy/security.rego \
                        --input backend/reports/npm-audit.json \
                        --format pretty \
                        'data.security.deny'

                    echo "Evaluating policy gate..."

                    opa eval \
                        --fail \
                        --data policy/security.rego \
                        --input backend/reports/npm-audit.json \
                        --format pretty \
                        'data.security.allow = true'
                '''
            }
        }

        stage('Mobile Quality & Security') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    expression { env.FRONTEND_CHANGED == 'true' }
                }
            }

            failFast true

            parallel {
                stage('Flutter Analyze') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh 'flutter analyze'
                            }
                        }
                    }
                }

                stage('Flutter Test + Coverage') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh 'flutter test --coverage'
                            }
                        }
                    }

                    post {
                        always {
                            archiveArtifacts(
                                artifacts: 'frontend/coverage/**',
                                allowEmptyArchive: true
                            )
                        }
                    }
                }

                stage('Mobile SCA - OSV Scanner') {
                    steps {
                        dir('frontend') {
                            sh '''
                                osv-scanner scan source \
                                    --recursive \
                                    .
                            '''
                        }
                    }
                }
            }
        }

        stage('Mobile - Fast') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FAST'
                    }

                    expression { env.FRONTEND_CHANGED == 'true' }
                }
            }

            steps {
                container('flutter') {
                    dir('frontend') {
                        sh '''
                            flutter analyze
                            flutter test
                        '''
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            sonar-scanner \
                                -Dsonar.projectKey=taskflow-api \
                                -Dsonar.sources=src \
                                -Dsonar.tests=src \
                                -Dsonar.exclusions=**/*.spec.ts \
                                -Dsonar.test.inclusions=**/*.spec.ts \
                                -Dsonar.coverage.exclusions=**/*.module.ts,**/*.entity.ts,**/main.ts,**/migrations/** \
                                -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                timeout(
                    time: 5,
                    unit: 'MINUTES'
                ) {
                    waitForQualityGate(
                        abortPipeline: true
                    )
                }
            }
        }

        stage('Resolve Image') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                script {
                    def backendCommit = sh(
                        script: '''
                            git log -1 --format=%H -- backend/
                        ''',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG =
                        backendCommit.take(7)

                    env.IMAGE_NAME =
                        "registry:5000/taskflow-api:${env.IMAGE_TAG}"

                    echo """
                    Current commit : ${env.GIT_COMMIT.take(7)}
                    Backend commit : ${env.IMAGE_TAG}
                    Image          : ${env.IMAGE_NAME}
                    """.stripIndent()
                }
            }
        }

        stage('Verify Image Exists') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                script {
                    def status = sh(
                        script: """
                            curl \
                                --connect-timeout 5 \
                                --max-time 10 \
                                -s \
                                -o /dev/null \
                                -w "%{http_code}" \
                                -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json' \
                                http://registry:5000/v2/taskflow-api/manifests/${env.IMAGE_TAG}
                        """,
                        returnStdout: true
                    ).trim()

                    if (status == '200') {
                        env.NEED_IMAGE_BUILD = 'false'

                        echo "Image exists: ${env.IMAGE_NAME}"
                    }
                    else if (status == '404') {
                        env.NEED_IMAGE_BUILD = 'true'

                        echo "Image does not exist: ${env.IMAGE_NAME}"
                        echo 'Image will be rebuilt.'
                    }
                    else {
                        error """
                        Unable to check registry.
                        HTTP status: ${status}
                        """
                    }
                }
            }
        }

        stage('Parallel Builds') {
            failFast true

            parallel {
                stage('Mobile - Build Debug APK') {
                    when {
                        allOf {
                            expression {
                                env.CI_MODE == 'FULL'
                            }

                            expression { env.FRONTEND_CHANGED == 'true' }
                        }
                    }

                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh 'flutter build apk --debug --dart-define-from-file=config/dev.json'
                            }
                        }
                    }

                    post {
                        success {
                            archiveArtifacts(
                                artifacts: 'frontend/build/app/outputs/flutter-apk/app-debug.apk',
                                fingerprint: true
                            )
                        }
                    }
                }

                stage('Backend - Build Image') {
                    when {
                        allOf {
                            expression {
                                env.CI_MODE == 'FULL'
                            }

                            expression { env.BACKEND_CHANGED == 'true' }

                            expression {
                                env.NEED_IMAGE_BUILD == 'true'
                            }
                        }
                    }

                    steps {
                        dir('backend') {
                            retry(2) {
                                sh '''
                                    set -e

                                    echo "========================================"
                                    echo "Buildx Setup"
                                    echo "========================================"

                                    docker buildx version
                                    docker buildx ls

                                    if ! docker buildx inspect jenkins-builder >/dev/null 2>&1; then
                                        echo "Creating BuildKit builder..."

                                        docker buildx create \
                                            --name jenkins-builder \
                                            --driver docker-container \
                                            --buildkitd-config ../ci/buildkit/buildkitd.toml \
                                            --use
                                    else
                                        echo "Using existing BuildKit builder..."

                                        docker buildx use jenkins-builder
                                    fi

                                    echo "Bootstrapping builder..."

                                    docker buildx inspect \
                                        --builder jenkins-builder \
                                        --bootstrap

                                    echo "========================================"
                                    echo "Build Image"
                                    echo "========================================"

                                    docker buildx build \
                                        --builder jenkins-builder \
                                        --push \
                                        -t "$IMAGE_NAME" \
                                        --cache-from type=registry,ref=registry:5000/taskflow-api:buildcache \
                                        --cache-to type=registry,ref=registry:5000/taskflow-api:buildcache,mode=max \
                                        .

                                    echo "========================================"
                                    echo "Image build completed"
                                    echo "========================================"

                                    echo "Image: $IMAGE_NAME"
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Image Verification') {
            failFast true

            parallel {
                stage('Container Scan') {
                    when {
                        allOf {
                            expression {
                                env.CI_MODE == 'FULL'
                            }

                            expression { env.BACKEND_CHANGED == 'true' }
                        }
                    }

                    steps {
                        dir('backend') {
                            sh '''
                                set -e

                                mkdir -p reports
                                mkdir -p "$TRIVY_CACHE_DIR"

                                echo "========================================"
                                echo "Trivy Image Scan"
                                echo "========================================"

                                echo "Image : $IMAGE_NAME"
                                echo "Cache : $TRIVY_CACHE_DIR"

                                # ========================================
                                # 1. Scan image ONCE
                                # ========================================

                                trivy image \
                                    --cache-dir "$TRIVY_CACHE_DIR" \
                                    --image-src remote \
                                    --insecure \
                                    --format json \
                                    --output reports/trivy-image.json \
                                    "$IMAGE_NAME"

                                # ========================================
                                # 2. Human-readable table
                                # ========================================

                                echo
                                echo "========================================"
                                echo "HIGH / CRITICAL Vulnerabilities"
                                echo "========================================"

                                trivy convert \
                                    --format table \
                                    --severity HIGH,CRITICAL \
                                    reports/trivy-image.json

                                # ========================================
                                # 3. SARIF artifact
                                # ========================================

                                trivy convert \
                                    --format sarif \
                                    --severity HIGH,CRITICAL \
                                    --output reports/trivy-image.sarif \
                                    reports/trivy-image.json

                                # ========================================
                                # 4. Security gate
                                # ========================================

                                trivy convert \
                                    --severity HIGH,CRITICAL \
                                    --exit-code 1 \
                                    --output /dev/null \
                                    reports/trivy-image.json

                                echo
                                echo "========================================"
                                echo "Trivy Scan Passed"
                                echo "========================================"

                                du -sh "$TRIVY_CACHE_DIR" || true
                            '''
                        }
                    }

                    post {
                        always {
                            archiveArtifacts(
                                artifacts: '''
                                    backend/reports/trivy-image.json,
                                    backend/reports/trivy-image.sarif
                                ''',
                                allowEmptyArchive: true
                            )
                        }
                    }
                }

                stage('E2E') {
                    when {
                        allOf {
                            expression {
                                env.CI_MODE == 'FULL'
                            }

                            expression { env.BACKEND_CHANGED == 'true' }
                        }
                    }

                    steps {
                        timeout(time: 10, unit: 'MINUTES') {
                            dir('backend') {
                                withEnv([
                                    "API_IMAGE=${env.IMAGE_NAME}"
                                ]) {
                                    sh '''
                                        docker compose \
                                            -f docker-compose.yaml \
                                            -f docker-compose.ci.yaml \
                                            -p "$COMPOSE_PROJECT_NAME" \
                                            up -d --wait --wait-timeout 120 \
                                            --no-build --remove-orphans

                                        docker compose \
                                            -f docker-compose.yaml \
                                            -f docker-compose.ci.yaml \
                                            -p "$COMPOSE_PROJECT_NAME" ps
                                    '''
                                }
                            }

                            dir('backend') {
                                sh '''
                                    BASE_URL=http://localhost:3000 \
                                        npm run test:e2e -- --ci --runInBand
                                '''
                            }
                        }
                    }
                    post {
                        always {
                            dir('backend') {
                                script {
                                    if (env.IMAGE_NAME?.trim()) {
                                        withEnv([
                                            "API_IMAGE=${env.IMAGE_NAME}"
                                        ]) {
                                            env.E2E_CLEANUP_EXIT_CODE = sh(
                                                returnStatus: true,
                                                script: '''
                                                mkdir -p reports
                                                docker compose \
                                                    -f docker-compose.yaml \
                                                    -f docker-compose.ci.yaml \
                                                    -p "$COMPOSE_PROJECT_NAME" \
                                                    logs --no-color > reports/e2e-compose.log 2>&1 || true
                                                docker compose \
                                                    -f docker-compose.yaml \
                                                    -f docker-compose.ci.yaml \
                                                    -p "$COMPOSE_PROJECT_NAME" \
                                                    down --volumes --remove-orphans
                                            ''').toString()
                                        }
                                    }
                                }
                                junit(
                                    allowEmptyResults: true,
                                    testResults: 'reports/e2e-junit.xml'
                                )
                                archiveArtifacts(
                                    artifacts: 'reports/e2e-*',
                                    allowEmptyArchive: true
                                )
                                script {
                                    if (env.E2E_CLEANUP_EXIT_CODE &&
                                        env.E2E_CLEANUP_EXIT_CODE != '0') {
                                        error 'Failed to clean up the disposable E2E Compose stack.'
                                    }
                                }
                            }
                        }
                    }
                }

                stage('SBOM Pipeline') {
                    when {
                        allOf {
                            branch 'main'

                            expression {
                                env.CI_MODE == 'FULL'
                            }

                            expression { env.BACKEND_CHANGED == 'true' }
                        }
                    }

                    stages {
                        stage('Generate SBOM') {
                            steps {
                                dir('backend') {
                                    sh '''
                                    mkdir -p reports

                                    SYFT_REGISTRY_INSECURE_USE_HTTP=true \
                                    syft "$IMAGE_NAME" \
                                        --from registry \
                                        -o cyclonedx-json=reports/taskflow-api.cdx.json
                                '''
                                }
                            }
                        }

                        stage('Sign SBOM') {
                            steps {
                                withCredentials([
                                file(
                                    credentialsId: 'cosign-private-key',
                                    variable: 'COSIGN_KEY_FILE'
                                ),
                                string(
                                    credentialsId: 'cosign-password',
                                    variable: 'COSIGN_PASSWORD'
                                )
                            ]) {
                                    dir('backend') {
                                        sh '''
                                        set +x

                                        mkdir -p reports

                                        cosign sign-blob \
                                            --yes \
                                            --key "$COSIGN_KEY_FILE" \
                                            --bundle reports/taskflow-api.cdx.sigstore.json \
                                            reports/taskflow-api.cdx.json
                                    '''
                                    }
                            }
                            }

                            post {
                                always {
                                    archiveArtifacts(
                                    artifacts: '''
                                        backend/reports/taskflow-api.cdx.json,
                                        backend/reports/taskflow-api.cdx.sigstore.json
                                    ''',
                                    allowEmptyArchive: true
                                )
                                }
                            }
                        }

                        stage('Verify SBOM Signature') {
                            steps {
                                withCredentials([
                                file(
                                    credentialsId: 'cosign-public-key',
                                    variable: 'COSIGN_PUB_FILE'
                                )
                            ]) {
                                    dir('backend') {
                                        sh '''
                                        cosign verify-blob \
                                            --key "$COSIGN_PUB_FILE" \
                                            --bundle reports/taskflow-api.cdx.sigstore.json \
                                            reports/taskflow-api.cdx.json
                                    '''
                                    }
                            }
                            }
                        }
                    }
                }
            }
        }

        stage('Unit Test - Fast') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FAST'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                dir('backend') {
                    sh '''
                        npm run lint
                        npm test -- --runInBand
                    '''
                }
            }
        }

        stage('Production Approval') {
            when {
                allOf {
                    branch 'main'
                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                script {
                    if (!env.IMAGE_NAME?.trim()) {
                        error 'IMAGE_NAME is not set before production approval.'
                    }

                    input(
                        message: """
                        Deploy to production?

                        Image : ${env.IMAGE_NAME}
                        Branch: ${env.BRANCH_NAME}
                        Commit: ${env.COMMIT_SHA}
                        """.stripIndent(),
                        ok: 'Deploy'
                    )
                }

                echo 'Production deployment approved.'
            }
        }

        stage('Checkout GitOps Repo') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    deleteDir()

                    git(
                        branch: "${GITOPS_BRANCH}",
                        credentialsId: 'github-jenkins',
                        url: "${GITOPS_REPO}"
                    )

                    sh '''
                        echo "GitOps repository:"
                        git remote -v

                        echo "Branch:"
                        git branch --show-current

                        echo "Commit:"
                        git log -1 --oneline
                    '''
                    script {
                        env.GITOPS_VALUES = env.BRANCH_NAME == 'main'
                            ? "${env.TASKFLOW_CHART}/values-production.yaml"
                            : "${env.TASKFLOW_CHART}/values-staging.yaml"
                    }
                }
            }
        }

        stage('Lint Helm Chart') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    sh '''
                        echo "Linting $GITOPS_VALUES"

                        helm lint "$TASKFLOW_CHART" \
                            -f "$GITOPS_VALUES"
                    '''
                }
            }
        }

        stage('Update GitOps Manifest') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    sh '''
                        echo "Updating:"
                        echo "$GITOPS_VALUES"

                        yq -i \
                            '.image.repository = "registry:5000/taskflow-api" |
                            .image.tag = strenv(IMAGE_TAG)' \
                            "$GITOPS_VALUES"

                        echo "Updated image:"
                        yq '.image' "$GITOPS_VALUES"

                        git diff -- "$GITOPS_VALUES"
                    '''
                }
            }
        }

        stage('Commit GitOps Change') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    script {
                        sh '''
                            git config user.name "jenkins"
                            git config user.email "jenkins@taskflow.local"

                            git add "$GITOPS_VALUES"
                        '''

                        def hasChanges = sh(
                            script: 'git diff --cached --quiet',
                            returnStatus: true
                        )

                        if (hasChanges == 0) {
                            env.GITOPS_CHANGED = 'false'
                            echo 'No GitOps changes.'
                        } else {
                            env.GITOPS_CHANGED = 'true'

                            sh '''
                                git commit \
                                    -m "deploy(${BRANCH_NAME}): taskflow-api ${IMAGE_TAG}"
                            '''

                            env.GITOPS_COMMIT = sh(
                                script: 'git rev-parse HEAD',
                                returnStdout: true
                            ).trim()

                            echo "GitOps commit: ${env.GITOPS_COMMIT}"
                        }
                    }
                }
            }
        }

        stage('Push GitOps change') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression { env.BACKEND_CHANGED == 'true' }

                    expression {
                        env.GITOPS_CHANGED == 'true'
                    }
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'github-jenkins',
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_TOKEN'
                        )
                    ]) {
                        retry(2) {
                            sh 'bash ../ci/scripts/push-gitops.sh'
                        }
                    }

                    script {
                        env.GITOPS_COMMIT = sh(
                            script: 'git rev-parse HEAD',
                            returnStdout: true
                        ).trim()
                    }

                    echo """
                    GitOps handoff completed.

                    Environment : ${env.BRANCH_NAME == 'main' ? 'production' : 'staging'}
                    Image tag   : ${env.IMAGE_TAG}
                    GitOps SHA  : ${env.GITOPS_COMMIT}

                    Argo CD will reconcile asynchronously.
                    """.stripIndent()
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts(
                    artifacts: '**/npm-debug.log*',
                    allowEmptyArchive: true
                )

                archiveArtifacts(
                    artifacts: 'backend/reports/**',
                    allowEmptyArchive: true
                )
            }
        }
    }

    post {
        success {
            echo """
            ========================================
            Pipeline SUCCESS
            ========================================
            Branch : ${env.BRANCH_NAME}
            Mode   : ${env.CI_MODE}
            Image  : ${env.IMAGE_NAME ?: '-'}
            GitOps : ${env.GITOPS_COMMIT ?: '-'}
            """.stripIndent()

            withCredentials([
                string(
                    credentialsId: 'discord-webhook-url',
                    variable: 'DISCORD_WEBHOOK_URL'
                )
            ]) {
                sh '''
                    python3 ci/scripts/discord_notify.py success \
                        || echo "WARNING: Discord notification failed"
                '''
            }
        }

        failure {
            echo """
            ========================================
            Pipeline FAILURE
            ========================================
            Branch : ${env.BRANCH_NAME}
            Mode   : ${env.CI_MODE}
            Stage  : ${env.STAGE_NAME}
            """.stripIndent()

            withCredentials([
                string(
                    credentialsId: 'discord-webhook-url',
                    variable: 'DISCORD_WEBHOOK_URL'
                )
            ]) {
                sh '''
                    python3 ci/scripts/discord_notify.py failure \
                        || echo "WARNING: Discord notification failed"
                '''
            }
        }
    }
}
