# Docker Control

A simple command line utility for controlling Docker for Windows.

## Motivation

The utility was created due to a limitation in Docker for Windows which
prevents users from controlling the Docker service from the command line when
running Linux containers.

## Requirements

* Docker for Windows

## Usage

The following commands are available:

* config
* reset
* restart
* start
* stop
* version

The commands are invoked like this:

```bash
docker-control <command>
```

## Configuration

Configuration values can be changed by invoking the following command:

```bash
docker-control config set <name> <value>
```

See the list of configuration values below.

### advanced.cpus

The number of CPUs to allocate for the virtual machine.

### advanced.memory

The amount of memory (in megabytes) to allocate for the virtual machine.

### advanced.vhd_path

The absolute path to the VHD file for the virtual machine.

### general.autostart

Whether to start Docker when a user logs in.

### general.autoupdate

Whether to automatically update Docker when a new version is released.

### general.expose_daemon

Whether to expose an insecure TCP socket for the Docker daemon.

### general.tracking

Whether to allow anonymous usage data to be sent to the Docker team.

### network.dns_forwarding

Whether to use DNS forwarding.

### network.dns_server

The IP address of the primary DNS server.

### network.subnet_address

The subnet address for the virtual network.

### network.subnet_mask_size

The subnet mask size for the virtual network.

### proxies.enabled

Whether to use proxy servers when pulling images.

### proxies.excluded_hostnames

A comma separated list of hostnames which should bypass the proxy servers.

### proxies.insecure_server

The URL for an insecure proxy server (HTTP).

### proxies.secure_server

The URL for a secure proxy server (HTTPS).

### shared_drives.credentials

The username and password to use when accessing the shared drives. The values
must be specified in the format `computername\username:password`.

### shared_drives.letters

A comma separated list of shared drive letters.

**WARNING**: This does not currently enable/disable drive sharing.

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request

## License

See the [LICENSE](LICENSE) file.
