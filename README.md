# Python flask HTTP/1 Mock

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://codedocs.xyz/testillano/h1mock.svg)](https://codedocs.xyz/testillano/h1mock/index.html)
[![Ask Me Anything !](https://img.shields.io/badge/Ask%20me-anything-1abc9c.svg)](https://github.com/testillano)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/testillano/h1mock/graphs/commit-activity)
[![Publish docker images and helm charts](https://github.com/testillano/h1mock/actions/workflows/publish.yml/badge.svg)](https://github.com/testillano/h1mock/actions/workflows/publish.yml)

HTTP/1 mock server built with Python Flask and supported by docker/kubernetes.

## Build project image

This image is already available at `docker hub` for every repository `tag`, and also for master as `latest`:

```bash
$ docker pull testillano/h1mock:<tag>
```

You could also build it using the script `./build.sh` located at project root:

```bash
./build.sh
```

This image is built with `./Dockerfile`.

## How it is delivered

`h1mock` is delivered in a `helm` chart called `h1mock` (`./helm/h1mock`) so you may integrate it in your regular `helm` chart deployments by just adding a few artifacts.

## How it integrates in a service

1. Add the project's helm repository with alias `erthelm`:

   ```bash
    helm repo add erthelm https://testillano.github.io/helm
   ```

2. Add one dependency to your `Chart.yaml` file per each service you want to mock with `h1mock` service (use alias when two or more dependencies are included).

   ```yaml
   dependencies:
     - name: h1mock
       version: 1.0.0
       repository: alias:erthelm
       alias: server1

     - name: h1mock
       version: 1.0.0
       repository: alias:erthelm
       alias: server2
   ```

3. Refer to `h1mock` values through the corresponding dependency alias, for example `.Values.h1server.image` to access process repository and tag.

## How it works

The application is built on demand from pieces of source code which manage the server behavior.
You can find source examples at `./examples` directory.

The server configuration can be done in two ways:

### On deployment

The chart value `b64provision` could be used to set the source code represented as `base64` encoded string. This value is empty by default, so the deployment won't contain answer rules (always responds status code `404 Not Found` with an html response containing a help hyperlink).

### On demand

This is done through `kubectl cp` of the source file into `h1mock` container's path `/app/provision`. The utility `inotify` will detect the creation event to upgrade the server source activating the new behavior. You could send different server definitions and they will be loaded on demand. You could even reactivate any of the available provision files at remote directory, by mean touching them through `kubectl exec`.

## Deploy and test

To deploy the `helm` chart, execute this script, and follow instructions:

```bash
./deploy.sh
```

You could provide additional `helm install` arguments like setters. In this way you could set an initial provision different than default, or configure a different service port (something that only can be done at deployment time):

```bash
./deploy.sh --set b64provision="$(cat examples/rules-and-functions | base64 -w 0)" --set service.port=9000
```

There is a small bash script to do a minimal test of examples available, but it is better to look for notes deployed to play with provisions and traffic requests:

```bash
./test.sh
```

