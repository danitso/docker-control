# Docker Control

A command line utility for controlling Docker for Mac and Windows.

## Motivation

The utility was created due to a limitation in Docker for Windows which prevents
users from controlling the Docker service from the command line when running
Linux containers.

## Table of contents

1. [Requirements](#requirements)
1. [Installation](#installation)
1. [Usage](#usage)
1. [Commands](#commands)
1. [Configuration](#configuration)
    1. [Common](#common)
    1. [Windows](#windows)
1. [License](#license)

## Requirements

* Docker for Mac 17.12 or greater
* Docker for Windows 17.09 or greater

## Installation

1. Clone or download the repository
1. Determine the absolute path to the `bin` directory which contains the binary
   for your operating system
1. Add the path to your system's `PATH` variable.

## Usage

The utility has a simple set of commands which are invoked like this:

```bash
docker-control <command>
```

See a list of commands below.

## Commands

### config

The `config` command has a simple getter/setter interface. You can retrieve a
value by invoking the following command:

```bash
docker-control config get <name>
```

Setting a value is just as easy:

```bash
docker-control config set <name> <value>
```

You can also retrieve and set multiple values with a single invocation of the
commands:

```bash
docker-control config get <name> <name> ...
docker-control config set <name> <value> <name> <value> ...
```

See the [Configuration](#configuration) section for a list of supported
configuration values.

**Note**: Changes to configuration values will first take effect once the Docker
service is restarted. This command will not trigger a restart as users may wish
to delay this action.

### reset

The `reset` command resets the configuration values and triggers a restart of
the Docker service.

### restart

The `restart` command restarts the Docker service.

### start

The `start` command starts the Docker service.

### stop

The `stop` command stops the Docker service.

### version

The `version` command prints a version string. The command can also be invoked
by using the aliases `-v` or `--version`.

## Configuration

While some values are supported by both Docker for Mac and Windows, others are
supported by only one of the systems. Trying to specify a system specific value
on the wrong system will result in an error.

* [Common](#common)
* [Windows](#windows)

### Common

#### advanced.disk_image

The absolute path to the disk image for the virtual machine.

#### advanced.memory

The amount of memory (in megabytes) to allocate for the virtual machine.

#### advanced.processors

The number of processors to allocate for the virtual machine.

#### general.autostart

Whether to start Docker when a user logs in.

#### general.autoupdate

Whether to automatically update Docker when a new version is released.

#### general.tracking

Whether to allow anonymous usage data to be sent to the Docker team.

#### network.subnet_address

The subnet address for the virtual network.

#### proxies.excluded_hostnames

A comma separated list of hostnames which should bypass the proxy servers.

#### proxies.insecure_server

The URL for an insecure proxy server (HTTP).

#### proxies.secure_server

The URL for a secure proxy server (HTTPS).

#### proxies.use_proxy

Whether to use custom proxy servers when pulling images.

#### sharing.directories

A comma separated list of directory paths, which will be used for host mapped
volumes.

**Note**: You can only share root directories on Windows i.e. `C:\`. You must
also run the utility in an elevated command prompt (`Run as administrator`).

### Windows

#### general.expose_daemon

Whether to expose an insecure TCP socket for the Docker daemon.

#### network.dns_forwarding

Whether to use DNS forwarding.

#### network.dns_server

The IP address of the primary DNS server.

#### network.subnet_mask_size

The subnet mask size for the virtual network.

#### sharing.credentials

The username and password to use when accessing the shared directories.

**Note:** The value must be specified as `username:password` or
`computername\username:password`. The username will be prefixed with the current
computer name, if the former format is used.

## License

See the [LICENSE](LICENSE) file.
