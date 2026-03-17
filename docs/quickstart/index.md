# Quickstart

Testcontainers for Perl integrates with Perl's standard Test::More framework and the `prove` command.

It is designed for integration and end-to-end tests, helping you spin up and manage the lifecycle of container-based dependencies via Docker.

## 1. System requirements

Please read the [System Requirements](../system_requirements/index.md) page before you start.

## 2. Install Testcontainers for Perl

Install the dependencies and build the module:

```bash
cpanm --installdeps .
perl Build.PL && ./Build && ./Build install
```

Or add to your `cpanfile`:

```perl
requires 'Testcontainers';
```

The module provides these main components:

| Module                          | Description                                                                                |
|---------------------------------|--------------------------------------------------------------------------------------------|
| `Testcontainers`                | High-level API with `run()` function and container management.                            |
| `Testcontainers::Wait`          | Wait strategies for container readiness.                                                  |
| `Testcontainers::Module::*`     | Pre-configured modules for popular services.                                              |

The source tree also contains `WWW::Docker` used internally by Testcontainers.

## 3. Spin up Redis

```perl
use Test::More;
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container = run('redis:7',
    exposed_ports => ['6379/tcp'],
    wait_for      => Testcontainers::Wait::for_log('Ready to accept connections'),
);

my $host = $container->host;
my $port = $container->mapped_port('6379/tcp');
print "Redis available at $host:$port\n";

# Clean up
$container->terminate;

done_testing;
```

The `run()` function receives the image name and configuration options as a hash.

- `exposed_ports` exposes port 6379 from the container and maps it to a random available host port — just like `docker run -p 6379`.
- `wait_for` validates when a container is ready to receive traffic. In this case, we check for the log message that Redis emits when ready.

When you use `exposed_ports`, Docker maps the container port to a random available host port. This is crucial for parallelization — if you add multiple tests, each starts its own Redis container on a different random port.

`run()` pulls the image (if needed), creates the container, and starts it.

All containers must be removed at some point, otherwise they will run until the host is overloaded. Call `$container->terminate` to clean up.

!!! tip

    Look at [Garbage Collector](../features/garbage_collector.md) to learn more about resource cleanup patterns.

## 4. Connect your code to the container

In a real project, you would pass this endpoint to your Redis client library. This snippet retrieves the endpoint from the container we just started:

```perl
my $host = $container->host;
my $port = $container->mapped_port('6379/tcp');

# Use host:port with your Redis client library
# For example: "redis://$host:$port"
```

We expose only one port, so the mapping is straightforward.

!!! tip

    If you expose more than one port, use `mapped_port()` with the specific container port you need.

## 5. Run the test

Run the test via:

```bash
prove -l t/
```

## 6. Want to go deeper with Redis?

You can find a more complete Redis example using the pre-configured module in our [Redis module](../modules/redis.md) documentation.

Or use any of the other pre-configured [modules](../modules/index.md):

- [PostgreSQL](../modules/postgres.md)
- [MySQL](../modules/mysql.md)
- [Redis](../modules/redis.md)

