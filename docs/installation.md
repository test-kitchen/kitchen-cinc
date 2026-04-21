# Installation Options

These options control how Cinc Client is downloaded and installed on
the test instance before the converge runs. Two install code paths exist:

- **Product mode (preferred)** — driven by `product_name`, uses the
  modern `Mixlib::Install` API and the omnitruck installers.
- **Omnibus URL mode (legacy)** — driven by `require_cinc_omnibus`,
  uses `Mixlib::Install::ScriptGenerator` and the URL in
  `cinc_omnibus_url`. Used only when `product_name` is not set.

`product_name` defaults to `"cinc"`, so product mode is active by
default.

## Product mode

### `product_name`

- **Type:** String
- **Default:** `"cinc"`
- Product to install. Set to `"cinc"` for Cinc Client or
  `"cinc-workstation"` for Cinc Workstation.

### `product_version`

- **Type:** String or Symbol
- **Default:** `:latest`
- Specific version to install (e.g. `"19.2.12"`) or `:latest`.

### `channel`

- **Type:** Symbol
- **Default:** `:stable`
- Release channel. One of `:stable` or `:current`.

### `install_strategy`

- **Type:** String
- **Default:** `"once"`
- When to install. One of:
  - `"once"` — only install if Cinc is not already present.
  - `"always"` — reinstall on every converge.
  - `"skip"` — skip the install command entirely.

### `download_url`

- **Type:** String
- **Default:** none
- Override the download URL with a direct package URL. Useful for
  air-gapped environments and internal package mirrors.

### `checksum`

- **Type:** String
- **Default:** none
- SHA256 checksum used to verify the file fetched from `download_url`.

### `platform`, `platform_version`, `architecture`

- **Type:** String
- **Default:** auto-detected
- Override platform detection when the omnitruck installer needs help
  identifying the target.

## Omnibus URL mode (legacy)

These options apply only when `product_name` is unset.

### `require_cinc_omnibus`

- **Type:** Boolean or String
- **Default:** `true`
- Controls the legacy install code path:
  - `true` — install the latest version using `cinc_omnibus_url`.
  - `false` — skip installation; assume Cinc is pre-installed.
  - `"15.0.0"` (or any version string) — install that specific version.

### `cinc_omnibus_url`

- **Type:** String
- **Default:** `"https://omnitruck.cinc.sh/install.sh"`
- URL of the install script used by the legacy install code path.

### `cinc_omnibus_install_options`

- **Type:** String
- **Default:** none
- Extra command-line flags appended to the install script invocation.
  May contain `-P <project>` to select a project and `-d <dir>` to
  specify a download directory.

### `cinc_omnibus_root` (advanced)

- **Type:** String
- **Default:** set by the installer at runtime (e.g. `/opt/cinc`)
- Root install directory of the Cinc package. The default values for
  `cinc_client_path`, `cinc_solo_path`, `cinc_apply_path`, and
  `ruby_bindir` are derived from this path.

## Proxy settings

These options are forwarded to the install script and to Cinc itself
via standard environment variables.

| Option        | Type   | Default | Notes                                |
|---------------|--------|---------|--------------------------------------|
| `http_proxy`  | String | none    | Forwarded to omnitruck and Cinc      |
| `https_proxy` | String | none    | Forwarded to omnitruck and Cinc      |
| `ftp_proxy`   | String | none    | Forwarded to omnitruck (Unix only)   |
| `no_proxy`    | String | none    | Forwarded to omnitruck (Unix only)   |

Only `http_proxy` is honored by the PowerShell installer.

If `chef-config` is available on the workstation, proxy settings from
`~/.chef/config.rb` are read at startup and exported to the
environment automatically.
