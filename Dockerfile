FROM eu.gcr.io/halfpipe-io/marklogic/marklogic

ADD . /tmp/ml-deploy

RUN yum install -y zip unzip && cd /tmp/ml-deploy && ./build && /etc/init.d/MarkLogic start && /tmp/ml-deploy/try-port.sh localhost 8002 5 && cd /tmp/ml-deploy && ./deploy.sh -p target/package.zip -t localhost && /etc/init.d/MarkLogic stop
