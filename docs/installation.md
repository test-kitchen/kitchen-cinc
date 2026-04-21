# Installation Options

These options control how Cinc Client is downloaded and installed on
the test instance before the converge runs. Installation is driven by
`product_name` and the `Mixlib::Install` API, which wraps the omnitruck
installers.

`product_name` defaults to `"cinc"`, so installation is active by
default. Set `install_strategy: "skip"` to disable it entirely.

## `product_name`

- **Type:** String
- **Default:** `"cinc"`
- Product to install. Set to `"cinc"` for Cinc Client or
  `"cinc-workstation"` for Cinc Workstation.

## `product_version`

- **Type:** String or Symbol
- **Default:** `:latest`
- Specific version to install (e.g. `"19.2.12"`) or `:latest`.

## `channel`

- **Type:** Symbol
- **Default:** `:stable`
- Release channel. One of `:stable` or `:current`.

## `install_strategy`

- **Type:** String
- **Default:** `"once"`
- When to install. One of:
  - `"once"` — only install if Cinc is not already present.
  - `"always"` — reinstall on every converge.
  - `"skip"` — skip the install command entirely.

## `download_url`

- **Type:** String
- **Default:** none
- Override the download URL with a direct package URL. Useful for
  air-gapped environments and internal package mirrors.

## `checksum`

- **Type:** String
- **Default:** none
- SHA256 checksum used to verify the file fetched from `download_url`.

## `platform`, `platform_version`, `architecture`

- **Type:** String
- **Default:** auto-detected
- Override platform detection when the omnitruck installer needs help
  identifying the target.

## `cinc_omnibus_root` (advanced)

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
