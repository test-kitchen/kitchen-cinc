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

Every option exposed by the provisioners is documented under
[`docs/`](docs/README.md):

- [Provisioners](docs/provisioners.md) — overview of `cinc_infra`,
  `cinc_zero`, `cinc_solo`, `cinc_apply`, and `cinc_target`.
- [Installation options](docs/installation.md) — `product_name`,
  `product_version`, `channel`, `install_strategy`, `download_url`,
  `checksum`, proxies, and the legacy omnibus options.
- [Converge options](docs/converge.md) — `run_list`, `attributes`,
  logging, `multiple_converge`, `enforce_idempotency`, `client_rb` /
  `solo_rb`, Chef Zero host/port, and more.
- [Cookbook resolution](docs/cookbook-resolution.md) — Policyfile and
  Berkshelf integration.
- [Paths](docs/paths.md) — sandbox, on-instance, and binary paths.
- [Target mode](docs/target-mode.md) — extra requirements and option
  overrides for `cinc_target`.

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
