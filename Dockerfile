
FROM kbase/deplbase:latest

ADD . /kb/dev_container/modules/amethst_service

RUN cd /kb/dev_container/modules/amethst_service && . ../../user-env.sh && make && make deploy-service && cat deploy.cfg >> /kb/deployment/deployment.cfg

# Make any changes to ensure the service runs in the foreground.
CMD ["/kb/deployment/services/amethst_service/start_service"]