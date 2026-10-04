package security

default allow := false

valid_report if {
    not input.error
    is_object(input.metadata.vulnerabilities)
    is_number(input.metadata.vulnerabilities.critical)
    input.metadata.vulnerabilities.critical >= 0
}

deny contains msg if {
    not valid_report
    msg := "Build denied: missing or invalid npm audit report"
}

deny contains msg if {
    input.metadata.vulnerabilities.critical > 0
    msg := sprintf(
        "Build denied: %d CRITICAL vulnerabilities found",
        [input.metadata.vulnerabilities.critical]
    )
}

allow if count(deny) == 0
