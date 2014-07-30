FROM springersbm/ml-docker
ADD . /tmp/ml-deploy
RUN cd /tmp/ml-deploy && ./build && ./deploy.sh -p target/package.zip
