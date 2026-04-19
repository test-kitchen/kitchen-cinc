# kitchen-cinc

A Test Kitchen provisioner for [Cinc Client](https://cinc.sh/) (the community distribution of Chef Infra Client) that downloads and installs omnibus packages via the [Cinc omnitruck API](https://omnitruck.cinc.sh/).

## Overview

This Test Kitchen plugin provides provisioners that automatically download and install the desired version of Cinc Client on your test instances. This allows you to test your cookbooks against different Cinc versions without pre-installing Cinc on your images.

## Installation

**Note:** This gem will ship as part of Cinc Workstation. If you're using Cinc Workstation, no additional installation is necessary.

For standalone installation, add this line to your Gemfile:

```ruby
gem "kitchen-cinc"
```

Then execute:

```shell
bundle install
```

Or install it directly:

```shell
gem install kitchen-cinc
```

## Usage

### Available Provisioners

This gem provides five provisioners:

- **`cinc_infra`** — Modern Cinc Client provisioner using local mode (recommended)
- **`cinc_zero`** — Deprecated alias for `cinc_infra` (maintained for backward compatibility)
- **`cinc_solo`** — Cinc Solo provisioner (note: does not support parallel converge)
- **`cinc_apply`** — Cinc Apply provisioner for running individual recipes
- **`cinc_target`** — Cinc Target Mode provisioner (requires Cinc 19.0.0+, Train-based transport)

### Basic Configuration

To use the Cinc Infra provisioner in your `kitchen.yml`:

```yaml
provisioner:
  name: cinc_infra
```

### Complete Example

```yaml
---
driver:
  name: vagrant

provisioner:
  name: cinc_infra
  product_name: cinc
  install_strategy: always
  channel: stable

platforms:
  - name: ubuntu-24.04
  - name: almalinux-9

suites:
  - name: default
    run_list:
      - recipe[my_cookbook::default]
```

### Docker (Dokken) Example

```yaml
---
driver:
  name: dokken
  privileged: true
  chef_image: cincproject/cinc
  chef_version: latest

provisioner:
  name: cinc_infra
  product_name: cinc

transport:
  name: dokken

platforms:
  - name: ubuntu-24.04
    driver:
      image: dokken/ubuntu-24.04
      pid_one_command: /bin/systemd

  - name: almalinux-9
    driver:
      image: dokken/almalinux-9
      pid_one_command: /usr/lib/systemd/systemd
```

### Configuration Options

#### `product_name`

- **Type:** String
- **Default:** `cinc`
- **Description:** The product to install. Set to `cinc` for Cinc Client or `cinc-workstation` for Cinc Workstation.

#### `product_version`

- **Type:** String
- **Default:** `latest`
- **Description:** The version of Cinc Client to install. Can be a specific version (e.g., `19.2.12`) or `latest`.

#### `channel`

- **Type:** String/Symbol
- **Default:** `stable`
- **Options:** `stable`, `current`
- **Description:** The release channel to install from.

#### `install_strategy`

- **Type:** String
- **Default:** `once`
- **Options:** `once`, `always`
- **Description:** When to install Cinc. `once` only installs if not present, `always` reinstalls on every converge.

#### `download_url`

- **Type:** String
- **Default:** none
- **Description:** Override the download URL for custom package locations or air-gapped environments.

#### `checksum`

- **Type:** String
- **Default:** none
- **Description:** SHA256 checksum to verify the downloaded package. Used with `download_url`.

#### `platform`, `platform_version`, `architecture`

- **Type:** String
- **Default:** Auto-detected
- **Description:** Explicitly specify platform details for package selection.

#### `run_list`

- **Type:** Array
- **Default:** `[]`
- **Description:** The Cinc run list to execute.

#### `attributes`

- **Type:** Hash
- **Default:** `{}`
- **Description:** Node attributes to set during the converge.

#### `log_level`

- **Type:** String
- **Default:** `auto`
- **Description:** Cinc log level. Set to `debug` for verbose output, or `auto` to let Cinc decide.

#### `log_file`

- **Type:** String
- **Default:** none
- **Description:** Path to write the Cinc log file on the test instance.

#### `multiple_converge`

- **Type:** Integer
- **Default:** `1`
- **Description:** Number of times to run converge. Useful with `enforce_idempotency`.

#### `enforce_idempotency`

- **Type:** Boolean
- **Default:** `false`
- **Description:** When `true`, fails the run if the second converge makes changes. Requires `multiple_converge` >= 2.

#### `deprecations_as_errors`

- **Type:** Boolean
- **Default:** `false`
- **Description:** Treat Cinc deprecation warnings as errors.

### Policyfile Support

kitchen-cinc auto-detects `Policyfile.rb` in your cookbook directory and uses it for dependency resolution. You can also configure it explicitly:

```yaml
provisioner:
  name: cinc_infra
  policyfile_path: path/to/Policyfile.rb
  policy_group: local
  always_update_cookbooks: true
```

### Berkshelf Support

If no Policyfile is found, kitchen-cinc will fall back to Berkshelf if a `Berksfile` is present:

```yaml
provisioner:
  name: cinc_infra
  berksfile_path: path/to/Berksfile
  always_update_cookbooks: true
```

### Path Configuration

All paths are auto-calculated if not specified:

- `data_path` — Path to data directory
- `data_bags_path` — Path to data bags
- `environments_path` — Path to environments
- `nodes_path` — Path to node definitions
- `roles_path` — Path to roles
- `clients_path` — Path to clients
- `encrypted_data_bag_secret_key_path` — Path to encryption key

## Development

### Running Tests

```shell
bundle install
bundle exec rake          # Run all tests and linting
bundle exec rake spec     # Run unit tests only
bundle exec rake lint     # Run Cookstyle linting only
```

### Integration Tests

```shell
# Vagrant
KITCHEN_YAML=kitchen.yml bundle exec kitchen test

# Docker (Dokken)
KITCHEN_YAML=kitchen.dokken.yml bundle exec kitchen test
```

## License

Apache-2.0 — see [LICENSE](LICENSE) for details.
