FROM debian:bookworm

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y mariadb-server vim zsh wget git netcat-openbsd

COPY ./conf/mdb_conf.sh /mdb_conf.sh

RUN chmod +x /mdb_conf.sh

ENTRYPOINT ["./mdb_conf.sh"]
