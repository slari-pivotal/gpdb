FROM pivotaldata/gpdb4-devel

WORKDIR /workspace

ADD . gpdb/

WORKDIR gpdb/gpAux

RUN time make parallelexec_opts=-j4 dist

RUN chown -R gpadmin:gpadmin /workspace/gpdb
RUN chown -R gpadmin:gpadmin /usr/local/greenplum-db-devel
