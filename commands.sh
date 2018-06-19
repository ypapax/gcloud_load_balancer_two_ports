#!/usr/bin/env bash
set -ex

build(){
	docker build . -t ypapax/two_ports
}

push(){
	docker push ypapax/two_ports
}

run(){
	set +e
	docker kill two_ports
	docker rm two_ports
	set -e
	docker run --name two_ports ypapax/two_ports
}

rerun(){
	build
	run
}

up(){
	build
	docker-compose stop
	docker-compose up
}

curlloca(){
	curl localhost:80
	curl localhost:8080
}
$@