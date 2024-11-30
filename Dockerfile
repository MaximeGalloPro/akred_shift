FROM ubuntu:latest

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN groupadd --gid $GROUP_ID developer \
    && useradd --uid $USER_ID --gid developer --shell /bin/bash --create-home developer

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    unzip \
    cmake \
    xz-utils

USER developer

RUN git clone https://github.com/flutter/flutter.git /home/developer/flutter
ENV PATH="/home/developer/flutter/bin:${PATH}"

RUN flutter precache \
    && flutter doctor \
    && flutter channel stable \
    && flutter upgrade

WORKDIR /app