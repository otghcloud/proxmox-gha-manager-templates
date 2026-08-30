<img src="https://otgh-static-assets.s3.otgh.cloud/branding/logos/otgh_cloud_2024.png" alt="OTGH Cloud" width="200px" />

# Proxmox GHA Manager Templates

This repository contains Packer build templates for GitHub's Actions runner images, intended to be built as Proxmox VM templates or local QEMU/KVM images.

These are built using the scripts from the official [GitHub actions/runner-images repository](https://github.com/actions/runner-images), with only minor changes being made so they can be built outside Azure.

The image contents themselves are unmodified and are 100% feature compatible with the official images.

## Purpose

Many organisations (ourselves included) utilise GitHub actions/workflows that make use of the standard "ubuntu-latest" or "windows-xxxx" images.

If you own existing infrastructure and want to use [self-hosted runners](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners),
this repository provides an easy way to build and self-host those standard images.

Please note, self-hosted runners are currently only available to organisation accounts within GitHub.

> [!CAUTION]
> We highly recommend reading [GitHub's self-hosted runner documentation](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners) to understand the implications of exposing self-hosted runners on public repositories.

## Usage

This repository is primarily intended to be consumed by our "[otghcloud/proxmox-gha-manager-core](https://github.com/otghcloud/proxmox-gha-manager-core)" project.

## Contributing

We'd love to have your input and value all contributions, large or small.

Please review [CONTRIBUTING.md](CONTRIBUTING.md) for additional information and required conventions.

## License

This repository uses the MIT license.

Please review [LICENSE.md](LICENSE.md) for more details.

## Security

Please review [SECURITY.md](SECURITY.md) for more details.