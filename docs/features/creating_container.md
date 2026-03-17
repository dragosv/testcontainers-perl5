# How to create a container

Testcontainers' generic container support offers the greatest flexibility and makes it easy to use virtually any container image in the context of a temporary test environment. To interact or exchange data with a container, Testcontainers provides the `run()` function to configure and create the resource.

## The run() function

The `run()` function is the primary entrypoint for creating containers. It receives the Docker image name and configuration options as a hash:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container = run('redis:7',
    exposed_ports => ['6379/tcp'],
    wait_for      => Testcontainers::Wait::for_log('Ready to accept connections'),
);

my $host = $container->host;
my $port = $container->mapped_port('6379/tcp');

# Use the container...

$container->terminate;
```

The `run()` function pulls the image (if needed), creates the container, starts it, and waits for the configured wait strategy to succeed.

## Container options

When creating a container, you can pass options to `run()` as a hash. The options are organized into functional categories.

### Basic options

#### exposed_ports

Exposes container ports to the host. Docker assigns random available host ports — this is the recommended approach to avoid port conflicts.

```perl
# Single port
exposed_ports => ['8080/tcp'],

# Multiple ports
exposed_ports => ['8080/tcp', '8443/tcp'],
```

After starting the container, retrieve the mapped port:

```perl
my $mapped_port = $container->mapped_port('8080/tcp');
```

#### env

Sets environment variables for the container.

```perl
env => {
    POSTGRES_PASSWORD => 'secret',
    POSTGRES_DB       => 'mydb',
    POSTGRES_USER     => 'admin',
},
```

#### wait_for

Sets the [wait strategy](wait/introduction.md) to determine when the container is ready for use.

```perl
use Testcontainers::Wait;

wait_for => Testcontainers::Wait::for_http('/health', port => '8080/tcp'),
```

#### entrypoint

Specifies or overrides the container's `ENTRYPOINT`:

```perl
entrypoint => ['nginx', '-g', 'daemon off;'],
```

#### cmd

Specifies or overrides the container's `CMD`:

```perl
cmd => ['--config', '/etc/app.conf'],
```

#### labels

Applies Docker labels to the container:

```perl
labels => {
    team => 'backend',
    app  => 'myservice',
    env  => 'test',
},
```

### Advanced options

#### name

Sets a specific container name:

```perl
name => 'my-postgres',
```

#### startup_timeout

Sets the timeout (in seconds) for wait strategies:

```perl
startup_timeout => 120,  # 2 minutes
```

#### privileged

Runs the container in privileged mode:

```perl
privileged => 1,
```

#### network_mode

Sets the network mode:

```perl
network_mode => 'host',
```

#### networks

Connects the container to one or more networks:

```perl
networks => ['my-network'],
```

#### tmpfs

Mounts tmpfs filesystems:

```perl
tmpfs => {
    '/tmp'     => 'rw,noexec,nosuid,size=100m',
    '/var/tmp' => 'rw',
},
```

## Container methods

After creating and starting a container, the container object exposes several useful methods.

### Getting the mapped port

```perl
my $port = $container->mapped_port('5432/tcp');
```

### Getting the host

```perl
my $host = $container->host;
```

### Executing commands

Execute a command inside the running container and get the output:

```perl
my $output = $container->exec(['echo', 'Hello from container']);
print $output;  # "Hello from container"
```

### Getting logs

Retrieve the container's stdout/stderr logs:

```perl
my $logs = $container->logs;
print $logs;
```

### Getting container state

```perl
my $state = $container->state;
my $running = $container->is_running;
```

### Stopping and deleting

```perl
# Stop the container
$container->stop;

# Stop and remove the container
$container->terminate;
```

## Lifecycle

A typical container lifecycle in a test looks like this:

```
run("image:tag", %opts)  →  test logic  →  $container->terminate
   configure & start           use              cleanup
```

The recommended cleanup pattern uses explicit terminate or END blocks:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
    wait_for      => Testcontainers::Wait::for_log('database system is ready to accept connections'),
);

# Test logic using the container...

$container->terminate;

# Or use END block for automatic cleanup:
END { $container->terminate if $container }
```

## Examples

### NGINX container

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;
use HTTP::Tiny;

my $container = run('nginx:1.26.3-alpine3.20',
    name          => 'my-nginx',
    exposed_ports => ['80/tcp'],
    wait_for      => Testcontainers::Wait::for_http('/', port => '80/tcp'),
);

my $host = $container->host;
my $port = $container->mapped_port('80/tcp');

my $response = HTTP::Tiny->new->get("http://$host:$port/");
print "Status: $response->{status}\n";  # 200

$container->terminate;
```

### Container with command output

```perl
use Testcontainers qw( run );

my $container = run('alpine:latest',
    cmd => ['sh', '-c', "echo 'Hello from container' && sleep 10"],
);

sleep 2;
my $logs = $container->logs;
print $logs;  # "Hello from container\n"

$container->terminate;
```

## Supported options

| Option                | Description                                                                   |
|-----------------------|-------------------------------------------------------------------------------|
| `name`                | Sets the container name.                                                      |
| `env`                 | Sets environment variables (hash reference).                                  |
| `labels`              | Applies labels to the container (hash reference).                             |
| `exposed_ports`       | Exposes container ports with random host port mapping (array reference).      |
| `entrypoint`          | Specifies or overrides the `ENTRYPOINT` (array reference).                    |
| `cmd`                 | Specifies or overrides the `CMD` (array reference).                           |
| `wait_for`            | Sets the wait strategy to indicate when the container is ready.               |
| `networks`            | Assigns Docker networks to the container (array reference).                   |
| `startup_timeout`     | Sets the timeout in seconds for wait strategies.                              |
| `privileged`          | Runs the container in privileged mode (boolean).                              |
| `network_mode`        | Sets the network mode (e.g., 'host').                                         |
| `tmpfs`               | Mounts tmpfs filesystems (hash reference).                                    |

!!! tip

    Testcontainers for Perl detects your Docker host configuration automatically. You do **not** need to set the Docker daemon socket manually.
