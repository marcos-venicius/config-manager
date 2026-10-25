FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y sudo

RUN useradd -m dev

RUN usermod -aG sudo dev

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER dev

# Create the workspace directory
WORKDIR /home/dev/app

CMD ["/bin/bash"]
