# sq1

## Description

Notes from the project.

## Table of Contents

1. [Plugin](#plugin)
2. [Site](#site)

## Plugin

`compose.yaml` runs sh command to install all plugin dependencies using composer.

```yaml
command: sh -c "php composer.phar self-update && php composer.phar update --with-all-dependencies --ignore-platform-reqs"
```

## Site

Use **Node.js v12.22.12** to build portal frontend and react component.

```bash
$ docker run -v .:/usr/node/app -w /usr/node/app --rm -it node:12.22.12-bullseye bash
```

```bash
$ npm config set strict-ssl=false
$ npm config set strict-ssl false
```

```bash
$ npm explore npm/node_modules/npm-lifecycle -g -- npm install node-pre-gyp@0.9.1
$ npm explore npm/node_modules/npm-lifecycle -g -- npm install node-gyp@latest
$ npm explore npm/node_modules/npm-lifecycle -g -- npm install node-pre-gyp:latest
```

```bash
$ npm install /libxmljs --scripts-prepend-node-path
```
