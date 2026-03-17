# Low-level API access

Testcontainers for Perl is built on top of `WWW::Docker`, a low-level Docker HTTP client that communicates with the Docker Engine API over a Unix socket. While the high-level `Testcontainers` module is recommended for test scenarios, you can access the Docker client directly for advanced use cases.

## Accessing the Docker client

The `Testcontainers::DockerClient` provides access to the underlying `WWW::Docker` client:

```perl
use Testcontainers::DockerClient;

my $docker_client = Testcontainers::DockerClient->new;
```

## Container operations

```perl
# Start, stop, and remove containers
$docker_client->start_container($container_id);
$docker_client->stop_container($container_id, timeout => 10);
$docker_client->remove_container($container_id, force => 1);

# Inspect a container
my $inspect = $docker_client->inspect_container($container_id);

# Get logs
my $logs = $docker_client->get_logs($container_id);

# Execute a command
my $output = $docker_client->exec($container_id, ['echo', 'hello']);
```

## Image operations

```perl
# Pull an image
$docker_client->pull_image('alpine:latest');
```

## Network operations

```perl
# Create a network
my $network_id = $docker_client->create_network(
    name   => 'my-network',
    driver => 'bridge',
);

# Connect / disconnect containers
$docker_client->connect_network($network_id, $container_id);
$docker_client->disconnect_network($network_id, $container_id);
```

## Using WWW::Docker directly

For even lower-level access, use `WWW::Docker` directly:

```perl
use WWW::Docker;

my $docker = WWW::Docker->new;

# List containers
my $containers = $docker->containers->list;

# List images
my $images = $docker->images->list;
```

!!! warning

    The low-level API is not covered by the same stability guarantees as the high-level `Testcontainers` module. Method signatures may change between minor versions.

## Docker socket detection

The `Testcontainers::DockerClient` automatically detects the Docker socket in this order:

1. `DOCKER_HOST` environment variable
2. `/var/run/docker.sock`
3. `~/.docker/run/docker.sock` (Docker Desktop on macOS)

See [Custom Configuration](configuration.md) for more details on Docker host detection.
