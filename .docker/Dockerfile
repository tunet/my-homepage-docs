ARG NGINX_VERSION
ARG MKDOCS_MATERIAL_VERSION



FROM squidfunk/mkdocs-material:${MKDOCS_MATERIAL_VERSION} as base

RUN pip install mkdocs-git-revision-date-plugin



FROM base as build

COPY ./.git /docs/.git
COPY ./docs /docs/docs
COPY ./mkdocs.yml /docs/mkdocs.yml

RUN mkdocs build



FROM nginx:${NGINX_VERSION}-alpine-slim as frontend

COPY --from=build /docs/site/ /srv/app/public/
COPY ./.docker/nginx/default.conf /etc/nginx/conf.d/default.conf
