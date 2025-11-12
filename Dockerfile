FROM python:3.12.10-slim-bookworm

RUN apt-get update && apt-get install -y \
    g++ \
    gcc \
    make \
    cmake \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN rm -rf /app/*

RUN git clone https://github.com/kirill2199/mysql_ch_replicator.git . \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -r requirements-dev.txt \
    && pip install --upgrade mysql_ch_replicator \
    && pip install -e .

RUN mkdir -p /app/data && \
    mkdir -p /home/user/binlog

CMD ["--help"]