FROM springersbm/ml-docker
RUN yum install -y zip unzip
ADD . /tmp/ml-deploy
RUN cd /tmp/ml-deploy && ./build && ./deploy.sh -p target/package.zip
