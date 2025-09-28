FROM ubuntu:25.04 AS inkscape
RUN apt-get update && apt-get -y --no-install-recommends install \
    inkscape \
    make

WORKDIR /build/
COPY Makefile ./
COPY img/*.svg ./img/
RUN make svgs

FROM ubuntu:25.04 AS blender
RUN apt-get update && \
    apt-get install -y \
        blender \
        python3 \
        python3-numpy \
        make

WORKDIR /build/
COPY Makefile ./
COPY --from=inkscape /build/img/* ./img/
COPY export.py ./
COPY img/* ./img/
RUN make files

FROM node:24 AS parcel
RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
    make

COPY ./ /build/
WORKDIR /build/
COPY --from=blender /build/img/* ./img/

RUN yarn
RUN make -o files build

FROM nginx
COPY --from=parcel /build/build /dist
COPY ./nginx.conf /etc/nginx/nginx.conf

