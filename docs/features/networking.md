# Networking and communicating with containers

There are two common cases for setting up communication with containers.

## Exposing ports to the host

The simplest case does not require additional network configuration. The host running the test connects directly to the container through a mapped port.

### Exposing container ports

Use `exposed_ports` to expose a container port to a random host port:

```perl
use Testcontainers qw( run );

my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
);
```

When you use `exposed_ports`, Docker maps the container port to a random available port on your host — just like `docker run -p 5432`.

This is important for parallelization: if you run multiple tests in parallel, each can start its own container — and each will be exposed on a different random port, avoiding conflicts.

### Getting the container host

Resolve the container address from the running container:

```perl
my $host = $container->host;
```

!!! warning

    Do not hardcode `localhost`, `127.0.0.1`, or any other fixed address to access the container. The address may vary depending on the Docker environment (e.g., Docker Desktop, remote Docker host, CI environments).

### Getting the mapped port

Retrieve the random host port assigned by Docker:

```perl
my $port = $container->mapped_port('5432/tcp');
```

### Complete example

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
    wait_for      => Testcontainers::Wait::for_log('database system is ready'),
);

my $host = $container->host;
my $port = $container->mapped_port('5432/tcp');
# Connect to postgres at $host:$port

$container->terminate;
```

## Creating networks

For container-to-container communication, create a custom Docker network. Containers on the same network can communicate using network aliases without exposing ports through the host.

### Creating a network

Use the `WWW::Docker` network API to create a Docker network:

```perl
use WWW::Docker;

my $docker = WWW::Docker->new;
my $network = $docker->networks->create(
    name   => 'my-network',
    driver => 'bridge',
);
```

### Connecting containers to a network

Assign a network to a container using the `networks` option:

```perl
my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
    networks      => ['my-network'],
);
```

### Network instance methods

| Method                        | Description                                      |
|-------------------------------|--------------------------------------------------|
| `connect($container_id)`      | Connects a container to this network.            |
| `disconnect($container_id)`   | Disconnects a container from this network.       |

## Advanced networking

### Multi-container networking

The following example creates a network and connects multiple containers:

```perl
use WWW::Docker;
use Testcontainers::Module::PostgreSQL qw( postgres_container );
use Testcontainers qw( run );

# Create a custom network
my $docker = WWW::Docker->new;
my $network = $docker->networks->create(
    name   => 'app-network',
    driver => 'bridge',
);

# Create a PostgreSQL container
my $pg = postgres_container(
    database => 'mydb',
    username => 'admin',
    password => 'secret',
);

# Create an application container on the same network
my $app = run('alpine:latest',
    entrypoint => ['top'],
    networks   => ['app-network'],
);

# Connect PostgreSQL to the network
$network->connect($pg->id);

$pg->terminate;
$app->terminate;
```

!!! tip

    When containers are on the same Docker network, they can communicate using container names or network aliases directly — no port mapping to the host is needed. Use the container port (for example, `5432`), not the mapped host port.
