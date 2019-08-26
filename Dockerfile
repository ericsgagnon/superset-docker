# docker build -t ericsgagnon/superset:0.34.0rc1 .

ARG SUPERSET_VERSION=0.34.0rc1
ARG OIC_VERSION=19.3

# Oracle Instant Client (oci) ########################################################################
#
# https://github.com/oracle/docker-images/blob/master/OracleInstantClient/dockerfiles/18.3.0/Dockerfile

FROM oraclelinux:7-slim as oracle-instant-client

ARG OIC_VERSION
ENV OIC_VERSION ${OIC_VERSION}

RUN  curl -o /etc/yum.repos.d/public-yum-ol7.repo https://yum.oracle.com/public-yum-ol7.repo && \
     yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install \
	 oracle-instantclient$OIC_VERSION-basic \
	 oracle-instantclient$OIC_VERSION-devel \
	 oracle-instantclient$OIC_VERSION-sqlplus && \
     rm -rf /var/cache/yum

# Final Stage ###########################################################################################
# using python base image for convenience - it has the most complicated install process...
FROM amancevice/superset:${SUPERSET_VERSION} as final

ARG OIC_VERSION
ENV OIC_VERSION ${OIC_VERSION}
ENV TZ UTC
ENV DEBIAN_FRONTEND noninteractive

USER root

# DB Drivers ##########################################

# Oracle drivers are super-special
ENV  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/oracle/$OIC_VERSION/client64/lib:/usr/include/oracle/$OIC_VERSION/client64/
ENV  OCI_LIB=/usr/lib/oracle/$OIC_VERSION/client64/lib
ENV  OCI_INC=/usr/include/oracle/$OIC_VERSION/client64

COPY --from=oracle-instant-client  /usr/lib/oracle /usr/lib/oracle
COPY --from=oracle-instant-client  /usr/share/oracle /usr/share/oracle
COPY --from=oracle-instant-client  /usr/include/oracle /usr/include/oracle
COPY ./oci8.pc /usr/lib/pkgconfig/oci8.pc

RUN  sed -i 's/OIC_VERSION/'"$OIC_VERSION"'/' /usr/lib/pkgconfig/oci8.pc && \
     apt update && apt install -y \
     libaio1 \
     unixodbc \
     unixodbc-dev \
     tdsodbc \
     odbc-postgresql \
     libsqliteodbc \
     mariadb-client \
     curl \
     net-tools

WORKDIR /home/superset

RUN  pip install cx_oracle

USER superset
