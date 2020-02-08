FROM ubuntu:18.04

ENV HOME_DIR="/"
ENV TERM=linux
WORKDIR ${HOME_DIR}

RUN apt-get update -yqq && \
    apt-get upgrade -yqq && \
    apt-get install -yqq zip vim curl \
    python3-distutils python3-dev

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1

RUN pip install requests

COPY ctl.sh                           $HOME_DIR/
COPY post.sh                          $HOME_DIR/
COPY post.py                          $HOME_DIR/
COPY envvars.appd.sh                  $HOME_DIR/
COPY $APPD_MACHINE_AGENT_ZIP_FILE     $HOME_DIR/
COPY envvars.controller1.sh           $HOME_DIR/


ENTRYPOINT [ "/ctl.sh" ]
