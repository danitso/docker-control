# Docker Control

A simple utility for controlling the Docker service.

## Motivation

The utility was created due to a limitation in Docker for Windows which
prevents users from controlling the Docker service from the command line when
running Linux containers.

## Requirements

* Docker for Windows

## Usage

The following commands are available:

* config
* start
* stop
* restart
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

### daemon.autostart

Whether to start the Docker service when a user logs in.

### daemon.autoupdate

Whether to automatically update Docker when a new version is released.

### daemon.expose

Whether to expose a TCP socket for the Docker service.

**Warning**: The socket being exposed does not use TLS encryption by default.

### daemon.tracking

Whether to allow anonymous usage statistics to be sent to the Docker team.

### network.dns

The IP address of the default DNS server.

### network.forward_dns

Whether to use DNS forwarding.

### network.subnet_address

The subnet address for the virtual network.

### network.subnet_mask_size

The subnet mask size for the virtual network.

### proxy.exclude

A list of hostnames which should bypass the proxy servers.

### proxy.insecure

The URL for an insecure proxy server.

### proxy.secure

The URL for a secure proxy server.

### proxy.use

Whether to use proxy servers when pulling images.

### vm.memory

The amount of RAM (in megabytes) to allocate for the virtual machine.

**Warning**: While the command accepts any integer, you must never allocate less
than 1024 MB of RAM. Also, it is strongly recommended to specify a value which
is a multiple of 256 MB (1024 MB, 1280 MB, 1536 MB etc.).

### vm.processors

The number of processors to allocate for the virtual machine.

**Warning**: While the command accepts any integer, you must never allocate less
than 1 processor or more than the total number of available processors (cores).

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request

## License

See the [LICENSE](LICENSE) file.
