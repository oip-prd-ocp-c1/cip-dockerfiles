FROM registry.access.redhat.com/ubi8/ubi:latest

ARG BUILD_DATE
ARG VCS_REF
ARG OKD_CLI_REL=v3.11.0
ARG OKD_CLI_TARBALL=openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
ARG WORKDIR=/opt/app/src


LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Open Innovation Platform OKD/OCP/Kubernetes Tools image" \
      org.label-schema.description="This image provides various tools simplifying user experience on the OIP." \
      org.label-schema.usage="https://github.com/oip-core/oip-core-tools-images/okdtools#VCS_REF" \
      org.label-schema.schema-version="1.0.0-rc.1" \
      org.label-schema.vcs-url="https://github.com/oip-core/oip-core-tools-images.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      docker.cmd="docker run -it oiprnd/okdtools"

ENV BUILD_DATE=$BUILD_DATE \
    VCS_REF=$VCS_REF \
    OKD_CLI_REL=$OKD_CLI_REL \
    OKD_CLI_TARBALL=$OKD_CLI_TARBALL \
    WORKDIR=/opt/app/src \
    HOME=/root \
    SHELL=/bin/bash

ENV GOPATH=$WORKDIR/go
ENV PATH=${PATH}:$GOPATH/bin
ENV YUM_OPTS="--disableplugin=subscription-manager --setopt=tsflags=nodocs"

# Installing basic dependencies
RUN yum -y $YUM_OPTS update && \
    yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    yum -y $YUM_OPTS install epel-release && \
    yum -y install jq && \
    RPM_PKGS="bash curl git less python3 python3-setuptools wget" && \
    yum -y $YUM_OPTS install $RPM_PKGS && \
    mkdir -p /usr/local/lib/python3.6/site-packages/ && \
    easy_install-3.6 pip && \
    yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    yum install -y postgresql96 && \
    yum install -y postgresql10 && \
    yum clean all && \
    rm -rf /var/cache/yum

WORKDIR $WORKDIR

# Adding OpenShift client & auto-completion
RUN curl -sLO https://github.com/openshift/origin/releases/download/$OKD_CLI_REL/$OKD_CLI_TARBALL && \
    tar zxf $OKD_CLI_TARBALL && \
    OCDIR=${OKD_CLI_TARBALL%.tar.gz} && \
    mv $OCDIR/oc /usr/bin && \
    chmod +x /usr/bin/oc && \
    rm -rf $OCDIR $OKD_CLI_TARBALL && \
    echo 'source <(oc completion bash)' >> $HOME/.autocomplete.bash

# Adding AWS cli & auto-completion
RUN pip3 install awscli && \
    echo "complete -C '$(type aws_completer)' aws" >> $HOME/.autocomplete.bash

# Adding distgen, required to build RHEL base images
RUN pip install distgen


# Run bash by default
CMD [ "/bin/bash" ]

# Fix for OpenShift
RUN chmod g=u /etc/passwd && \
    chgrp -R 0 $WORKDIR && \
    chmod -R g=u $HOME $WORKDIR
USER 1001
