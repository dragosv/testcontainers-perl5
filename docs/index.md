# Testcontainers for Perl

Testcontainers for Perl is a Perl library that makes it simple to create and clean up container-based dependencies for automated integration and end-to-end tests. The library integrates with Perl's standard Test::More framework and the `prove` command.

Typical use cases include spinning up throwaway instances of databases, message brokers, or any Docker image as part of your test suite — containers start in seconds and are cleaned up automatically when the test finishes.

```perl title="Quickstart example"
use Testcontainers qw( run );
use Testcontainers::Wait;
use HTTP::Tiny;

my $container = run('testcontainers/helloworld:1.3.0',
    exposed_ports => ['8080/tcp'],
    wait_for      => Testcontainers::Wait::for_http('/uuid', port => '8080/tcp'),
);

my $host = $container->host;
my $port = $container->mapped_port('8080/tcp');

my $response = HTTP::Tiny->new->get("http://$host:$port/uuid");
print "Received UUID: $response->{content}\n";

$container->terminate;
```

<p style="text-align:center">
  <strong>Not using Perl? Here are other supported languages!</strong>
</p>
<div class="card-grid">
  <a class="card-grid-item" href="https://java.testcontainers.org">
    <img src="language-logos/java.svg" />Java
  </a>
  <a class="card-grid-item" href="https://golang.testcontainers.org">
    <img src="language-logos/go.svg" />Go
  </a>
  <a class="card-grid-item" href="https://dotnet.testcontainers.org">
    <img src="language-logos/dotnet.svg" />.NET
  </a>
  <a class="card-grid-item" href="https://node.testcontainers.org">
    <img src="language-logos/nodejs.svg" />Node.js
  </a>
  <a class="card-grid-item" href="https://testcontainers-python.readthedocs.io/en/latest/">
    <img src="language-logos/python.svg" />Python
  </a>
  <a class="card-grid-item" href="https://docs.rs/testcontainers/latest/testcontainers/">
    <img src="language-logos/rust.svg" />Rust
  </a>
  <a class="card-grid-item" href="https://github.com/testcontainers/testcontainers-hs/">
    <img src="language-logos/haskell.svg"/>Haskell
  </a>
  <a href="https://github.com/testcontainers/testcontainers-ruby/" class="card-grid-item"><img src="language-logos/ruby.svg"/>Ruby</a>
</div>

## About

Testcontainers for Perl is a library to support tests with throwaway instances of Docker containers. Built on Perl 5.40+ with Moo-based internals, it communicates with Docker via the Docker Remote API over Unix sockets and provides a functional API via `Testcontainers::run()` to support your test environment.

Choose from existing pre-configured [modules](modules/index.md) — PostgreSQL, MySQL, and Redis — and start containers within seconds. Or use the generic `run()` function to run any Docker image with full control over configuration.

Read the [Quickstart](quickstart/index.md) to get up and running in minutes.

## System requirements

Please read the [System Requirements](system_requirements/index.md) page before you start.

| Requirement     | Minimum version      |
|-----------------|----------------------|
| Perl            | 5.40+                |
| Linux/macOS     | Any modern version   |
| Docker          | 20.10+               |

Testcontainers automatically detects the Docker socket. It checks the `DOCKER_HOST` environment variable first, then `~/.docker/run/docker.sock` (Docker Desktop on macOS), and finally `/var/run/docker.sock`.

## License

See [LICENSE](https://github.com/dragosv/testcontainers-perl5/blob/main/LICENSE).

## Copyright

Copyright (c) 2024 - 2026 The Testcontainers for Perl Authors.

----

Join our [Slack workspace](https://slack.testcontainers.org/) | [Testcontainers OSS](https://www.testcontainers.org/) | [Testcontainers Cloud](https://testcontainers.com/cloud/)
[testcontainers-cloud]: https://www.testcontainers.cloud/
