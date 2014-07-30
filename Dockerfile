FROM springersbm/ml-docker
RUN yum install -y zip unzip
ADD . /tmp/ml-deploy
RUN /etc/init.d/MarkLogic start && /tmp/ml-deploy/try-port.sh localhost 8002 5 && cd /tmp/ml-deploy && ./build && ./deploy.sh -p target/package.zip -t localhost
