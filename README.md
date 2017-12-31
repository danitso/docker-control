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

### daemon.dns

The IP address of the default DNS server.

### daemon.expose

Whether to expose a TCP socket for the Docker service.

**Warning**: The socket being exposed does not use TLS encryption by default.

### daemon.forward_dns

Whether to use DNS forwarding.

### daemon.tracking

Whether to allow anonymous usage statistics to be sent to the Docker team.

### vm.cpus

The number of CPUs to allocate for the virtual machine.

**Warning**: While the command accepts any integer, you must never allocate less
than 1 CPU or more than the total number of available CPU cores.

### vm.memory

The amount of RAM (in megabytes) to allocate for the virtual machine.

**Warning**: While the command accepts any integer, we strongly recommend that
you allocate at least 1024 MB and that you increment the allocation in steps of
256 MB (1024 MB, 1280 MB, 1536 MB etc.).

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request

## License

See the [LICENSE](LICENSE) file.
