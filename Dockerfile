FROM springersbm/ml-docker

ADD . /tmp/ml-deploy

RUN yum install -y zip unzip

RUN cd /tmp/ml-deploy && ./build 
RUN /etc/init.d/MarkLogic start && /tmp/ml-deploy/try-port.sh localhost 8002 5 && ./deploy.sh -p target/package.zip -t localhost
