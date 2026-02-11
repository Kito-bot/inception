FROM debian:bookworm

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y curl php php8.2-fpm php-mysql mariadb-client wget vim zsh git netcat-openbsd

COPY /conf/wp_conf.sh /

RUN  chmod +x wp_conf.sh

ENTRYPOINT ["./wp_conf.sh"]
