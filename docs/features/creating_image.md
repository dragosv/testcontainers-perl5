# Creating a Docker image

Testcontainers for Perl pulls Docker images automatically when creating containers via `run()`. If the image is not available locally, it will be downloaded from the configured registry (Docker Hub by default).

## Automatic image pulling

When you use `run()`, the image is pulled automatically:

```perl
use Testcontainers qw( run );

my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
);
```

If the image `postgres:16` is not present locally, Testcontainers will automatically pull it before creating the container.

## Using private registries

If your image is hosted in a private registry, ensure your Docker daemon is authenticated before running tests:

```bash
docker login my-registry.example.com
```

Testcontainers will use the credentials stored by Docker for image pulls.

## Low-level image management

For advanced use cases, you can manage images directly through the `WWW::Docker` module:

```perl
use WWW::Docker;

my $docker = WWW::Docker->new;

# Pull an image
$docker->images->pull('alpine:latest');

# List images
my $images = $docker->images->list;

# Remove an image
$docker->images->remove('alpine:latest');
```

!!! note

    For most testing scenarios, you do not need to manage images directly. `run()` handles image pulling transparently.
