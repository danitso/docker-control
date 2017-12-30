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

* start
* stop
* restart
* version

The commands are invoked like this:

```bash
docker-control <command>
```

## Known issues

### Stopping the Docker service sometimes fails in Windows 10

Due to the fact that the Docker for Windows UI appears to ignore common window
messages, the only way to safely terminate it is by simulating a mouse click on
the `Quit Docker` tray menu item. However, sometimes the tray icon ends up
having the wrong state, especially if moving it to a new location in the tray's
overflow section. This prevents the tray menu from being activated and thereby
prevents the mouse click from being simulated.

A fix for this issue is expected to be included in an upcoming release.

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request

## License

See the [LICENSE](LICENSE) file.
