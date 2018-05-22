FROM golang:latest
MAINTAINER Anshuman Bhartiya <anshuman.bhartiya@gmail.com>

RUN apt-get update && apt-get install -y python-pip jq

# create a generic SSH config for Github
WORKDIR /root/.ssh
RUN echo "Host *github.com \
\n  IdentitiesOnly yes \
\n  StrictHostKeyChecking no \
\n  UserKnownHostsFile=/dev/null \
\n  IdentityFile /root/.ssh/id_rsa \
\n  \
\n Host github.*.com \
\n  IdentitiesOnly yes \
\n  StrictHostKeyChecking no \
\n  UserKnownHostsFile=/dev/null \
\n  IdentityFile /root/.ssh/id_rsa" > config

# repo-supervisor
WORKDIR /data
RUN git clone https://github.com/anshumanbh/repo-supervisor.git

WORKDIR /data/repo-supervisor

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
RUN /bin/bash -c "source ~/.bashrc && nvm install 7"
RUN /bin/bash -c "source ~/.bashrc && cd /data/repo-supervisor && npm install --no-optional && npm run build"

# Trufflehog
WORKDIR /data
RUN git clone https://github.com/dxa4481/truffleHog.git

# Go deps
RUN go get github.com/google/go-github/github && go get github.com/satori/go.uuid && go get golang.org/x/oauth2

# do this later so we can reuse layers above when only our code changes
COPY main.go /data/main.go
COPY runreposupervisor.sh /data/runreposupervisor.sh

RUN chmod +x runreposupervisor.sh
COPY regexChecks.py /data/truffleHog/truffleHog/regexChecks.py
COPY requirements.txt /data/truffleHog/requirements.txt
RUN pip install -r /data/truffleHog/requirements.txt

# build our code
RUN go build -o gitallsecrets .

ENTRYPOINT ["./gitallsecrets"]
