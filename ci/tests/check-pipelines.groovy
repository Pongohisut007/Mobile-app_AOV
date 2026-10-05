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
    [base: baseline, paths: ['Jenkinsfile'], backend: true, frontend: true, mode: 'FULL'],
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
new GroovyShell().parse(new File('Jenkinsfile').text)
println 'Migration guard: Groovy syntax passed'
