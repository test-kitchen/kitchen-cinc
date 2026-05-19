# Kitchen-cinc Change Log

## [1.1.0](https://github.com/test-kitchen/kitchen-cinc/compare/v1.0.0...v1.1.0) (2026-05-19)


### Features

* **provisioner:** add chef_* aliases for kitchen-omnibus-chef compatibility ([8a85364](https://github.com/test-kitchen/kitchen-cinc/commit/8a853649bb59315eb3e6cb33ebf40700ab3e7994))
* **provisioner:** defer chef_* aliases to kitchen-chef-enterprise when installed ([d2adb44](https://github.com/test-kitchen/kitchen-cinc/commit/d2adb44557939ea7e5d42c964892548b77e724a8))

## [1.0.0](https://github.com/test-kitchen/kitchen-cinc/compare/v0.1.0...v1.0.0) (2026-04-24)


### ⚠ BREAKING CHANGES

* remove legacy omnibus install-script code path
* rename chef-prefixed config keys to cinc-prefixed equivalents

### Features

* add initial kitchen-cinc gem scaffold ([21875b0](https://github.com/test-kitchen/kitchen-cinc/commit/21875b0506f00bf6a3ae475b469592219eb25867))
* add project docs and default product_name to cinc ([1e2c3e4](https://github.com/test-kitchen/kitchen-cinc/commit/1e2c3e48c84453c2670371a310c76d668ac04fa4))


### Bug Fixes

* **cinc_base:** properly escape quotes and backslashes in config values ([08a7b0a](https://github.com/test-kitchen/kitchen-cinc/commit/08a7b0a4ed0560ad300d21f04e11ba2cae36e67d))


### Code Refactoring

* remove legacy omnibus install-script code path ([6d04cf2](https://github.com/test-kitchen/kitchen-cinc/commit/6d04cf2368e9d00c30b6bc1ed2ab2d5ed8b61bb3))
* rename chef-prefixed config keys to cinc-prefixed equivalents ([c577ae2](https://github.com/test-kitchen/kitchen-cinc/commit/c577ae2a0f4e55d0499cc7f8821e958b5d3ade0a))

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
