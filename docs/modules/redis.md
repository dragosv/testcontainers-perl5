# Redis

## Introduction

The Testcontainers module for Redis provides a pre-configured container for running a Redis instance in your tests. It uses the official [`redis`](https://hub.docker.com/_/redis) Docker image.

Redis is the simplest module — it requires no credentials or database configuration by default.

## Adding the dependency

Add Testcontainers to your `cpanfile`:

```perl
requires 'Testcontainers';
```

Or install directly:

```bash
cpanm --installdeps .
perl Build.PL && ./Build && ./Build install
```

## Usage example

<!--codeinclude-->

```perl
use Testcontainers::Module::Redis qw( redis_container );
use Test::More;

my $redis = redis_container();

my $redis_url = $redis->connection_string;
# redis_url: "redis://localhost:XXXXX"

# Use redis_url with your Redis client

$redis->terminate;

done_testing;
```

<!--/codeinclude-->

## Module Reference

### `redis_container`

The `redis_container()` function creates and starts a Redis instance.

#### Function signature

```perl
my $redis = redis_container(%opts);
```

Creates a new Redis container with the given options. The container is pre-configured with:

- **Image**: `redis:7-alpine` (by default)
- **Port**: `6379/tcp` (mapped to a random host port)

#### Container Options

| Option           | Type     | Default            | Description                       |
|------------------|----------|:------------------:|-----------------------------------|
| `image`          | `String` | `"redis:7-alpine"` | Docker image to use               |
| `port`           | `String` | `"6379/tcp"`       | Container port                    |
| `password`       | `String` | `undef`            | Redis password (optional)         |
| `startup_timeout`| `Int`    | `30`               | Timeout in seconds                |
| `name`           | `String` | `undef`            | Container name                    |

#### Wait Strategy

The module uses a single wait strategy (applied automatically):

| Strategy | Configuration |
|----------|---------------|
| Log      | `"Ready to accept connections"` with 30 s timeout |

### Container Methods

The returned container object provides these methods:

| Method                | Return Type | Description                         |
|-----------------------|-------------|-------------------------------------|
| `connection_string()` | `String`    | Returns a `redis://` connection URI |
| `host()`              | `String`    | Returns the container host          |
| `mapped_port($port)`  | `String`    | Returns the mapped host port        |
| `terminate()`         | `Void`      | Stops and removes the container     |

#### Connection URL format

```
redis://<host>:<mapped-port>
```

With password:
```
redis://:<password>@<host>:<mapped-port>
```

## Examples

### Default configuration

```perl
my $redis = redis_container();
my $url = $redis->connection_string;
# "redis://localhost:XXXXX"
```

### Pinned version

```perl
my $redis = redis_container(
    image => 'redis:6-alpine',
);
```

### With password

```perl
my $redis = redis_container(
    password => 'mysecret',
);

my $url = $redis->connection_string;
# "redis://:mysecret@localhost:XXXXX"
```

### Using with Redis client

```perl
use Testcontainers::Module::Redis qw( redis_container );
use Redis;

my $redis_container = redis_container();

my $redis = Redis->new(server => $redis_container->host . ':' . $redis_container->mapped_port('6379/tcp'));

$redis->set('key', 'value');
my $value = $redis->get('key');

$redis_container->terminate;
```
