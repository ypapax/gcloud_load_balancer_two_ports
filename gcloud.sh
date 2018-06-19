#!/usr/bin/env bash
set -ex

template_create(){
	gcloud beta compute instance-templates create-with-container mytemplate \
     --container-image ypapax/two_ports
}

create_managed_group(){
	gcloud compute instance-groups managed create twoports-group \
    --base-instance-name twoports \
    --size 2 \
    --template mytemplate \
    --zone europe-west1-b
}

set_named_ports(){
	gcloud compute instance-groups managed set-named-ports twoports-group \
   --named-ports app80:80,app8080:8080 \
	--zone europe-west1-b
}

create_health_check80(){
	gcloud compute health-checks create http healthcheck80 --port 80 \
	    --check-interval 30s \
	    --healthy-threshold 1 \
	    --timeout 10s \
	    --unhealthy-threshold 3
}

create_backend(){
	gcloud compute backend-services create twoports-backend --global --health-checks=healthcheck80
}

add_backend(){
	gcloud compute backend-services add-backend twoports-backend \
	--global \
	--instance-group=twoports-group \
	--instance-group-zone europe-west1-b
}

url_map(){
	gcloud compute url-maps create twoports-map1 --default-service twoports-backend
}

url_map2(){
	gcloud compute url-maps create twoports-map2 --default-service twoports-backend
}

create_http_proxy1(){
	gcloud compute target-http-proxies create twoports-proxy1 --url-map twoports-map1
}

create_http_proxy2(){
	gcloud compute target-http-proxies create twoports-proxy2 --url-map twoports-map2
}

forwarding_rule(){
	gcloud compute forwarding-rules create forwarding-rule80 --global --target-http-proxy twoports-proxy1 --ports 80
	gcloud compute forwarding-rules create forwarding-rule8080 --global --target-http-proxy twoports-proxy1 --ports 8080
}

describe_forwarding_rule(){
	gcloud compute forwarding-rules describe forwarding-rule80 --global
	gcloud compute forwarding-rules describe forwarding-rule8080 --global
}

load_balancer_frontend_ip(){
	rule=$1
	gcloud compute forwarding-rules describe $rule --global | grep IPAddress | awk '{print $2}'
}

createAll(){
	template_create
	create_managed_group
	set_named_ports
	create_health_check80
	create_backend
	add_backend
	url_map
	url_map2
	create_http_proxy1
	create_http_proxy2
	forwarding_rule
}

workers_ips(){
	gcloud compute instances list | grep twoports- | awk '{print $5}'
}

curl1(){
	ip1=$(load_balancer_frontend_ip forwarding-rule80)
	curl $ip1:80
}

curlWorkers80(){
	for ip in $(workers_ips); do
		curl $ip:80
	done
}

curlWorkers8080(){
	for ip in $(workers_ips); do
		curl $ip:8080
	done
}

$@