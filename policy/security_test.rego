package security

test_clean_report_allowed if {
    allow with input as {"metadata": {"vulnerabilities": {"critical": 0}}}
}

test_critical_report_denied if {
    not allow with input as {"metadata": {"vulnerabilities": {"critical": 1}}}
}

test_missing_metadata_denied if {
    not allow with input as {}
}

test_registry_error_denied if {
    not allow with input as {"error": {"code": "ENOTFOUND"}}
}

test_invalid_count_denied if {
    not allow with input as {"metadata": {"vulnerabilities": {"critical": "0"}}}
}
