# odoo app

FROM phusion/baseimage:latest
MAINTAINER Joan Marc Carbo Arnau <jmcarbo@gmail.com>
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty-backports main restricted " >> /etc/apt/sources.list
RUN (DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -q )
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install python-software-properties software-properties-common

# Install Postgress
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install postgresql postgresql-contrib
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes -q cron sudo
RUN apt-get install -q -y vim
RUN apt-get -y install wget sudo bzip2 cups
RUN apt-get install -y python-pip python-dev build-essential

# package required for odoo no repository install dependence
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install git
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install graphviz ghostscript postgresql-client \
 python-dateutil python-feedparser python-matplotlib \
 python-ldap python-libxslt1 python-lxml python-mako \
 python-openid python-psycopg2 python-pybabel python-pychart \
 python-pydot python-pyparsing python-reportlab python-simplejson \
 python-tz python-vatnumber python-vobject python-webdav \
 python-werkzeug python-xlwt python-yaml python-imaging
 RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install gcc python-dev mc bzr python-setuptools python-babel \
 python-feedparser python-reportlab-accel python-zsi python-openssl \
 python-egenix-mxdatetime python-jinja2 python-unittest2 python-mock \
 python-docutils lptools make python-psutil python-paramiko poppler-utils \
 python-pdftools antiword
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q  python-colorama python-distlib python-html5lib python-pip
RUN pip install decorator pyPDF

RUN    wget https://wkhtmltopdf.googlecode.com/files/wkhtmltoimage-0.11.0_rc1-static-amd64.tar.bz2 && \
    wget https://wkhtmltopdf.googlecode.com/files/wkhtmltopdf-0.11.0_rc1-static-amd64.tar.bz2 && \
    bzip2 -d wkhtmltoimage-0.11.0_rc1-static-amd64.tar.bz2 && \
    tar xvf wkhtmltoimage-0.11.0_rc1-static-amd64.tar && \
    bzip2 -d wkhtmltopdf-0.11.0_rc1-static-amd64.tar.bz2 && \
    tar xvf wkhtmltopdf-0.11.0_rc1-static-amd64.tar && \
    install wkhtmltopdf-amd64 /usr/bin/wkhtmltopdf && \
    install wkhtmltoimage-amd64 /usr/bin/wkhtmltoimage
    
RUN apt-get install -y xpdf-utils

RUN apt-get install -q -y language-pack-en
RUN update-locale LANG=en_US.UTF-8



RUN echo "listen_addresses = '*'" >> /etc/postgresql/9.3/main/postgresql.conf
RUN echo "host all all all md5"  >> /etc/postgresql/9.3/main/pg_hba.conf
RUN /usr/bin/pg_ctlcluster 9.3 main start && ( echo "ALTER USER postgres PASSWORD 'a123456'" | sudo -u postgres psql )

RUN locale-gen en_US.UTF-8
RUN useradd -s /bin/bash -m -p $(echo "a123456" | openssl passwd -1 -stdin) deploy
RUN usermod -a -G sudo deploy

# project settings
ENV project_name openerp
ENV project_root /home/openerp/

RUN adduser --system --home=$project_root --group openerp


ADD odoo /odoo
RUN cd / && \
    chown -R openerp: odoo

RUN /usr/bin/pg_ctlcluster 9.3 main start && (sudo -u postgres createuser -s  deploy) && ( echo "ALTER USER deploy PASSWORD 'a123456'; CREATE DATABASE TEST" | sudo -u postgres psql )
RUN /usr/bin/pg_ctlcluster 9.3 main start && (sudo -u postgres createuser -s  vagrant) && ( echo "ALTER USER vagrant PASSWORD 'a123456'; " | sudo -u postgres psql )

# UTF-8 patch
ADD template.sql /tmp/template.sql
RUN /usr/bin/pg_ctlcluster 9.3 main start && ( sudo -u postgres psql -f /tmp/template.sql )


EXPOSE 8069
EXPOSE 5432
EXPOSE 2224
EXPOSE 22
EXPOSE 443
EXPOSE 80

RUN mkdir /addons && \
    chown -R openerp: /addons

#Openerp service
RUN mkdir -p /etc/service/openerp
ADD runit-openerp /etc/service/openerp/run
RUN chmod +x /etc/service/openerp/run

#Postgres service
RUN mkdir -p /etc/service/postgres
ADD runit-postgres /etc/service/postgres/run
RUN chmod +x /etc/service/postgres/run

# CUPS service
RUN mkdir -p /etc/service/cups
ADD runit-cups /etc/service/cups/run
RUN chmod +x /etc/service/cups/run

# FONTS
ADD FRE3OF9X.TTF /usr/share/fonts/FRE3OF9X.TTF
ADD FREE3OF9.TTF /usr/share/fonts/FREE3OF9.TTF

