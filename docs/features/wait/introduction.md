# Wait strategies — Introduction

Wait strategies detect when a container is ready for testing. They check different indicators of readiness and complete as soon as they are fulfilled. By default, Testcontainers will proceed without waiting. For most images, you should configure a wait strategy to ensure the service is fully ready before running tests.

## Available strategies

| Strategy                                  | Description                                                           |
|-------------------------------------------|-----------------------------------------------------------------------|
| [Port](#wait-for-port)                    | Waits for a TCP port to be reachable.                                 |
| [HTTP](#wait-for-http)                    | Waits for an HTTP endpoint to return a 2xx status code.               |
| [Log](#wait-for-log)                      | Waits for a specific message in the container logs.                   |
| [Health check](#wait-for-health-check)    | Waits for Docker's HEALTHCHECK to report healthy.                     |
| [Combined](#combining-strategies)         | Waits for multiple strategies to all succeed.                         |

## Startup timeout

Each wait strategy supports a configurable timeout. The default timeout is **60 seconds**. If the strategy does not succeed within the timeout, an error is thrown.

```perl
# Set timeout via the startup_timeout option in run()
my $container = run('postgres:16',
    exposed_ports   => ['5432/tcp'],
    wait_for        => Testcontainers::Wait::for_log('database system is ready'),
    startup_timeout => 120,  # 2 minutes
);
```

## Setting a wait strategy

Set the wait strategy using the `wait_for` option:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
    wait_for      => Testcontainers::Wait::for_all(
        Testcontainers::Wait::for_listening_port('5432/tcp'),
        Testcontainers::Wait::for_log('database system is ready to accept connections'),
    ),
);
```

## Wait for HTTP

The HTTP wait strategy checks if an HTTP endpoint returns a successful response (status code 2xx). You can configure the port, path, and other options.

```perl
# Basic — wait for port 8080 to respond with 2xx on "/"
Testcontainers::Wait::for_http('/')

# Custom path and port
Testcontainers::Wait::for_http('/health',
    port        => '8080/tcp',
    status_code => 200,
)
```

**Parameters:**

| Parameter      | Default   | Description                          |
|----------------|-----------|--------------------------------------|
| `path`         | `"/"`     | The HTTP path to request.            |
| `port`         | —         | The container port to check.         |
| `status_code`  | `200`     | Expected HTTP status code.           |
| `method`       | `"GET"`   | HTTP method to use.                  |

**Example:**

```perl
my $container = run('httpbin/httpbin:latest',
    exposed_ports => ['80/tcp'],
    wait_for      => Testcontainers::Wait::for_http('/uuid', port => '80/tcp'),
);
```

## Wait for port

The port wait strategy checks if a TCP port is reachable on the container. This verifies that a service is listening on the specified port.

```perl
Testcontainers::Wait::for_listening_port('5432/tcp')

# Or wait for the lowest exposed port
Testcontainers::Wait::for_exposed_port()
```

**Parameters:**

| Parameter  | Default | Description                          |
|------------|---------|--------------------------------------|
| `port`     | —       | The container port to check.         |

!!! note

    Just because a service is listening on a TCP port does not necessarily mean it is fully ready to handle requests. Log-based or HTTP-based strategies often provide more reliable readiness confirmation.

## Wait for log

The log wait strategy monitors the container's stdout/stderr and completes when a specific message appears.

```perl
Testcontainers::Wait::for_log('database system is ready to accept connections')

# With regex
Testcontainers::Wait::for_log(qr/listening on port \d+/)

# Wait for multiple occurrences
Testcontainers::Wait::for_log('ready', occurrences => 2)
```

**Parameters:**

| Parameter     | Default | Description                            |
|---------------|---------|----------------------------------------|
| `message`     | —       | The string or regex to search for.     |
| `occurrences` | `1`     | Number of times the message must appear. |

## Wait for health check

If the Docker image has a [HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck) instruction, you can wait for Docker to report the container as healthy:

```perl
Testcontainers::Wait::for_health_check()
```

## Combining strategies

Use `for_all(...)` to combine multiple wait strategies. All strategies must succeed for the container to be considered ready:

```perl
Testcontainers::Wait::for_all(
    Testcontainers::Wait::for_listening_port('5432/tcp'),
    Testcontainers::Wait::for_log('database system is ready to accept connections'),
)
```

Strategies are executed sequentially in the order provided.

## Summary

| Factory function               | Description                                                           |
|--------------------------------|-----------------------------------------------------------------------|
| `for_listening_port($port)`    | Waits for a TCP port to be reachable.                                 |
| `for_exposed_port()`           | Waits for the lowest exposed port to be reachable.                    |
| `for_http($path, %opts)`       | Waits for an HTTP endpoint to return a 2xx status code.               |
| `for_log($message, %opts)`     | Waits for a specific message in the container logs.                   |
| `for_health_check()`           | Waits for Docker's built-in health check to report healthy.           |
| `for_all(@strategies)`         | Combines multiple wait strategies; all must succeed.                  |
