# Kitchen-cinc Change Log

## Unreleased

* chore(deps): update actions/checkout action to v7 ([b5c6734](https://github.com/test-kitchen/kitchen-cinc/commit/b5c6734))
* chore(deps): update davidanson/markdownlint-cli2-action action to v24 ([9da1b72](https://github.com/test-kitchen/kitchen-cinc/commit/9da1b72))
* Fix typos ([172480d](https://github.com/test-kitchen/kitchen-cinc/commit/172480d))
* Fix malformed YARD tags ([0dc302f](https://github.com/test-kitchen/kitchen-cinc/commit/0dc302f))
* Require Ruby 3.1+ and modernize CI ([c784b47](https://github.com/test-kitchen/kitchen-cinc/commit/c784b47))
* Remove remaining dead linting config and add the gem version badge ([5b3952c](https://github.com/test-kitchen/kitchen-cinc/commit/5b3952c))
* Make CI able to resolve and load the test dependencies ([07f23df](https://github.com/test-kitchen/kitchen-cinc/commit/07f23df))
* Let cookstyle decide which files to lint ([dfc7e73](https://github.com/test-kitchen/kitchen-cinc/commit/dfc7e73))
* Docs: document the last five options and split contributor docs ([8196d41](https://github.com/test-kitchen/kitchen-cinc/commit/8196d41))

## [1.1.0](https://github.com/test-kitchen/kitchen-cinc/compare/v1.0.0...v1.1.0) (2026-05-19)

### Features

* **provisioner:** add chef_* aliases for kitchen-omnibus-chef compatibility ([8a85364](https://github.com/test-kitchen/kitchen-cinc/commit/8a853649bb59315eb3e6cb33ebf40700ab3e7994))
* **provisioner:** defer chef_* aliases to kitchen-chef-enterprise when installed ([d2adb44](https://github.com/test-kitchen/kitchen-cinc/commit/d2adb44557939ea7e5d42c964892548b77e724a8))

### Other Changes

* chore(deps): update davidanson/markdownlint-cli2-action action to v23 ([c2a191b](https://github.com/test-kitchen/kitchen-cinc/commit/c2a191b))
* chore(deps): update googleapis/release-please-action action to v5 ([5e20fa8](https://github.com/test-kitchen/kitchen-cinc/commit/5e20fa8))
* docs: clarify chef_* alias delegation behavior in README ([d81dc6e](https://github.com/test-kitchen/kitchen-cinc/commit/d81dc6e))

## [1.0.0](https://github.com/test-kitchen/kitchen-cinc/compare/v0.1.0...v1.0.0) (2026-04-24)

- Initial release of kitchen-cinc gem
- Cinc Infra provisioner (`cinc_infra`) using cinc-client in local mode
- Cinc Solo provisioner (`cinc_solo`)
- Cinc Apply provisioner (`cinc_apply`)
- Cinc Target provisioner (`cinc_target`) for remote execution (Cinc 19.0.0+)
- Cinc Zero provisioner (`cinc_zero`) as deprecated alias for `cinc_infra`
- Policyfile support with auto-detection
- Berkshelf fallback support
- Omnitruck-based package installation via `omnitruck.cinc.sh`


### ⚠ BREAKING CHANGES

* remove legacy omnibus install-script code path ([6d04cf2](https://github.com/test-kitchen/kitchen-cinc/commit/6d04cf2368e9d00c30b6bc1ed2ab2d5ed8b61bb3))
* rename chef-prefixed config keys to cinc-prefixed equivalents ([c577ae2](https://github.com/test-kitchen/kitchen-cinc/commit/c577ae2a0f4e55d0499cc7f8821e958b5d3ade0a))

### Features

* add initial kitchen-cinc gem scaffold ([21875b0](https://github.com/test-kitchen/kitchen-cinc/commit/21875b0506f00bf6a3ae475b469592219eb25867))
* add project docs and default product_name to cinc ([1e2c3e4](https://github.com/test-kitchen/kitchen-cinc/commit/1e2c3e48c84453c2670371a310c76d668ac04fa4))


### Bug Fixes

* **cinc_base:** properly escape quotes and backslashes in config values ([08a7b0a](https://github.com/test-kitchen/kitchen-cinc/commit/08a7b0a4ed0560ad300d21f04e11ba2cae36e67d))


### Code Refactoring


### Other Changes

* refactor: remove Chef compatibility alias files ([3171264](https://github.com/test-kitchen/kitchen-cinc/commit/3171264))
* test: add dokken config and update integration tests ([a6c3387](https://github.com/test-kitchen/kitchen-cinc/commit/a6c3387))
* ci: run integration tests via exec on ubuntu, macos, and windows ([98ab7c4](https://github.com/test-kitchen/kitchen-cinc/commit/98ab7c4))
* chore: update copyright and gem metadata ([35bbeff](https://github.com/test-kitchen/kitchen-cinc/commit/35bbeff))
* docs: add comprehensive configuration reference under docs/ ([4c4b5cd](https://github.com/test-kitchen/kitchen-cinc/commit/4c4b5cd))
* ci: Add missing .release-please-manifest.json ([3ad2b10](https://github.com/test-kitchen/kitchen-cinc/commit/3ad2b10))

* Initial commit ([12165e9](https://github.com/test-kitchen/kitchen-cinc/commit/12165e9))
* ci: add workflows and project configs ([1c4d154](https://github.com/test-kitchen/kitchen-cinc/commit/1c4d154))
