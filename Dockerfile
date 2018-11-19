FROM ubuntu:18.04

ARG branch=master
ARG version

ENV name="cloudkeeper-aws" \
    username="cloudkeeper"
ENV spoolDir="/var/spool/${username}"
ENV logDir="/var/log/${username}"

LABEL application=${name} \
      description="A tool for synchronizing appliances between cloudkeeper and AWS" \
      maintainer="work.dusanbaran@gmail.com" \
      version=${version} \
      branch=${branch}

SHELL ["/bin/bash", "-c"]

# update + dependencies
RUN apt-get update && \
    apt-get --assume-yes upgrade && \
    apt-get --assume-yes install ruby

# cloudkeeper-aws
RUN gem install ${name} -v "${version}" --no-document

# env
RUN useradd --system --shell /bin/false --home ${spoolDir} --create-home ${username} && \
    usermod -L ${username} && \
    mkdir -p ${logDir} && \
    chown -R ${username}:${username} ${spoolDir} ${logDir}

EXPOSE 50051

USER ${username}

ENTRYPOINT ["cloudkeeper-aws"]
