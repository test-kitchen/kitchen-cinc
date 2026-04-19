# Kitchen-cinc Change Log

## 0.1.0 (Unreleased)

- Initial release of kitchen-cinc gem
- Cinc Infra provisioner (`cinc_infra`) using cinc-client in local mode
- Cinc Solo provisioner (`cinc_solo`)
- Cinc Apply provisioner (`cinc_apply`)
- Cinc Target provisioner (`cinc_target`) for remote execution (Cinc 19.0.0+)
- Cinc Zero provisioner (`cinc_zero`) as deprecated alias for `cinc_infra`
- Policyfile support with auto-detection
- Berkshelf fallback support
- Omnitruck-based package installation via `omnitruck.cinc.sh`
