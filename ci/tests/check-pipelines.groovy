// Run with Groovy 3: groovy ci/tests/check-pipelines.groovy
// This checks Groovy syntax and real change-selection code, without Jenkins plugins.
def baseline = 'a' * 40
def fixtures = [
    [base: null, paths: [], backend: true, frontend: true, mode: 'FAST'],
    [base: 'invalid', paths: [], backend: true, frontend: true, mode: 'FAST'],
    [base: baseline, exists: false, paths: [], backend: true, frontend: true, mode: 'FAST'],
    [base: baseline, paths: ['backend/src/main.ts'], backend: true, frontend: false, mode: 'FAST'],
    [base: baseline, paths: ['frontend/lib/main.dart'], backend: false, frontend: true, mode: 'FAST'],
    [base: baseline, paths: ['backend/a', 'frontend/b'], backend: true, frontend: true, mode: 'FAST'],
    [base: baseline, paths: ['README.md'], backend: false, frontend: false, mode: 'FAST'],
    [base: baseline, paths: ['Jenkinsfile'], backend: false, frontend: false, mode: 'FAST'],
    [base: baseline, paths: ['ci/pods/frontend.yaml'], backend: true, frontend: true, mode: 'FULL'],
    [base: baseline, paths: ['policy/security.rego'], backend: true, frontend: true, mode: 'FULL'],
    [base: baseline, paths: ['Makefile'], backend: true, frontend: true, mode: 'FULL'],
    [base: baseline, paths: ['.gitleaks.toml'], backend: true, frontend: true, mode: 'FULL']
]

['backend', 'frontend'].each { component ->
    def source = new File("ci/Jenkinsfile.${component}").text
    new GroovyShell().parse(source)
    def logic = source.substring(source.indexOf('def baseCommit ='), source.indexOf('echo """'))
    fixtures.each { fixture ->
        def environment = [GIT_PREVIOUS_SUCCESSFUL_COMMIT: fixture.base, CI_MODE: 'FAST', BUILD_NUMBER: '1']
        def bindings = new Binding([
            env: environment,
            withEnv: { List entries, Closure body -> body() },
            sh: { Map options ->
                options.returnStatus ? (fixture.exists == false ? 1 : 0) : fixture.paths.join('\n')
            }
        ])
        new GroovyShell(bindings).evaluate(logic)
        assert environment["${component.toUpperCase()}_CHANGED".toString()] == fixture[component].toString(): fixture
        assert environment.CI_MODE == fixture.mode: fixture
        def other = component == 'backend' ? 'FRONTEND' : 'BACKEND'
        assert !environment.containsKey("${other}_CHANGED".toString())
    }
    if (component == 'backend') {
        assert !source.contains("container('flutter')")
        assert !source.contains('FRONTEND_CHANGED')
        assert source.contains("stage('Push GitOps change')")
        assert source.contains("'data.security.allow = true'")
        assert source.contains('disableConcurrentBuilds()')
    } else {
        assert !source.contains('BACKEND_CHANGED')
        assert !source.contains('GITOPS_REPO')
        assert source.contains('flutter build apk --debug')
    }
    println "${component}: Groovy syntax and ${fixtures.size()} change-selection cases passed"
}

['ci/Jenkinsfile.backend', 'ci/Jenkinsfile.frontend'].each { path ->
    def source = new File(path).text
    def start = source.indexOf("stage('Secrets Detection')")
    assert start >= 0
    def header = source.substring(start, source.indexOf('steps {', start))
    assert !header.contains('when {'): "Secrets scan must run in FAST and FULL: ${path}"
    assert source.contains('disableConcurrentBuilds()'): "Builds must queue: ${path}"
    println "${path}: unconditional secret scan and build queue checks passed"
}

['ci/Jenkinsfile.backend'].each { path ->
    def source = new File(path).text
    def start = source.indexOf('def buildCommit =')
    assert start >= 0
    def logic = source.substring(start, source.indexOf('echo """', start))
    def imageNames = []
    // Different CI commits with the same backend source must have different image tags.
    ['a' * 40, 'b' * 40, 'c' * 64].each { commit ->
        def environment = [:]
        new GroovyShell(new Binding([
            env: environment,
            sh: { Map options ->
                assert options.script.trim() == 'git rev-parse HEAD'
                commit + '\n'
            },
            error: { String message -> throw new IllegalStateException(message) }
        ])).evaluate(logic)
        assert environment.IMAGE_TAG == commit
        assert environment.IMAGE_NAME == "registry:5000/taskflow-api:${commit}".toString()
        imageNames << environment.IMAGE_NAME
    }
    assert imageNames.toSet().size() == 3
    def rejected = false
    try {
        new GroovyShell(new Binding([
            env: [:], sh: { Map options -> '' },
            error: { String message -> throw new IllegalStateException(message) }
        ])).evaluate(logic)
    } catch (IllegalStateException expected) {
        rejected = true
    }
    assert rejected
    println "${path}: image resolution passed (3 commits and invalid commit rejection)"
}
