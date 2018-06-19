FROM python:latest
ADD . /
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8080
EXPOSE 80

