FROM nvidia/cuda:10.0-cudnn7-runtime as lc0base
RUN apt-get update &&\
    apt-get install -y libopenblas-base libprotobuf10 zlib1g-dev \
    ocl-icd-libopencl1 tzdata &&\
    apt-get clean all

FROM lc0base as botbase
RUN apt upgrade -y
RUN apt-get update &&\
    apt-get install -y python3.7 &&\
    apt-get clean all

FROM nvidia/cuda:10.0-cudnn7-devel as builder
RUN apt-get update &&\
    apt-get install -y curl wget supervisor git \
    clang-6.0 libopenblas-dev ninja-build protobuf-compiler libprotobuf-dev \
    python3-pip &&\
    apt-get clean all
RUN pip3 install meson

LABEL "version"="lc0_v0.26.3-client_v29"
RUN curl -s -L https://github.com/LeelaChessZero/lc0/releases/latest |\
    egrep -o '/LeelaChessZero/lc0/archive/refs/tags/v0.27.0.tar.gz' |\
    wget --base=https://github.com/ -O v0.27.0.tar.gz -i - &&\
    tar xfz v0.27.0.tar.gz && rm v0.27.0.tar.gz && mv lc0* /lc0
WORKDIR /lc0
RUN CC=clang-6.0 CXX=clang++-6.0 INSTALL_PREFIX=/lc0 \
    ./build.sh release && ls /lc0/bin
WORKDIR /lc0/bin
RUN curl -s -L https://github.com/LeelaChessZero/lczero-client/releases/latest |\
    egrep -o '/LeelaChessZero/lczero-client/releases/download/v.*/lc0-training-client-linux' |\
    head -n 1 | wget --base=https://github.com/ -i - &&\
    chmod +x lc0-training-client-linux &&\
    mv lc0-training-client-linux lc0client

FROM lc0base as lc0
COPY --from=builder /lc0/bin /lc0/bin
WORKDIR /lc0/bin
ENV PATH=/lc0/bin:$PATH
CMD lc0client --user lc0docker --password lc0docker

FROM builder as botBuilder
RUN apt-get update &&\
    apt-get install -y python3-venv
RUN git clone https://github.com/careless25/lichess-bot.git /lcbot
WORKDIR /lcbot


# https://onedrive.live.com/download?cid=547CCA53C39C1EA1&resid=547CCA53C39C1EA1%21612&authkey=AHOF5lyRIHMk7Ys



RUN apt-get update && apt-get install -y wget python3 python3-pip p7zip-full
RUN wget --no-check-certificate "https://onedrive.live.com/download?cid=547CCA53C39C1EA1&resid=547CCA53C39C1EA1%21613&authkey=AGOqbMI3aSGCP8Q" -O r.7z
RUN 7z e r.7z -y
RUN rm r.7z
RUN python3 -V
RUN python3 -m venv .venv &&\
    . .venv/bin/activate &&\
    pip3 install wheel &&\
    python3 -m pip install --no-cache-dir -r requirements.txt
    

FROM botbase as lcbot
COPY --from=builder /lc0/bin /lc0/bin
COPY --from=botBuilder /lcbot /lcbot
WORKDIR /lcbot
