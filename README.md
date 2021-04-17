[![Build docker image and publish to Docker Hub](https://github.com/testillano/h1mock/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/testillano/h1mock/actions/workflows/docker-publish.yml)

# Python flask HTTP/1 Mock

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

`h1mock` is delivered in a `helm` chart called `ert-h1mock` (`./helm/h1mock`) so you may integrate it in your regular `helm` chart deployments by just adding a few artifacts.

## How it integrates in a service

1. Add the project's helm repository with alias `erthelm`:

   ```bash
    helm repo add erthelm https://testillano.github.io/helm
   ```

2. Add one dependency to your `Chart.yaml` file per each service you want to mock with `h1mock` service (use alias when two or more dependencies are included).

   ```yaml
   dependencies:
     - name: ert-h1mock
       version: 1.0.0
       repository: alias:erthelm
       alias: h1server

     - name: ert-h1mock
       version: 1.0.0
       repository: alias:erthelm
       alias: h1server2
   ```

3. Refer to `h1mock` values through the corresponding dependency alias, for example `.Values.h1server.image` to access process repository and tag.

## How it works

The mock application is built on demand (lazy creation with default provision at first usage) by mean `inotify` utility.
The starter script monitors the provision directory for a new file created (or modified), inserting the URL rules and functions given in the detected file.
Python3 make the rest: the new mock application is reloaded with the new behaviour, acting as a provision system on-demand.

The user could provide new provisions by mean `kubectl cp` into `h1mock` container at `/app/provision` directory.
You can see a provision example at `./example/rules-and-functions`.

## Deploy & test

To deploy the `helm` chart, execute the following script, and follow instructions:

```bash
./helm/deploy.sh
```

