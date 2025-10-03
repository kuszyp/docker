# docker

## Description

Dockerfile and docker compose files that i used in recent projects.

## Table of Contents

1. [Projects](#projects)
   1. [Base template](#base-template)
   2. [wso2-bootstrap](#wso2-bootstrap)
   3. [wso2apim-with-is-as-km](#wso2apim-with-is-as-km)
   4. [SQ1](#sq1)
2. [TODO](#todo)
3. [License](#license)

## Projects

### Base template

Docker composer template from [compose-application-model](https://docs.docker.com/compose/compose-application-model/).
It is rather a guideline, how to prepare valid docker compose file.

### wso2-bootstrap

Docker setup to run SoapUI project to bootstrap WSO2 APIM and WSO2 IS with initial data.

### wso2apim-with-is-as-km

Full setup of WSO2 Api Manager with WSO2 Identity Server as a Key Manager.

### SQ1

Short note how to run site locally:

- Use `node:12.22.12-bullseye` image to build frontend
- Prepare image based on `php:8.2-cli` to build custom api plugin
- Use official `wordpress:6.8.2-php8.2-apache` image to run final site

**Important!** Build local image first to use it in `composer.yaml`

```bash
$ docker build . -t site:001 --no-cache
```

Update image value with recently created image.

```yaml
wordpress:
  image: site:001
  restart: always
```

How to play around with `compose.yaml` file?

- Create all containers defined in compose.yaml
- Run all containers defined in compose.yaml in detached mode
- Display logs from all running containers
- Stop and remove all running containers
- Remove unused networks and volumes

```bash
$ docker compose -f compose.yaml create
$ docker compose -f compose.yaml up --detached
$ docker compose -f compose.yaml logs -f
$ docker compose -f compose.yaml down
$ docker network prune
$ docker volume prune
// $ docker system prune --volumes

```

## TODO

- [ ] Command to remove all images prepared for given compose.yaml file `docker compose -f compose.yaml images | awk '{print $1}' | grep -v 'CONTAINER'`.

## License

This project is licensed under the [MIT License](LICENSE).
