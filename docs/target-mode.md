# Target Mode (`cinc_target`)

`cinc_target` runs `cinc-client` **on the workstation** in target mode
(`--target`) and connects to the test instance through a Train-based
Test Kitchen transport. Cinc is not installed on the test instance.

## Requirements

- **Cinc Client 19.0.0 or newer**, installed locally on the workstation.
  The provisioner runs `cinc-client -v` at converge time and aborts if
  the local install is too old or missing.
- **A Train-based transport**, such as
  [`kitchen-transport-train`](https://github.com/tecracer-chef/kitchen-transport-train).
  The provisioner asks the active transport for a `train_uri`; if that
  method does not exist, it raises `RequireTrainTransport`.

If either requirement is not met, the provisioner raises a
`UserError` and the test fails fast.

## Option overrides

`cinc_target` inherits every option from `cinc_infra`, with the
following defaults overridden:

### `install_strategy`

- **Type:** String
- **Default:** `"none"`
- Disables the install command; Cinc is expected to be on the
  workstation, not the test instance.

### `sudo`

- **Type:** Boolean
- **Default:** `true`
- Whether to prefix the local `cinc-client` invocation with `sudo`.

## Transferring files

Because `cinc_target` runs the converge from the workstation rather than on the
instance, it can move files in both directions around the run.

### `uploads`

- **Type:** `Hash`
- **Default:** `{}`
- **Description:** Files copied from the workstation to the instance **before**
  the converge. Each key is a local path, or an array of local paths, and each
  value is the remote destination.

```yaml
provisioner:
  name: cinc_target
  uploads:
    /local/path/certificate.pem: /etc/ssl/certificate.pem
```

### `downloads`

- **Type:** `Hash`
- **Default:** `{}`
- **Description:** Files copied from the instance back to the workstation
  **after** the converge. Each key is a remote path, or an array of remote
  paths, and each value is the local destination. Useful for retrieving reports
  or logs produced by the run.

```yaml
provisioner:
  name: cinc_target
  downloads:
    /var/log/cinc/client.log: ./tmp/client.log
```

## Options that are intentionally no-ops

The following hooks are stubbed out for `cinc_target` because the
target node is touched only through Train, not through the regular
Test Kitchen install/init lifecycle:

- `install_command` — returns an empty string.
- `init_command` — returns an empty string.
- `prepare_command` — returns an empty string.

Installation options from [installation.md](installation.md)
(`product_name`, `product_version`, `channel`, `download_url`,
etc.) have no effect on the test instance, since nothing is installed
there. They still control how `cinc-client` itself behaves on the
workstation.

## Example

```yaml
---
driver:
  name: proxy
  host: target.example.com

transport:
  name: train
  backend: ssh
  user: deploy
  key_files:
    - ~/.ssh/id_ed25519

provisioner:
  name: cinc_target

platforms:
  - name: target

suites:
  - name: default
    run_list:
      - recipe[my_cookbook::default]
```
