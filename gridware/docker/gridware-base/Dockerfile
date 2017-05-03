FROM alces/clusterware-el7:1.7
LABEL maintainer="Alces Software Ltd. <support@alces-software.com>" \
      description="Alces Gridware - base image"

RUN /opt/clusterware/bin/alces service install gridware && /opt/clusterware/bin/alces gridware init && yum clean all
RUN mkdir -p /opt/gridware/bin
COPY launcher.sh /opt/gridware/bin/launcher.sh
ENTRYPOINT ["/opt/gridware/bin/launcher.sh"]
