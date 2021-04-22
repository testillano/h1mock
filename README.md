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

You must use [flask API](https://flask.palletsprojects.com/en/1.1.x/) over `app` application (this instance name is mandatory, no other can be used) and define the *URL rules* inside a function which must be called `registerRules()`. For example:

```python
def registerRules():
  app.add_url_rule("/foo", "foo_get", view_func=foo_get, methods=['GET'])
  app.add_url_rule("/bar", "bar_post", view_func=bar_post, methods=['POST'])

def foo_get:
    # <here your code>

def bar_post:
    # <here your code>
```

So **these are the requirements**:
- Flask application instance: `app`.

- Mandatory rules registration definition: `registerRules()`.

- No need to re-import those already available: `os`, `logging` and of course, `flask` (*Flask*, *Blueprint*, *jsonify*, *request*).

More examples could be found at `./examples` directory.

To configure the service, that source code could be provisioned in two ways:

### On deployment time

The chart value `provisionPath` shall be used to set a relative path to the `helm chart`. The value must be in place (even being a symlink). If this value is missing or empty, a default provision is established (which always responds status code `404 Not Found` with an `html` response containing a help hyper link). Example:

```bash
helm install myRelease -n myNamespace chartDir --set provisionPath=myProvision --wait
```

In this example, the file `myProvision` must be accessible from `helm chart` root level.

### On demand

This can be done in two main ways:

* Through `kubectl cp` of the source file into `h1mock` container's path `/app/provision`. The utility `inotify` will detect the creation event to upgrade the server source activating the new behavior. You could send different server definitions and they will be loaded on demand (this is thanks to [flask debug mode option](https://flask.palletsprojects.com/en/1.1.x/quickstart/#debug-mode)). You could even reactivate any of the available provision files within the docker internal directory, by mean touching them by mean `kubectl exec`. Note that the initial provision belongs to a read-only configMap, so the only way to reactivate it is copying a duplicate with a new name (and this one could be touched in any moment). The initial configuration is used also as fall back in case of container crash.
* Through an administrative service which is launched on value `service.admin_port` (*8074* by default). These are the supported methods of this control API:
  * **POST** `/app/v1/provision/<file basename>` with source code sent over the request body in plain text. This operation always receives status code `201 Created`, but possible crash of container's application may be provoked by a bad design of the content sent.
  * **GET** `/app/v1/provision/<file basename>`, to "*touch*" and so reactivate an existing provision. This also receives `200 OK`, even when the touched provision was missing: in that case, an empty provision is created and this shall provoke the crash, being a rude way to reboot the container and then, restore the initial configuration. As mentioned in the `kubectl` method section above, the `initial` provision base name cannot be reactivated (in this case, status code `500 Internal Server Error` will be received).
  * There is also a keep-alive probe for administration interface, via **GET** `/healthz`, which is used internally as liveness probe, but could also be used externally to check that the deployment is stable and healthy.

## Deploy

To deploy the main micro service chart, execute the following:

```bash
./deploy.sh
```

Once installed, a template notes will be shown. Follow the instructions to execute manually a basic check.

## Test (administrative interface)

The following script will deploy the component test chart and then start the pytest framework:

```bash
./ct/test.sh
```

## Test (kubectl provision)

External provision by mean `kubectl` commands is tested too, but using `bash` instead of `pytest`:

```bash
./ct/ktest.sh
```
